# iQOO Neo 7 SE 免解锁 Root — 完整技术思路与实施记录

日期: 2026-08-23/24 | 设备: PD2238/V2238A | MT6895 (天玑8200) | 5.10.246-android12-9-dirty | OS6 | BL locked

---

## 一、目标与路线选择

**目标**: 不解锁 Bootloader 实现 root（免解锁临时 root），进而持久化。

**路线演进**:
```
方案 A: CVE-2026-43499 (GhostLock) 内核提权     ← 主攻方向 (本文档)
方案 B: MTK BROM/DA 强解 BL (heapb8/奇美拉系)   ← 备选, 与内核漏洞无关
方案 C: 等待社区公开适配                         ← 被动
```

选择 A 的依据: 漏洞影响 2.6.39~7.0 全系内核；同芯片同内核分支有成功先例
(soralis0912/aristotle-root, 小米 XIG04, MT6895 + 5.10-android12-9)；
本机 PoC 实测触发内核 panic（后证实为"利用失败触发保护"而非"漏洞存在"，
见第四节勘误，但漏洞最终经反汇编确认【未修复】）。

---

## 二、漏洞原理 (CVE-2026-43499 / GhostLock)

**位置**: `kernel/locking/rtmutex.c` 的 `remove_waiter()`, 潜伏 15 年。

**本质**: `futex_requeue()` 走代理锁回滚时 (`rt_mutex_start_proxy_lock`
失败返回 EDEADLK), 调用 `remove_waiter(lock, waiter)` 清理。但该函数内部
操作的是 **current**（当前调用者=主线程）而非 **waiter->task**（真正的等待
线程 W）:

```c
raw_spin_lock(&current->pi_lock);      /* 错: 应锁 W 的 pi_lock */
rt_mutex_dequeue(lock, waiter);
current->pi_blocked_on = NULL;         /* 错: 清了 main 的(本来就空) */
```

**后果**: W 的 `pi_blocked_on` 保持指向 W 自己内核栈上的 rt_mutex_waiter。
W 从 `FUTEX_WAIT_REQUEUE_PI` 以 ETIMEDOUT 返回后（清理被 goto out 跳过）,
悬垂指针存活。W 随即进入 `pselect`, 内核把 fd_set 复制到**同一片栈区**,
悬垂指针恰好落在 fdset 数据上 → 构造 fake rt_mutex_waiter → consumer
线程用 `sched_setattr` 触发 `rt_mutex_adjust_prio_chain` → walk 经过
`rb_erase` 时按 overlay 内容执行**任意地址 8 字节写**。

**本机前提核验**:
| 条件 | 状态 |
|---|---|
| CONFIG_FUTEX_PI=y | ✅ |
| 内核未含修复 (5.10.246 < 修复版 5.10.261?) | ✅ 反汇编确认 remove_waiter 用 current (SP_EL0), 无 waiter->task 加载 |
| /dev/ashmem 存在 | ✅ (fops 劫持目标) |
| perf_event_paranoid=-1 | ✅ |

⚠️ 勘误记录: 曾一度误判"内核已修复"（把 start_proxy_lock 里存在
remove_waiter 调用误读为修复特征——实际那正是漏洞代码本身, 修复改的是
函数内部 current→waiter->task）。经设备内核 remove_waiter 反汇编
(`mrs x20, SP_EL0` = 用 current) 纠正为未修复。

---

## 三、完整流水线与状态总览

```
[1] 固件获取与解包           ✅ 完成
[2] 符号/偏移提取            ✅ 完成 (QEMU 虚拟地址复核 13/13)
[3] target.h 构建            ✅ 完成 (草案→编译通过)
[4] preload.so 编译          ✅ 完成 (216KB, NDK r29)
[5] 真机运行                 ✅ 实证 (race 触发, 200 walks/轮, 不 panic)
[6] 写入命中调参             ⏳ 进行中 ← 当前卡点 (sweep v2 后台运行)
[7] KASLR 泄露               ⏸ 等 [6]
[8] fops 劫持→物理读写→uid=0 ⏸ 等 [6]
[9] 持久化 (seccfg→解锁→SakiSU) ⏸ 等 [8]
```

### [1] 固件分析
- OTA 为 vivo 传统 old-dat 格式（非 A/B payload）, 关键镜像直接可提
- 提取: boot/vendor_boot/lk/preloader×3/vbmeta×3/recovery/dtbo/scatter.txt
- 内核版本串与设备一致; vermagic 含 `vivo` 字段实锤

### [2] 符号提取 (零风险, 离线)
- magiskboot 解包 boot.img → gzip 解压 → 裸 Image (49MB)
- kallsyms 静态提取: **174,277 符号**, _text=0xffffffc008000000
- vmlinux-to-elf 生成 output.elf (57.9MB) → pyelftools dump .data 区验证指针
- 关键偏移 (节选): INIT_TASK=0x2aec240 SYSCTL_BOOTID=0x2ee910d
  ASHMEM_MISC_FOPS=0x2c851e8 loggers[]=0x2ae1618 nfulnl_log_packet=0x14c331c

### [3] 内存布局 (39 位 VA 专属, 不可抄 Pixel 模板)
- PAGE_OFFSET/DIRECT_MAP = 0xffffff8000000000 ~ 0xffffffc000000000
- KIMAGE_TEXT_BASE = 0xffffffc008000000 (oppo 5.10.236 同值互证)
- P0_KERNEL_PHYS_LOAD = 0x40000000, delta=0 (vendor_boot kernel_addr 实证)

### [4] 结构体偏移来源
继承 aristotle (MT6895+5.10.136, QEMU/gdb 验证) + QEMU 复核:
task.comm@0x790="swapper/0", real_cred/cred@0x778/0x780 同指 init_cred,
pid/tgid@0x5c8=0, pi_blocked_on@0x898。5.10 特征: waiter 无
wake_state/ww_ctx 字段; configfs bin 文件走 .read/.write 非 _iter。

---

## 四、真机实证结果 (2026-08-24)

```
[+] p0 profile delta=0 init_task=ffffffc00aaec240 ✓ 全部实测值加载正确
[+] ckpt: WRITE-PROOF armed bootid_target=ffffff8002ee910d ✓ 别名换算正确
[*] found 15 collisions                            ✓ KernelSnitch 工作正常
[*] [0..7] tested 共 650 万候选                     ✓ 暴搜完成
[+] consumer walk walks=200/轮                      ✓ 竞态与链遍历真实发生
[+] pselect attempt=N survived slices=5/5           ✓ 窗口稳定, 不崩不 panic
✗ landed=0                                          ✗ 写入未命中目标
```

**结论**: 漏洞利用的"扣扳机"环节全部工作, 子弹落点参数待调。
期间一次清理泄漏进程引发的重启也验证了救砖路径有效。

## 五、当前卡点: fdset 对齐 (写入命中)

**机制**: 悬垂指针指向旧 rt_waiter 栈址 P。pselect 的内核 fdset 复制到
同一栈区的 FDSET_BASE。walk 把 P 处内存当 waiter 解析, 因此 overlay
必须满足: P+0x00=写值, P+0x10=&sysctl_bootid(写目标), P+0x30=task,
P+0x38=lock。fdset word i 位于 FDSET_BASE+8i, 故需知 DELTA=FDSET_BASE-P,
将表整体平移 s=DELTA/8 个 word。DELTA 是内核构建常量, 只能实测。

**sweep 方法** (work\qemu\init_sweep.c): waiter 线程进入 pselect 前
自驱循环 s=0..11: 重建 overlay→dup 置位 fd→pselect(3s) 让 consumer 打点
→回读 boot_id。boot_id 变化的 s 即答案。

**已修复的自伤 bug**: 初版 sweep 把 waiter_fn 改成了会 return 的结构,
线程退出=内核栈释放=overlay 蒸发=必然 landed=0 且任务列表缺线程
(观测吻合)。已改为 waiter 内部跑完整个 sweep 永不退出 (aristotle 原版
不变式: waiter 必须活着保住栈)。

**判定**: sweep_v2.log 中任何一轮 BOOTID≠BEFORE → 该轮 s 值填入
target.h 的 PSELECT_WAITER_WORD_SHIFT → 重编译 → 理论直通 [7][8]。
若 12 档全空 → 扩大 nfds (加宽可控窗口) 或转 heap 对齐方案。

## 六、持久化路径 (修正: 不是改 LK)

| 方式 | 判定 |
|---|---|
| 改 lk.img 本体 | ❌ preloader 验签, 过不了=开机死 |
| **改 seccfg 分区锁标志** | ✅ 无签名数据分区, mtkclient 同款机制 |
| 每次开机重打 exploit | ⚠️ 可用但脆弱 |

```
临时 root 成功瞬间 (一次性):
  ddtar 读 seccfg → 翻转锁标志 → 写回 → 重启
  → BL unlocked (orange) → fastbootd 可刷
  → SakiSU 修补 init_boot/vendor_boot (选 5.10-android12 vivo KMI + 移除 vr.ko)
  → fastboot flash → KSU LKM 开机自启 = 真·永久 root
```

vr.ko 死结在此解开: 锁着 BL 无法刷 vendor_boot 去 vr.ko;
解锁后即可移除, LKM 不再被杀。

---

## 七、工具链与产物清单

### 脚本 (scripts\)
| 脚本 | 功能 | 状态 |
|---|---|---|
| 01_unpack_ota.ps1 | 卡刷包→分区镜像 | ✅ |
| 02_boot_kallsyms.ps1 | boot.img→Image→kallsyms→符号核对 | ✅ |
| 03_qemu_boot.ps1 | QEMU 冒烟/-Verify 偏移验证 | ✅ |
| 04_build.ps1 | 编译 preload.so (参考, 实际用内联命令) | ✅ |
| check_exploit.ps1 | 真机 exploit 状态巡检 | ✅ |

### 关键产物
```
work/boot_out/kallsyms.txt            174K 符号表
work/boot_out/output.elf              57.9MB 带符号 ELF (IDA/gdb 用)
work/boot_out/target_pd2238_draft.h   目标配置 (已同步至 aristotle 工程)
work/qemu/init_sweep.c                扫描实验源码
work/qemu/sweep_v2.log                ⏳ 进行中的扫描日志
src/aristotle-root/build/.../preload.so  最终部署产物
work/ota_out/*                        救砖弹药库 (全套官方镜像)
docs/SAFETY.md                        安全手册+救砖四级方案
docs/DEPLOY.md                        部署手册
```

### 环境依赖 (tools\)
payload-dumper-go 2.0.2 / magiskbot(PinNaCode) / python3.11便携+vmlinux-to-elf
1.2.3 / QEMU 11.1.0 / NDK r29 / aarch64-gdb(mmozeiko 构建)

---

## 八、安全框架摘要 (详见 SAFETY.md)

- 临时 root 阶段零分区写入, 最坏 panic 重启 (无害, 已多次实证)
- 红线: 永不写 lk/preloader; 解锁前必备份; 连续 panic>5 次停手分析
- 救砖四级: 强启 → recovery 卡刷 → mtkclient/SPFT 线刷 → 售后
- 弹药库: 卡刷包 8.9GB + 全套官方镜像随时可回刷

---

## 九、经验教训 (踩坑记录)

1. **不要用"特征存在性"下安全结论**: remove_waiter 调用的存在是漏洞形态
   而非修复形态; 修复改的是函数内部。曾据此误判"已修复"又反转。
2. **QEMU 物理读取(xp)不可用于内核符号验证**: 启动后镜像映射重排,
   会读到 0xcc 毒化假象; 必须用 monitor 虚拟地址读取(x, 走客机页表)。
3. **exploit 线程绝不能退出**: 悬垂指针指向线程自己的内核栈, 线程退出=
   栈释放=overlay 蒸发。所有轮次必须在 waiter 线程内部完成。
4. **PowerShell 5.1 三大坑**: UTF-8 无 BOM 中文脚本解析错乱 (补 BOM);
   native 参数引号剥离 (--% 或 cmd 包装); Start-Job 生命周期随会话
   (后台进程用 Start-Process)。
5. **Python 生成 cpio 有坑**: newc 头字段必须 ASCII 文本; 用 bsdtar
   --format=newc + 二进制补丁 mode=0755 最可靠。
6. **-m 2048 下 QEMU virt 的 initrd 放置异常**, 用 -m 1024。
7. **TCG 断点对多核不可靠**, gdb 观察→改用 monitor 虚拟地址读取 +
   物理搜索 (pmemsave) 方案。

---

## 十、下一步行动序列

1. ⏳ 收取 sweep_v2 结果 (work\qemu\sweep_v2.log, 每 ~20min 查看)
   - 命中 → 提取 s → 更新 target.h → 04 重编译 → 真机 M4'
2. 未命中 → nfds 扩窗 (512→1024+) 或 heap 对齐方案设计
3. landed=1 达成 → slide 泄露验证 (boot_id 回读算 stext)
4. fops 劫持 → pipe physrw → uid=0 → 立即 seccfg 解锁
5. 重启 → fastbootd → SakiSU(vivo KMI+去vr) → 永久 root 收工
6. 并行备选: BL 强解路线物料持续跟进 (nut 工具迭代/远程服务报价)
