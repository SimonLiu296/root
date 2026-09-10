# iQOO Neo7 SE (PD2238/V2238A) 免解锁 Root 可行性评估报告

日期: 2026-08-23
设备: iQOO Neo7 SE (PD2238 / V2238A), 序列号 10CD6M23EL003SU

## 1. 设备实测情报

| 项目 | 实测值 |
|---|---|
| 型号 | V2238A (PD2238), iQOO 系列, 国行 (ro.vivo.product.overseas=no) |
| SoC | MTK6895 (天玑8200) |
| 系统 | Android 16 / OriginOS 6 (PD2238G_A_16.3.15.0.W10), SDK 36 |
| 内核 | 5.10.246-android12-9-g9c94fefc2317-dirty, 编译于 2026-07-15 |
| 安全补丁 | 2026-07-01 (system) / 2026-06-05 (vendor) |
| BL 状态 | locked (ro.boot.vbmeta.device_state=locked, flash.locked=1, verifiedboot=green) |
| SELinux | Enforcing |
| 关键分区 | boot, init_boot, vendor_boot, vbmeta*, mrdump (vivo panic dump) 均存在 |
| 架构 | aarch64, ARM64_VA_BITS=39, 4K 页 |

## 2. 漏洞前提验证 (实测)

### GhostLock (CVE-2026-43499, rtmutex/futex-requeue 栈UAF)
- CONFIG_FUTEX_PI=y ✓ 具备
- 内核 5.10.246 < 5.10.261 (上游修复线) — 理论上未打补丁, 但 vivo 魔改 (-dirty) 无法静态确认, 需 PoC 实证

### 利用链所需条件对照
| 条件 | 本机 | 说明 |
|---|---|---|
| ARM64_VA_BITS=39 + 4K 页 | ✓ | 与官方 target 一致 |
| CFI (CONFIG_CFI_CLANG=y) | ✓ | 官方有 CFI 友好 fops 绕过方案 |
| /dev/ashmem | ✓ | fops 劫持目标存在 |
| perf_event_paranoid=-1 | ✓ | W2 cred patch 的 perf_find_task 可用 |
| CONFIG_USERFAULTFD=y | ✓ | |
| CONFIG_KALLSYMS_ALL=y | ✓ | 但 kptr_restrict 限制读取 |
| CONFIG_DEBUG_INFO_BTF | ✗ 未开启 | 57 个结构体偏移无法自动化提取 (extract_btf.py 失效) |
| kallsyms 可读 | ✗ Permission denied | 28 个符号偏移无法获取 (锁 BL + kptr_restrict) |
| CONFIG_UBSAN_TRAP=y | ✗ 致命 | UBSAN 触发 BRK 指令 |
| CONFIG_PANIC_ON_OOPS=y | ✗ 致命 | oops 直接 panic |
| mrdump 分区 + aee_core_forwarder | ✗ 致命 | 厂商 panic 模块 (对应一加 mrdump) |
| CONFIG_STATIC_USERMODEHELPER=y | ✗ | DirtyMode 提权路径被封死 |

## 3. 结论

**完整免解锁 root 利用链在本机不可行。** 依据:

1. 复制了一加 ACE5 至尊版适配失败 (brszzz.github.io, 2026-07) 的全部致命条件:
   UBSAN_TRAP + PANIC_ON_OOPS + 厂商 panic 模块。该案例偏移全部正确、编译通过,
   运行 36-45 秒即在 slide (KASLR 泄漏) 阶段 panic 重启, 且无法绕过。
2. 比一加案例更糟: 一加案例有 root 权限读 kallsyms + GKI 内核自带 BTF;
   本机两者皆无 (锁 BL + 无 BTF), 连偏移都无法获取。
3. 备选 n-day (CVE-2026-43074 eventpoll UAF, CVE-2026-64560 POSIX timer UAF)
   均为 Pixel 6.6.118 专用适配, 同样受上述致命条件限制。

## 3.5 实证结果 (2026-08-23 晚)

已执行官方 PoC (poc.c, 静态 ARM64) 在设备上验证:

- **结果: 内核 panic, 手机死机重启 —— 漏洞真实存在, 未被 vivo 修复**
  (内核 2026-07-15 编译, 未 backport 2026-04 的上游修复; 5.10.246 < 5.10.261)
- 触发后长按电源强制重启, 系统完整恢复:
  - sys.boot_completed=1, 版本 PD2238G_A_16.3.15.0.W10 不变
  - BL 状态不变: locked / verifiedboot=green / flash.locked=1
  - 无任何分区写入, 数据无损
- PoC 已从设备清理 (/data/local/tmp/poc 已删除)

**安全含义**: 当前系统存在可被本地低权限进程利用的内核 LPE (DoS 级
已验证; 完整利用需要复杂适配)。若在意安全性, 关注 vivo 后续内核更新。

**利用含义**: 漏洞存在 ≠ 可利用。完整 root 利用链仍受第 3 节全部
致命条件限制 (UBSAN_TRAP + PANIC_ON_OOPS + 无 BTF + 锁 BL 无符号),
且 PANIC_TIMEOUT=-1 + mrdump 使任何适配尝试都会立即 panic 重启,
调试成本极高。此实证数据可供未来 5.10 适配研究者参考。

唯一可实证的步骤已执行完毕。

## 4. 已准备物料 (目录)

- tools/platform-tools/ — adb/fastboot 37.0.1 (官方)
- apk/SakiSU_v4.3.0-sakisu.1_arm64-v8a.apk — SHA256 已验证与官方一致
- src/CyberMeowfia-main/ — NebuSec 官方 PoC + exploit 源码
- kernel_config.txt — 完整内核配置 (8105 行)
- device_info.txt / prereq.txt / blocks.txt / uname.txt — 设备实测数据
- scripts/ — 配套脚本


参考 ghostlock-oneplus 项目中的 /tools 目录。流程通常是：从手机中提取 boot.img -> 使用工具解包获取内核 (kernel) -> 利用 objdump 等反汇编工具分析关键函数（如 rt_mutex_adjust_prio_chain）-> 找到与 rb_erase 等操作相关的指令及操作数地址 -> 反推出正确的结构体偏移（如 pi_tree 在 waiter 结构中的位置 +0x28）-> 最终填入项目的 target.h 或 offsets.h 配置文件中

## 6. 重大更新 (2026-08-23 QEMU 阶段) — 漏洞已被 vivo 修复!

### 反汇编实证: 设备内核 5.10.246 已 backport CVE-2026-43499 修复

对设备 boot.img 提取的 output.elf 反汇编 rt_mutex_start_proxy_lock:

```
rt_mutex_start_proxy_lock @ 0xffffffc0082282d8:
  bl  __rt_mutex_start_proxy_lock
  cbz w0, +0x90              # ret==0 跳过
  bl  remove_waiter          # 0x228364 ← 修复! (ret!=0 时正确清理 waiter)
```

上游修复 (5.10.261) 的形态 = 拆分 __rt_mutex_start_proxy_lock +
公开版本失败时调用 remove_waiter。设备内核完全吻合。GPL 源码 (5.10.177)
也包含此修复, 双重确认。

### 对结论的影响 (颠覆)

| 旧结论 (ASSESSMENT v1) | 新结论 |
|---|---|
| 5.10.246 < 5.10.261, 漏洞未修复 | ❌ 错! vivo 已 backport |
| PoC panic = 漏洞存在 | ❌ panic 是修复后利用失败的保护行为 |
| 免解锁临时 root 理论可行(需移植) | ❌ 当前固件彻底不可行 |
| 可尝试 preload.so 移植 | ❌ 无漏洞可打 |

### 为什么 PoC 会 panic
CyberMeowfia 的 poc.c 针对未修复内核构造 UAF; 在已修复内核上,
其非法内存操作触发 UBSAN_TRAP + PANIC_ON_OOPS → panic 重启。
(这解释了 panic 但无法解释为漏洞存在)

### 新出路
1. 降级到旧版本固件 (漏洞未修复的版本) — 若 vivo 允许
2. 等待新内核漏洞
3. 走 BL 解锁路线 (MTK BROM/DA, 与内核漏洞无关) — 仍然可行