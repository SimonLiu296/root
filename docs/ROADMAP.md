# iQOO Neo7 SE 免解锁 Root 技术路线图（基于 GhostLock/CVE-2026-43499）

日期: 2026-08-23
设备: PD2238/V2238A, 内核 5.10.246-android12-9 (2026-07-15 编译), Android 16/OriginOS 6, BL locked
状态: 漏洞存在性已实证 (PoC 触发内核 panic)

## 为什么 Pixel/一加能成、本机不能直接套

| 条件 | Pixel 10 (官方适配) | 一加 Ace6T/15 (社区移植) | 本机 vivo |
|---|---|---|---|
| 内核 | GKI 6.6/6.12 | GKI 6.12 | **MTK 私有 5.10** |
| BTF (/sys/kernel/btf) | ✓ | ✓ | ✗ 无 |
| kallsyms 读取 | root/固件提取 | root/固件提取 | 锁 BL + kptr_restrict 拒读 |
| UBSAN_TRAP | 不开 | 不开 | **开启 (致命)** |
| PANIC_ON_OOPS | 不开 | 不开 | **开启 (致命)** |
| 厂商 panic 模块 | 无 | mrdump | **mrdump + aee (vivo)** |
| 公开适配工作量 | 官方已做 | 社区已做 | **零适配, 需自研** |

结论: 漏洞一样, 但利用链所需的"偏移获取"和"调试环境"被 vivo 内核配置封死,
且没有任何公开先例。这是研究项目, 不是教程流程。

## 完整路线图 (各阶段工作量/风险)

### 阶段 1: 生成 target.h (偏移) —— 最关键, 数周
- 1a. 符号偏移 (28 个 kallsyms 符号):
  - 获取官方固件包 (vivo OTA 全量包) → boot.img → 解压内核 Image
  - kallsyms 提取 (CONFIG_KALLSYMS_ALL=y, 符号表压缩在镜像 .rodata, 有成熟工具)
- 1b. 结构体偏移 (57 个 BTF 字段):
  - vivo 官方 GPL 源码 (opensource.vivo.com, MT6855 5.10.177 已验证存在, MT6895 大概率也有)
  - 编译 vmlinux (开 DWARF) → pahole 提取偏移表
  - ⚠️ 版本差 (177 vs 246) 需实测校正, 差 8 字节即崩 (一加案例教训)
  - 备选: IDA 手工逆向 (数周)
- 风险: 低 (纯离线工作)

### 阶段 2: KASLR 绕过 —— 数天~数周
- slide (boot_id 泄漏): 被 UBSAN_TRAP 封死 (一加实证) ✗
- KernelSnitch (futex hash 时序侧信道): 一加作者推荐替代, 仓库有源码, 需适配 5.10 futex hash ✓
- 备选: prefetch 侧信道 (ARM64 需 KPTI off, MTK 状态未知)
- 风险: 中 (侧信道需时序调优)

### 阶段 3: 主利用链 (任意写 → 提权) —— 数周~数月
- fops 劫持: /dev/ashmem 存在 ✓, 需 ashmem/fops/configfs 偏移
- pipe 物理读写 → cred patch → root
- 每步失败 = UBSAN/panic → 强制重启 (PANIC_TIMEOUT=-1)
- 风险: **高** (每次调试都死机重启, 反复强制断电有闪存磨损)

### 阶段 4: vivo 特有对抗 —— 数天
- vr.ko 会杀 root 进程 → root 后需先处理 (但锁 BL 不能刷 vendorboot)
- 持久性: 锁 BL 无法刷分区 → 只能"临时 root" (每次开机重新提权 + LKM 内存加载)
- 结论: 即使成功也是临时 root, 非持久

## 关键资源清单

- 官方 PoC/exploit: github.com/NebuSec/CyberMeowfia (IonStack/CVE-2026-43499)
- 一加移植参考: github.com/p2p3p/GhostLock-for-OnePlus (6.12 专用, 流程可参考)
- 一加 ACE5 适配失败复盘: brszzz.github.io/2026/07/12/... (UBSAN_TRAP 教训)
- vivo 官方内核源码: opensource.vivo.com (MT6855 5.10.177 已确认; GitHub 镜像:
  github.com/XiKoTaSu/android_kernel_vivo_mt6855-opensource.vivo.com)
- 设备实测数据: 本目录 kernel_config.txt / device_info.txt / ASSESSMENT.md

## 客观结论

- 技术上: 路线存在 (漏洞真、攻击面真、源码可获取), 但**不是短平快任务**
- 预计工作量: 1-2 个月全职内核逆向/利用开发, 且需要 ARM64 内核利用经验
- 成功率: 无法保证 (唯一参考案例 - 一加 ACE5 - 失败于本机同款配置)
- 性价比建议: 等待作者团队公开免解锁方案 (其目标区间包含本机条件) 或
  走解 BL + SakiSU 路线 (物料已备)
