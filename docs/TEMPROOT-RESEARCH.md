# PD2238 临时 Root 完整技术研究报告
日期: 2026-08-23 | 设备: iQOO Neo7 SE / MT6895 / 5.10.246-android12-9-dirty / OS6 / BL locked

## 〇、结论摘要

临时 root 在本机技术上可行, 且存在一个高度相似的公开成功先例:
soralis0912/aristotle-root (小米 XIG04, 同芯片 MT6895, 同 KMI 分支
5.10-android12-9, 基于 duchamp-root 源码)。核心工作量收敛为三件事:

1. 静态提取本机内核偏移 (工具已就绪, 等卡刷包)
2. 以 aristotle/duchamp 源码为底座移植 target.h (同源码树)
3. QEMU 先行调试 (aristotle 仓库自带 qemu/ 目录, 可绕开 PANIC_ON_OOPS 实机试错死局)

最大不确定性: vivo -dirty 私改幅度 / 本机 NF_LOG 关闭需换 slide 锚点 /
UBSAN_TRAP 使实机试错成本极高。

## 一、漏洞与提权链解剖 (基于本地 CyberMeowfia 源码逐行分析)

CVE-2026-43499: futex_requeue_pi 代理锁回滚时 remove_waiter() 错把 current
当 waiter->task 操作, 造成栈上 rt_mutex_waiter UAF。
本机 CONFIG_FUTEX_PI=y 且已实证漏洞存在 (PoC panic)。

### 七个阶段及本机适配点
| # | 阶段 | 源文件 | 做什么 | PD2238 适配点 |
|---|---|---|---|---|
| 1 | 注入 | preload.c | LD_PRELOAD constructor 触发 | 无差异 |
| 2 | KASLR 泄露 | slide.c | UAF 操纵 rbtree 旋转把内核指针写进 boot_id 存储, 读 /proc/sys/kernel/random/boot_id 反算 _stext (slide.c:326-380) | 警告: 官方锚点 nfnl_logger/loggers 数组在本机不存在 (NF_LOG 全关)。替代方案: 任何地址已知的 .data 指针供体, 如 init_task / root_task_group / security_hook_heads; 写入目标 SLIDE_RANDOM_BOOT_ID_DATA 保留 |
| 3 | 堆排布 | pipe.c | pipe_buffer 页 spray 占位被释放的内核栈页 | INIT_ON_ALLOC=y 影响复用时序, spray 参数需重调 |
| 4 | 堆址泄露 | kernelsnitch/ | futex hash 冲突时序侧信道, 泄露 groomed 页的 physmap 地址 (pipe.c:139-214) | MTK 上公认最难调 (PD2241 D9300 失败案例即卡此关); 但 vivo PD2279J 移植记录显示 2026-07 已有人突破 KernelSnitch on MTK 5.10 |
| 5 | FOPS 劫持 | fops.c | pselect 栈布局放置 fake lock, 竞态改写 ops 表 (CFI 友好路径) | PSELECT_ROUTE_NFDS=320 等栈布局常量需按本机 ABI 重调; 错值 = panic |
| 6 | 物理读写→提权 | root.c/pipe.c | 伪造 pipe_buf_ops 得任意物理读写, patch cred(uid=0/caps/sid) + 关 seccomp + selinux enforcing=0 | 结构体偏移来自静态提取+源码推导; STATIC_USERMODEHELPER=y 不影响此路线 (不走 usermode helper) |
| 7 | 持久化 | root.c/su_daemon.c | 落地 su daemon / ksud late-load | 本机目标是临时 root + 立即写 seccfg 解锁 → 转 SakiSU 永久化 |

## 二、先例对照表 (谁离 PD2238 最近)

| 项目 | SoC | 内核 | 与本机距离 | 备注 |
|---|---|---|---|---|
| **aristotle-root** (XIG04) | **MT6895** | **5.10.136-android12-9** | 同芯片同分支, sublevel 差 110 | 最佳底座; 其 target.h 的 MTK 常量 (phys_offset/pselect 时序/A78A55 拓扑) 大部分可继承 |
| duchamp-root (上游) | MT6895系? | - | aristotle 的母本 | Colorful-glassblock 出品 |
| ghostlock-aresin (POCO F3 GT) | MT6893 | 4.14.186-android13 | 同厂不同代 | data-only physmap 技术参考 |
| PD2279J 移植记录 (qhyz) | MT6833 | 5.10.149-android12 | 同为 vivo+MTK+5.10android12 | 偏移提取方法学完整可抄; KernelSnitch 已突破但 pwrite 未通 |
| 一加 ACE5 至尊版复盘 | SM8735 | 6.x | 配置相似 (UBSAN_TRAP+PANIC_ON_OOPS+mrdump) | 失败教训: slide 阶段 36-45s panic |

关键推断: aristotle 成功证明 **MT6895 + 5.10android12 KMI 上整条链是通的**
(含 KernelSnitch 在 A78/A55 上可调), 本机与其差异只剩:
a) sublevel 246 vs 136 → 全部偏移需重提 (本来就要做)
b) vivo -dirty 补丁 → 结构体可能被动过, 需交叉验证
c) NF_LOG 缺失 → slide 锚点替换
d) vivo OS6 用户态 → LD_PRELOAD 运行环境确认即可

## 三、调试策略: 用 QEMU 打破 PANIC_ON_OOPS 死局

实机每次失败 = panic 重启 (PANIC_TIMEOUT=-1), 且无串口, 无法断点。
aristotle 仓库自带 qemu/ 目录的解法:
1. 从卡刷包提取本机 kernel Image + vendor_boot ramdisk
2. QEMU-system-aarch64 -M virt -cpu cortex-a76 加载同款 Image
   (39位VA需 -cpu max 或改ID映射, 具体以 qemu/ 目录脚本为准)
3. 在 QEMU 里无限次试错: 验证 kallsyms 提取正确性 / slide 锚点替换 /
   pselect 栈常量 / kernelsnitch 时序参数
4. QEMU 全绿后才上真机, 把 panic 概率压到最低
注意: QEMU 无法完美模拟 MTK 私有驱动与 SMP 拓扑, 时序类阶段
(kernelsnitch/consumer 打点) 最终仍需真机标定。

## 四、执行计划 (里程碑制)

M1 固件分析 (零风险, 卡刷包到手即做)
  - 01/02 脚本提取 boot.img + kallsyms 21 符号
  - 对照 aristotle target.h 字段逐项填表
  - 判定: 符号齐全度 >= 90% 才继续
M2 结构体偏移 (零风险)
  - GPL 源码(5.10.177) + 本机 config 编译 vmlinux → pahole
  - task_struct/cred/rt_mutex_waiter/pipe_inode_info/configfs 关键字段
  - 用 M1 的 kallsyms init_task 地址反推校验
M3 QEMU 移植 (零风险)
  - clone aristotle-root, 建 PD2238 target.h, 替换 slide 锚点
  - qemu/ 流程跑通 slide+fops 两阶段
M4 真机冷启动测试 (有 panic 风险)
  - pristine boot_id 重启 → 推 preload.so → LD_PRELOAD 触发
  - 目标: slide-kaslr-ok 日志出现 (第一里程碑)
M5 全链 + seccfg (变局点)
  - physrw 通 → 先写 seccfg 解锁 → 重启 → SakiSU 去 vr.ko → 永久化

## 五、风险与不确定性清单

1. vivo -dirty 幅度未知: 编译时间 2026-07-15 说明近期还在改内核,
   可能加了针对 GhostLock 的检测 (如 waiter 完整性校验)
2. UBSAN_TRAP: QEMU 可关掉模拟, 但真机开着 — 任何未定义行为直接死
3. vr.ko: 提权成功瞬间可能被盯防 (X200 Pro 案例), 所以 seccfg 写入要快,
   且优先级高于一切后续动作
4. SLUB_MIRROR/INIT_ON_ALLOC 对堆排布的影响需实测标定
5. 法律与设备风险: 仅限本人设备研究; 强制重启有闪存磨损; 最坏情况变砖

## 十一、真机实测与 QEMU 迭代记录 (2026-08-24)

### 真机 M4 首测结果 (重大进展)
preload.so 在真机 PD2238 上成功运行:
- ✅ target.h 全部偏移加载正确 (init_task/root_tg/delta=0)
- ✅ KernelSnitch 工作: 找到 15 碰撞, 650 万候选暴搜完成
- ✅ 竞态触发: 每轮尝试 consumer walk=200 次全部执行
- ✅ pselect 窗口稳定存活 (slices=5/5), 内核零 panic
- ✅ 多轮自动重试机制工作 (attempt 1..7)
- ❌ WRITE-PROOF landed=0 (写入未命中目标)

### 关键诊断链
1. 反汇编确认设备内核未修复 CVE-2026-43499
   (remove_waiter 用 SP_EL0/current, 无 waiter->task 加载)
   [勘误: 曾误判已修复, 见第四节]
2. QEMU 标记实验证明: 悬垂指针 +0x38 处是栈残留(0xdc0)而非 overlay 值
   → 悬垂指针与 fdset 的相对位置 (DELTA) 与 aristotle 不同
3. QEMU 崩溃于 rb_erase+0x24 (walk 跟随假节点后崩) → 写原语路径真实存在
4. 真机数百次 walk 无 panic → overlay 接近正确但未精确对齐

### 已部署的对策
- kShiftSweep 从 {-2} 扩展为 {-4,-3,-2,-1,0,1,2,3} (fops.c)
  真机每轮尝试自动换一个 shift, 一次完整运行覆盖全部候选
- 设备端脱离运行方案 (nohup + exp.log 轮询)
- check_exploit.ps1 巡检脚本

### 待解决
1. 真机完整 sweep 轮 (~30-60 分钟) 的 landed=1 验证
2. 若 8 个 shift 全空: 需转"fdset 大小/nfds 参数"维度扫描
   (RTMUTEX 分析文档指出 nfds 决定 fdset 布局形态)
3. 泄漏探针进程泄漏问题 (~70 个/次尝试, 多轮累积致系统不稳)
4. vr.ko 对临时 root 进程的干扰评估

### 方法论沉淀
- QEMU 日志必须用 -serial file: 直写 (Out-File 有缓冲, 轮询永远失灵)
- exploit 线程绝不可退出 (内核栈=悬垂指针的宿主)
- overlay 字段布局必须逐字段对照原版 (w2/w5=&target, w6=task, w7=lock)
- 真机与 QEMU 的内存布局不同, QEMU 只验证逻辑, 调参必须在真机
## 十二、QEMU 单核调试的最终结论 (2026-08-24)

### 决定性数据 (多次崩溃寄存器)
- 真机崩溃: x28(pib) = 0xffffffc00b513b10 (waiter 栈, 栈基偏移 0x3b10)
- QEMU 崩溃: x28(pib) = 0xffffffc00b463b10 (同样偏移模式 0x3b10!)
- 两者都验证: 悬垂 pib = waiter 内核栈内 0x3b10 偏移处

### 关键发现: 崩溃路径不是 consumer
- 崩溃时间 = WAIT_REQUEUE_PI 超时时刻 (REQUEUE+3s)
- 崩溃在 futex_wait_requeue_pi 的 ETIMEDOUT 清理路径 (rt_mutex_cleanup_proxy_lock/fixup_owner)
- 即: 悬垂 pib 在超时返回时被清理路径访问 → 崩溃
- 这证明悬垂存在, 但 QEMU 单核下 exploit 流程走不到 pselect (时序敏感)

### pib 与 fdset 空间分离
- pib = 内核栈地址 (0xffffffc00b4...)
- fake_lock/fake_w0 = 直接映射堆地址 (0xffffff8...)
- walk 从 pib(栈)读字段, 字段值指向堆 — 要求 fdset(栈上的值)覆盖 pib 位置
- PD2238: DELTA=+0x120, fdset 窗口 120B 够不到 → pselect 路线结构性不可行

### 已尝试的所有方向 (供后续参考)
1. shift 扫描 [-4..3]: -4/-3 数学无效, -2..+3 全 landed=0
2. 增大 nfds: 源码证明 ≥321 转 kvmalloc 堆, 无解
3. 替代 syscall 扫描: poll/ppoll(0x528 太深), sched_setaffinity(0x40 太浅且仅8B),
   select(0x1f0), pselect6(0x210) — 全部不在 [0x2e0,0x380] 目标窗口
4. QEMU 帧求和: Δ=+0x120 高置信 (PLAN-B-FRAMES.md)

### 残余可行方向 (按工作量)
1. 系统性扫描所有 _copy_from_user 调用点, 找目标深度∈[0x2e0,0x380] 且≥80B 的
   栈缓冲 (约100+调用点, 需脚本递归求帧和) — 数天
2. 用 io_uring/socket 等更深封装改变 futex 链深度, 使 rt_waiter 上移 — 需创新
3. 接受 pselect 路线死亡, 评估其它免解锁途径

### 环境教训
- QEMU TCG 单核下 futex 超时清理路径会 panic, 多核下断点失效
- 真机是唯一可靠验证环境, 但每次迭代成本 = 一次重启+日志分析