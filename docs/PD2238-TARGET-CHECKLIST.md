# PD2238 (iQOO Neo7 SE) GhostLock target.h 提取清单

设备内核: 5.10.246-android12-9-g9c94fefc2317-dirty | aarch64 | 4K页 | **VA_BITS=39** | KASLR=y
对照模板: CyberMeowfia/IonStack/exploit/src/targets/tokay-CP2A.260605.012/target.h (Pixel, 48位VA — 常量不可照抄!)

## A. 内存布局常量 — 已按 39 位 VA 计算完成 (来源: 本地源码 memory.h 公式)

| 宏 | 值 | 说明 |
|---|---|---|
| PAGE_OFFSET / DIRECT_MAP_BASE | `0xFFFFFF8000000000` | -(1<<39) |
| DIRECT_MAP_END | `0xFFFFFFC000000000` | _PAGE_END(39) |
| KERNELSNITCH_IDENTITY_START/END | 同上线性区 | 5.10 无独立 identity 映射, 用线性区 |
| VMEMMAP_SIZE | `0x100000000` (4GB) | (_PAGE_END-PAGE_OFFSET)>>6 |
| VMEMMAP_START | `0xFFFFFFBFFFE00000` | -VMEMMAP_SIZE-2M |
| MODULES_VADDR (=KASAN_SHADOW_END) | `0xFFFFFFC000000000` | GENERIC/SW_TAGS 未开, HW_TAGS 不占 shadow |
| MODULES_END / KIMAGE_VADDR | `0xFFFFFFC080000000` | +128M |
| **KIMAGE_TEXT_BASE (静态)** | `0xFFFFFFC080800000` (待验证) | KIMAGE_VADDR+TEXT_OFFSET(0x80000); 以 kallsyms 的 `_text` 为准 |
| KASLR slide | 运行时未知 | KernelSnitch 适配后测得; 静态 kallsyms 地址 = 无 slide 链接地址 |
| P0_PHYS_OFFSET | `0x40000000` (待验证) | MTK 常规 DRAM 基址; 可由 Image 内 self-reloc 或 dts 确认 |

⚠️ 注意: 与 Pixel 模板最大差异就是这组值——48 位 vs 39 位, 直接照抄必 panic。

## B. 内核符号偏移 — 等 boot.img 后跑 scripts\02_boot_kallsyms.ps1

kallsyms 静态提取 (CONFIG_KALLSYMS_BASE_RELATIVE=y ✓):
```
ashmem_misc_fops        ashmem_ioctl        ashmem_compat_ioctl   ashmem_mmap
ashmem_open             ashmem_release      ashmem_show_fdinfo
configfs_read_iter      configfs_bin_write_iter
copy_splice_read        noop_llseek         init_task       init_uts_ns
empty_zero_page         root_task_group     selinux_blob_sizes
selinux_enforcing       security_hook_heads kmalloc_caches  anon_pipe_buf_ops
```
SLIDE 阶段附加符号: `nfnetlink_log 相关 logger 结构`, `sysctl 表中的 boot_id 节点`
(本机 NF_LOG_* 均未启用 ⚠️ nfnl_logger 可能不存在 → slide 阶段需换锚点, 参考 qhyz 移植记录改用 perf 泄露或其它 .data 锚点)

## C. 结构体字段偏移 — 由本地源码推导 (5.10.177≈5.10.246 核心结构体基本稳定)

| 组 | 字段 | 推导方式 |
|---|---|---|
| rt_mutex_waiter | tree_entry/pi_tree_entry/task/lock/wake_state/prio/deadline/ww_ctx | 源码 kernel/locking/rtmutex.c 结构定义 |
| task_struct | pid/tgid/real_parent/cred/real_cred/comm/tasks/thread_group/pi_lock/pi_waiters/pi_top_task/pi_blocked_on/seccomp/atomic_flags | include/linux/sched.h + 编译验证 |
| cred | uid/security/capabilities/securebits | include/linux/cred.h |
| pipe_inode_info | head/tail/bufs/tmp_page/user... | include/linux/pipe_fs_i.h |
| file_operations | 全部 ABI 固定 | 不需提取 |
| struct page / slab | compound_head/type | mm_types.h |
| configfs dir | page/needs_read_fill/bin_buffer... | fs/configfs/*.h |

方法: 用 kernel_config.txt 配置编译本地源码 vmlinux (需 arm64 工具链+pahole), 或 pahole 直读;
⚠️ vivo -dirty 补丁可能动过核心结构 → 关键字段用 kallsyms 交叉验证。

## D. 已确认的利用阻力 (config 层面)

- CONFIG_INIT_ON_ALLOC_DEFAULT_ON=y — 分配清零, 影响复用型 spray 时序
- CONFIG_SLAB_FREELIST_RANDOM/HARDENED + SHUFFLE_PAGE_ALLOCATOR=y — 标准 hardening, GhostLock 技术栈已覆盖
- CONFIG_KASAN_HW_TAGS=y — D8200 无 MTE 硬件, 判定为 defconfig 残留、运行时无效 (低置信度, 首次 panic dump 可复核)
- CONFIG_SLUB_MIRROR=y — 非 mainline 加固 (freelist 镜像校验?), 需逆向 slub.c 确认影响
- CONFIG_UBSAN_TRAP=y + PANIC_ON_OOPS=y — 致命组合不变, 试错成本极高

## E. 待办状态

- [x] 工具链: payload-dumper-go 2.0.2 / magiskboot / python311便携版+vmlinux-to-elf 1.2.3
- [x] 内存布局常量计算 (39位)
- [x] 卡刷包解包 → boot.img (已完成: OTA 是 old-dat 格式, 关键镜像直接可提)
- [x] kallsyms 静态提取 (174,277 符号, output.elf 57.9MB)
- [ ] 结构体偏移推导 (源码编译或人工分析)
- [ ] preload-so 交叉编译 (NDK) + KernelSnitch 5.10 适配 ← 最大风险点
## F. 实测结果 (2026-08-23 晚, 卡刷包到位后)

### 固件确认
- OTA = 传统 old-dat 格式 (非 A/B payload), 89 项, 关键镜像直接 .img 可提
- boot.img: header v4, kernel gzip, ramdisk lz4_legacy, OS 12.0.0, patch 2025-03
- 内核版本串与设备完全一致: 5.10.246-android12-9-g9c94fefc2317-dirty (clang 12.0.5)
- vermagic 实测: "... mod_unload modversions vivo aarch64" ← vivo 标志实锤

### kallsyms 静态提取: 全量成功
- 174,277 符号 | _text = 0xffffffc008000000 (KIMAGE_TEXT_BASE 实测)
- output.elf 57.9MB (vmlinux-to-elf 1.2.3), 可继续 IDA/gdb 分析

### 符号偏移命中表 (全部实测)
| 符号 | OFF | 状态 |
|---|---|---|
| ASHMEM_MISC_FOPS (ashmem_misc+0x10) | 0x2c851e8 | ELF dump 确认指向 ashmem_fops |
| ASHMEM_FOPS | 0x2595010 | ✓ |
| ASHMEM_IOCTL/MMAP/OPEN/RELEASE/SHOW_FDINFO | 0x1254c78 / 0x1255388 / 0x12555cc / 0x1255688 / 0x12557e8 | ✓ |
| CONFIGFS_READ_BIN (.cfi_jt) | 0x1a3b078 | ELF dump 确认在 bin_fops 表 +0x10 |
| CONFIGFS_WRITE_BIN (.cfi_jt) | 0x1a3b668 | ELF dump 确认在 bin_fops 表 +0x18 |
| COPY_SPLICE_READ (generic_file_splice_read) | 0x656e9c | 5.10 名字, ✓ |
| NOOP_LLSEEK | 0x5d921c | ✓ |
| INIT_TASK / INIT_UTS_NS | 0x2aec240 / 0x2aebfe8 | ✓ |
| EMPTY_ZERO_PAGE / ROOT_TASK_GROUP | 0x2d2d000 / 0x2d33100 | ✓ |
| SELINUX_BLOB_SIZES / ENFORCING | 0x25d86d0 / 0x2a94d6c | ✓ |
| SECURITY_HOOK_HEADS / KMALLOC_CACHES | 0x25d8038 / 0x25d7b70 | ✓ |
| ANON_PIPE_BUF_OPS | 0x2440ba8 | ✓ |
| INIT_NET / INIT_NSPROXY | 0x2c8f0c0 / 0x2b00fd0 | ✓ |
| SYSCTL_BOOTID (slide 或acles) | 0x2ee910d | ✓ u8[16] 未对齐 |
| loggers[] (slide 供体) | 0x2ae1618 | 全零数组但地址有效 |
| nfulnl_log_packet (slide 佐证) | 0x14c331c | nfnetlink_log 编译在内! |

### 结论: slide 锚点大概率不用换
NF_LOG_L3 钩子关闭 ≠ nfnetlink_log 不存在 (函数+数据结构都在),
loggers[] 全零不影响其作为 .data 供体。官方 slide 机制可直接用, 仅换地址值。

### 产物
- work/ota_out/: boot/vendor_boot/lk/preloader_*/vbmeta*/scatter.txt/recovery/dtbo/固件镜像
- work/boot_out/: kernel / ramdisk.cpio / kallsyms.txt(8MB) / output.elf(57.9MB) / target_pd2238_draft.h
- target.h 草案: 符号偏移全部实测, 结构体偏移继承 aristotle (5.10 QEMU/gdb 验证)

## G. M3 QEMU 验证结果 (2026-08-23)

### 环境
- QEMU 11.1.0 (weilnetz Windows 版) + NDK r29 clang 21
- PD2238 内核 Image 在 QEMU virt (cortex-a72, 1GB, nokaslr) 启动成功
- initramfs 方案: bsdtar newc + mode 0755 补丁 (Python 生成器有 bug 已弃用)
- 注意: QEMU 物理加载地址与链接布局不同, 物理读取(xp)会看到 0xcc 毒化;
  必须用 monitor 虚拟地址读取 (x 命令, 走客机页表) 验证

### 验证结果: 13/13 符号偏移全部正确
init_task=0x2aec240 (comm="swapper/", real_cred/cred=同指针, pid/tgid=0)
init_uts_ns=0x2aebfe8 ("Linux")
sysctl_bootid=0x2ee910d (uuid 区)
root_task_group=0x2d33100 / kmalloc_caches=0x25d7b70
security_hook_heads=0x25d8038 / anon_pipe_buf_ops=0x2440ba8
loggers=0x2ae1618 / ashmem_fops=0x2595010 / empty_zero_page=0x2d2d000 (全零)

### 工具
- scripts\03_qemu_boot.ps1: boot (冒烟) / -Verify (monitor 偏移验证)
- work\qemu\verify_vaddr.py: 虚拟地址验证脚本
- 遗留: -m 2048 时 initrd 放置异常, 用 -m 1024; cmd.exe 逗号问题已绕开