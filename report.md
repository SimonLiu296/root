# GhostLock (CVE-2026-43499) Round-1 报告

**目标设备:** iQOO Neo7 SE / PD2238 / V2238A  
**内核:** `5.10.246-android12-9-g9c94fefc2317-dirty` (clang 12.0.5, aarch64)  
**分析日期:** 2026-09-09  
**任务:** 解包 boot → 提取 vmlinux/kallsyms → 对照 CyberMeowfia CVE-2026-43499 源码宏骨架 → 交叉验证并设置 PD2238 偏移  

本轮只做静态解包、符号提取与偏移对照，不触发利用。

复现脚本与原始数据:

- `work/boot_out/round1_verify.py` (独立提取器)
- `work/boot_out/round1_verify.json` / `round1_verify.txt`
- `work/boot_out/target_pd2238_verified.h`
- 已写入: `src/aristotle-root/src/targets/pd2238-16.3.15.0.W10/target.h`

公开对照 (二次查证):

- NebuSec IonStack part II/III: <https://nebusec.ai/research/ionstack-part-2/> <https://nebusec.ai/research/ionstack-part-3/>
- 源码树: `IonStack/CVE-2026-43499` (tokay `target.h` 为 GKI 6.12 宏骨架，**数值禁止照抄到 5.10**)

---

## 1. boot.img 解包与 vmlinux 提取

### 1.1 `work/ota_out` — 分区镜像

卡刷包为传统 old-dat / scatter 形态 (非 A/B payload)。关键镜像已在目录内:

| 文件 | 大小 | 作用 |
|---|---:|---|
| `boot.img` | 100663296 | Android boot v4, magic `ANDROID!` |
| `vendor_boot.img` | 67108864 | vendor ramdisk / kernel_offset 候选 |
| `recovery.img` | 201326592 | 救砖/对照 |
| `dtbo.img` | 280400 | DTBO |
| `lk.img` | 3063472 | Little Kernel |
| `preloader_{emmc,ufs,raw}.img` | ~505–509 KB | MTK preloader |
| `md1img.img` | 74035600 | 基带 |
| `vbmeta*.img` | 4096 | AVB |
| `firmware.bin` | 59768832 | 固件 blob |
| `scatter.txt` | 2670 | `boot` 分区地址 `0x64d80000` |

**结论:** `work/ota_out` 作为 OTA/线刷产物目录是正确且完整的。缺少 `init_boot.img` 属预期 (非 GKI 16 拆分 boot 的 MTK 5.10 机型)。

### 1.2 `work/boot_out` — 内核解包

| 产物 | 大小 | SHA-256 (前 16 hex) | 判定 |
|---|---:|---|---|
| `boot.img` | 100663296 | `e95ccd773652f097…` | 与 `ota_out/boot.img` **逐字节相同** |
| `kernel` | 51766900 | `bda9ad91f7236a4a…` | 未压缩 ARM64 Image (EFI MZ stub `4d5a`) |
| `Image` | 51766900 | 同上 | `kernel == Image` |
| `output.elf` | 60725041 | `b4214141f975ae24…` | ELF64 ET_DYN, `e_machine=AARCH64`, magic `7f454c46` |
| `kallsyms.txt` | 8260566 | `daa375c5aee6ff51…` | **174,277** 行符号 |
| `ramdisk.cpio` | 2586880 | `ce738c949c6d011e…` | newc cpio |

`Image` 内 Linux banner:

```
Linux version 5.10.246-android12-9-g9c94fefc2317-dirty (build-user@build-host)
(Android clang 12.0.5 / LLD 12.0.5)
```

与真机 `/proc/version` 同源。

kallsyms 锚点:

| 符号 | VA |
|---|---|
| `_text` / `_head` | `0xffffffc008000000` |
| `_stext` | `0xffffffc008010000` |
| `_etext` | `0xffffffc009c40000` |
| `_end` | `0xffffffc00af20000` |

→ **KIMAGE_TEXT_BASE = `0xffffffc008000000`** (vmlinux-to-elf 重建地址; 39-bit VA 约定下的静态链接基址)。

`output.elf` 可通过 `PT_LOAD` 按 VA 读取 `.text/.data/.bss`。本轮所有 “ELF dump” 均走该映射，而不是相信 kallsyms 单源。

**解包结论: 通过。** `work/boot_out` 已具备完整 vmlinux (ELF) + 全量符号表。缺失 magiskboot 的 `header`/`dtb` 旁路文件不影响符号分析 (v4 boot 的 kernel 已是完整 Image)。

---

## 2. CVE-2026-43499 源码树

要求路径: `src/CyberMeowfia-main`。

| 检查项 | 结果 |
|---|---|
| 目录存在 | 是 (`src/CyberMeowfia.zip` 解包, **无 `.git`**) |
| `IonStack/CVE-2026-43499/exploit/src/main.c` | 是 |
| `offset.h` → `TARGET_CONFIG_H` | 是 (按 `make PROJECT=` 选 target.h) |
| `poc/poc.c` | 是 |
| 参考 target `tokay-CP2A.260605.012/target.h` | 是 |
| `git clone https://github.com/NebuSec/CyberMeowfia/tree/main/IonStack/CVE-2026-43499` | **该 URL 不能直接 clone** (GitHub tree 页); 正确是 clone 整仓再进子目录。本地 zip 内容与公开 IonStack 布局一致 |

源码预期的 **宏骨架** (来自 tokay, GKI **6.12** / Android 17) 包括:

- 符号 OFF: `ASHMEM_*` `CONFIGFS_READ_ITER` `CONFIGFS_BIN_WRITE_ITER` `COPY_SPLICE_READ` `INIT_TASK` `SLIDE_NFULNL_LOGGER` `SLIDE_LOGGERS_0_1` `SLIDE_SYSCTL_BOOTID` …
- 栈: `PSELECT_WAITER_WORD_SHIFT`
- 结构: `rt_mutex_waiter` (含 `wake_state`/`ww_ctx`)、`file_operations`、`configfs_buffer`、`task_struct`

IonStack part III 利用链 (公开 writeup, 二次确认):

1. GhostLock 留下悬空 `rt_mutex_waiter`
2. `pselect` 回收栈帧并伪造 waiter → 约束写
3. 改 `boot_id` sysctl `.data` → 读 `loggers[0][1]` 泄 `&nfulnl_logger` → KASLR slide
4. 劫持 `ashmem` `file_operations` 为同签名 `configfs` handler
5. `pipe_buffer.page` 升级任意读写 → patch cred / SELinux

**源码结论: 通过 (zip 等价于 clone 子树)。** Pixel 数值不得用于 PD2238。

---

## 3. 符号表解析

解析器: `round1_verify.py` 读取 `kallsyms.txt` (`addr type name`)。  
GhostLock 相关命中 (VA 与 `_text` 相对偏移):

| 逻辑名 | kallsyms 符号 | VA | OFF = VA - `_text` |
|---|---|---|---|
| ASHMEM_MISC | `ashmem_misc` | `0xffffffc00ac851d8` | `0x02c851d8` |
| ASHMEM_MISC_FOPS | `ashmem_misc+0x10` | `0xffffffc00ac851e8` | `0x02c851e8` |
| ASHMEM_FOPS | `ashmem_fops` | `0xffffffc00a595010` | `0x02595010` |
| ASHMEM_IOCTL | `ashmem_ioctl` | `0xffffffc009254c78` | `0x01254c78` |
| ASHMEM_COMPAT_IOCTL | `compat_ashmem_ioctl` | `0xffffffc009255328` | `0x01255328` |
| ASHMEM_READ_ITER | `ashmem_read_iter` | `0xffffffc009254ba4` | `0x01254ba4` |
| ASHMEM_MMAP | `ashmem_mmap` | `0xffffffc009255388` | `0x01255388` |
| ASHMEM_OPEN | `ashmem_open` | `0xffffffc0092555cc` | `0x012555cc` |
| ASHMEM_RELEASE | `ashmem_release` | `0xffffffc009255688` | `0x01255688` |
| ASHMEM_SHOW_FDINFO | `ashmem_show_fdinfo` | `0xffffffc0092557e8` | `0x012557e8` |
| CONFIGFS_READ_BIN **body** | `configfs_read_bin_file` | `0xffffffc00872566c` | `0x0072566c` |
| CONFIGFS_WRITE_BIN **body** | `configfs_write_bin_file` | `0xffffffc0087258e4` | `0x007258e4` |
| CONFIGFS_READ_BIN **CFI JT** | `configfs_read_bin_file.cfi_jt` | `0xffffffc009a3b078` | `0x01a3b078` |
| CONFIGFS_WRITE_BIN **CFI JT** | `configfs_write_bin_file.cfi_jt` | `0xffffffc009a3b668` | `0x01a3b668` |
| CONFIGFS_BIN_FOPS | `configfs_bin_file_operations` | `0xffffffc00a44c0e0` | `0x0244c0e0` |
| COPY_SPLICE_READ | `generic_file_splice_read` | `0xffffffc008656e9c` | `0x00656e9c` |
| NOOP_LLSEEK | `noop_llseek` | `0xffffffc0085d921c` | `0x005d921c` |
| INIT_TASK | `init_task` | `0xffffffc00aaec240` | `0x02aec240` |
| INIT_UTS_NS | `init_uts_ns` | `0xffffffc00aaebfe8` | `0x02aebfe8` |
| EMPTY_ZERO_PAGE | `empty_zero_page` | `0xffffffc00ad2d000` | `0x02d2d000` |
| ROOT_TASK_GROUP | `root_task_group` | `0xffffffc00ad33100` | `0x02d33100` |
| SELINUX_BLOB_SIZES | `selinux_blob_sizes` | `0xffffffc00a5d86d0` | `0x025d86d0` |
| SELINUX_ENFORCING | **无此全局符号** | — | — |
| SELINUX_ENFORCING_BOOT | `selinux_enforcing_boot` | `0xffffffc00aa94d6c` | `0x02a94d6c` |
| SELINUX_STATE | `selinux_state` | `0xffffffc00aec9c40` | `0x02ec9c40` |
| SECURITY_HOOK_HEADS | `security_hook_heads` | `0xffffffc00a5d8038` | `0x025d8038` |
| KMALLOC_CACHES | `kmalloc_caches` | `0xffffffc00a5d7b70` | `0x025d7b70` |
| ANON_PIPE_BUF_OPS | `anon_pipe_buf_ops` | `0xffffffc00a440ba8` | `0x02440ba8` |
| SYSCTL_BOOTID | `sysctl_bootid` | `0xffffffc00aee910d` | `0x02ee910d` |
| RANDOM_TABLE | `random_table` | `0xffffffc00ac45230` | `0x02c45230` |
| LOGGERS | `loggers` | `0xffffffc00aae1618` | `0x02ae1618` |
| NFULNL_LOGGER | `nfulnl_logger` | `0xffffffc00aae16f0` | `0x02ae16f0` |
| NFULNL_LOG_PACKET | `nfulnl_log_packet` | `0xffffffc0094c331c` | `0x014c331c` |
| RT_MUTEX_START_PROXY_LOCK | `rt_mutex_start_proxy_lock` | `0xffffffc0082282d8` | `0x002282d8` |
| REMOVE_WAITER | `remove_waiter` | `0xffffffc008225c60` | `0x00225c60` |
| SYS_PSELECT6 | `__arm64_sys_pselect6` | `0xffffffc008604e64` | `0x00604e64` |
| SYS_FUTEX | `__arm64_sys_futex` | `0xffffffc0082dbbf0` | `0x002dbbf0` |
| WORKER_THREAD | `worker_thread` | `0xffffffc00819c380` | `0x0019c380` |

**5.10 相对 GKI 6.12 的符号空缺 (预期, 非提取失败):**

- `configfs_read_iter` / `configfs_bin_write_iter` — 5.10 `fs/configfs/file.c` 使用 `.read` / `.write` (`configfs_read_bin_file` / `configfs_write_bin_file`)
- `selinux_enforcing` — 运行时标志在 `selinux_state` 内; 全局只剩 `selinux_enforcing_boot`

漏洞原语符号 `rt_mutex_start_proxy_lock` 与 `remove_waiter` 均存在，与 CVE-2026-43499 根因 (rollback 清 `current->pi_blocked_on` 而非 `waiter->task`) 匹配。

---

## 4. 偏移对照表

列说明:

- **Tokay (源码预期数值):** Pixel GKI 6.12, 仅作宏名/语义对照, **不应相等**
- **旧草案:** 此前 `target_pd2238_draft.h`
- **本轮提取:** kallsyms 和/或 ELF
- **已设置:** Round-1 写入 `target.h` 的值
- **判定:** 旧草案 vs 本轮黄金值

| 宏 | Tokay 6.12 | 旧草案 | 本轮提取 | 已设置 | 判定 |
|---|---|---|---|---|---|
| `KIMAGE_TEXT_BASE` | `0xffffffc008000000` | 同左 | `_text` 同左 | `0xffffffc008000000` | **通过** (地址碰巧同形, 语义仍是 5.10 链接基址) |
| `ASHMEM_MISC_FOPS_OFF` | `0x0217cb80` | `0x02c851e8` | ELF `misc+0x10`, 指针命中 `ashmem_fops` | `0x02c851e8` | **通过** |
| `ASHMEM_FOPS_OFF` | `0x01280b50` | `0x02595010` | kallsyms | `0x02595010` | **通过** |
| `ASHMEM_IOCTL_OFF` | `0x00c38d28` | `0x01254c78` | kallsyms | `0x01254c78` | **通过** |
| `ASHMEM_COMPAT_IOCTL_OFF` | `0x00c39660` | `0x01254c78` (误等同 ioctl) | `compat_ashmem_ioctl` = `0x01255328` | `0x01255328` | **旧草案失败, 已纠正** |
| `ASHMEM_MMAP/OPEN/RELEASE/SHOW_FDINFO` | (Pixel) | 与 kallsyms 一致 | 一致 | 维持 | **通过** |
| `CONFIGFS_READ_ITER_OFF` | `0x00464400` (`*_iter`) | alias → CFI JT | 无 `*_iter` 符号 | alias → `0x01a3b078` | **语义失败 (无 iter); 值作 .read 用则通过** |
| `CONFIGFS_BIN_WRITE_ITER_OFF` | `0x00464930` | alias → CFI JT | 无 `*_iter` | alias → `0x01a3b668` | 同上 |
| `CONFIGFS_READ_BIN_OFF` | (无) | `0x01a3b078` | `.cfi_jt` = `0x01a3b078`; body = `0x0072566c` | `0x01a3b078` | **通过** (必须用 CFI JT, 与 fops 表一致) |
| `CONFIGFS_WRITE_BIN_OFF` | (无) | `0x01a3b668` | `.cfi_jt` | `0x01a3b668` | **通过** |
| `COPY_SPLICE_READ_OFF` | `copy_splice_read` | `0x00656e9c` | `generic_file_splice_read` | `0x00656e9c` | **通过** (5.10 换名) |
| `NOOP_LLSEEK_OFF` | Pixel | `0x005d921c` | 一致 | 维持 | **通过** |
| `INIT_TASK_OFF` | Pixel | `0x02aec240` | 一致; ELF `comm`@+`0x790`=`swapper` | 维持 | **通过** |
| `INIT_UTS_NS_OFF` | Pixel | `0x02aebfe8` | ELF 可见 ASCII `Linux` | 维持 | **通过** |
| `EMPTY_ZERO_PAGE` / `ROOT_TASK_GROUP` / `SELINUX_BLOB_SIZES` / `SECURITY_HOOK_HEADS` / `KMALLOC_CACHES` / `ANON_PIPE_BUF_OPS` | Pixel | 与 kallsyms 一致 | 一致 | 维持 | **通过** |
| `SELINUX_ENFORCING_OFF` | `selinux_enforcing` | `0x02a94d6c` (= `selinux_enforcing_boot`) | 无 live 全局; `selinux_state`=`0x02ec9c40` | `SELINUX_STATE_OFF` | **旧草案失败 (boot 标志); 已改 state 基址, 字段偏移仍未锁定** |
| `SLIDE_NFULNL_LOGGER_OFF` | `nfulnl_logger` 对象 | `0x02ae1618` (误用数组基址) | `0x02ae16f0` | `0x02ae16f0` | **旧草案失败, 已纠正** |
| `SLIDE_LOGGERS_0_1_OFF` | `loggers[0][1]` | `0x02ae1618` (数组[0][0]) | base+8 = `0x02ae1620` | `0x02ae1620` | **旧草案失败, 已纠正** |
| `SLIDE_SYSCTL_BOOTID_OFF` | Pixel | `0x02ee910d` | `sysctl_bootid` u8[16] 未对齐 | `0x02ee910d` | **通过** |
| `PSELECT_WAITER_WORD_SHIFT` | `1` | `-2` | **无法从符号表导出** | `-2` (继承) | **未验证** |
| `WAITER_PRIO_OFF` | `0x44` (6.12 有 wake_state) | `0x40` | 5.10 `rtmutex_common.h`: prio 紧随 lock | `0x40` | **通过 (源码布局)** |
| `WAITER_WAKE_STATE_OFF` / `WW_CTX` | `0x40` / `0x50` | `-1` | 5.10 结构无这两字段 | `-1` | **通过 (源码布局)** |
| `TASK_COMM_OFF` | `0x848` | `0x790` | ELF `init_task+0x790` = `swapper` | `0x790` | **通过** |
| `TASK_CRED_OFF` / `TASK_REAL_CRED_OFF` | `0x838` / `0x830` | `0x780` / `0x778` | ELF 两处均为内核指针 `0xffffffc00ab01130` | 维持 | **通过** |
| `FOPS_SPLICE_READ_OFF` | `0xc8` | `0xc0` (实为 splice_write) | 5.10 `file_operations` 推算 | `0xc8` | **旧草案失败, 已纠正** |
| `FOPS_SHOW_FDINFO_OFF` | `0xe0` | `0xe0` | 推算 | `0xe0` | **通过** |
| `CFG_PAGE_OFF` | 16 | 16 | `configfs_buffer.page` 在 count+pos 之后 | 16 | **通过 (源码)** |
| `CFG_BIN_BUFFER_OFF` | 88 | 88 | Pixel 布局; 5.10 `mutex` + `ANDROID_OEM_DATA` 会改后续字段 | 88 (未改) | **未验证** |

### 4.1 ELF 动态交叉确认 (PT_LOAD 读 VA)

1. **`ashmem_misc+0x10` → `ashmem_fops`:** 指针 `0xffffffc00a595010`, 与符号完全一致。
2. **`ashmem_fops` 槽位:** `llseek` 与 `read_iter` 非空; `.read`/`.write`/`.write_iter` 为 0。`read_iter` = `ashmem_read_iter.cfi_jt` (`0xffffffc009a2ae10`)。
3. **`configfs_bin_file_operations`:** `.read` = `configfs_read_bin_file.cfi_jt`, `.write` = `configfs_write_bin_file.cfi_jt`, `.read_iter`/`.write_iter` = 0。
4. **`init_uts_ns`:** 内含 ASCII `Linux`。
5. **`init_task`:** `comm` 在 `+0x790`; `real_cred`/`cred` 在 `+0x778`/`+0x780`。
6. **`loggers[]` 静态镜像 64 字节全零。** `nfulnl_logger` 对象非零 (含内核指针)。官方 slide 依赖运行时 `nfnetlink_log` 把 `&nfulnl_logger` 填进 `loggers[0][1]`, 静态 ELF **不能**证明运行时槽位已填充。
7. **`sysctl_bootid`:** 16 字节全零 (启动时由 `proc_do_uuid` 填充), 地址未 8 字节对齐, 与 `static u8 sysctl_bootid[UUID_SIZE]` 一致。

---

## 5. 验证结论

### 5.1 总评

| 项目 | 结果 |
|---|---|
| boot 解包 / vmlinux / kallsyms 位置与完整性 | **通过** |
| CVE-2026-43499 源码位于 `src/CyberMeowfia-main` | **通过** (zip, 非 git) |
| 符号偏移可从 kallsyms+ELF 独立复现 | **通过** |
| 旧草案全部符号一次性正确 | **失败** (5 处需改, 见下) |
| Pixel tokay 数值可直接用于 PD2238 | **失败** (必须按本机提取) |
| 5.10 上可原样使用 Pixel `read_iter`/`write_iter` 劫持路径 | **失败** (ABI 不匹配) |
| `PSELECT_WAITER_WORD_SHIFT` / `CFG_BIN_BUFFER_*` | **本轮无法闭合** |

**本轮对 “符号级 target.h” 的判定: 有条件通过。**  
已纠正的符号可以进入后续移植; **不能**声称 PD2238 已具备与 tokay 相同的可编译即用利用配置。

### 5.2 已纠正的错误 (旧草案 → 本轮)

1. `ASHMEM_COMPAT_IOCTL_OFF`: `0x1254c78` → `0x1255328` (`compat_ashmem_ioctl`)
2. `SLIDE_NFULNL_LOGGER_OFF`: `0x2ae1618` (数组) → `0x2ae16f0` (`nfulnl_logger`)
3. `SLIDE_LOGGERS_0_1_OFF`: `0x2ae1618` → `0x2ae1620` (`&loggers[0][1]`)
4. `SELINUX_ENFORCING_OFF`: 不再指向 `selinux_enforcing_boot`; 改为 `selinux_state` 基址 `0x2ec9c40` (字段位移仍受 `__randomize_layout` 影响)
5. `FOPS_SPLICE_READ_OFF`: `0xc0` → `0xc8`

### 5.3 原因分析 — 为何 Pixel 路径不能 1:1 落到 5.10

**CFI 与 fops 签名。** IonStack part III 在 Android 17 上把 `ashmem` 的 `read_iter`/`write_iter` 换成 `configfs_*_iter` (同为 `ssize_t(struct kiocb *, struct iov_iter *)`, CFI hash 相同)。PD2238:

- `ashmem_fops` 只有 `read_iter` (CFI JT), 没有 `.write` / `.write_iter`
- `configfs_bin_file_operations` 只有 `.read` / `.write` (CFI JT), 没有 `*_iter`

因此 **不能**把 tokay 的 `CONFIGFS_READ_ITER`/`CONFIGFS_BIN_WRITE_ITER` 宏语义直接灌进 ashmem 的 iter 槽。后续若继续走 ashmem, 需要改为填充 `.read`/`.write`, 或另选 victim。这是移植问题, 不是符号提取失败。

**SELinux。** 旧值命中 `selinux_enforcing_boot` (cmdline 副本)。写它不会让运行时进入 permissive。live 状态在 `selinux_state` (BSS, 静态全零)。该结构在源码中带 `__randomize_layout`, 在未确认 `RANDSTRUCT` 关闭前, `enforcing` 布尔偏移不能当作已验证。

**KASLR slide。** 静态 `loggers[]` 全零。`nfulnl_log_packet` 已编进内核, 运行时 `nf_log_set` 可能填充槽位, 但这必须 QEMU/真机读 `loggers[0][1]` 才能确认。备用泄漏源: `nfulnl_logger` 对象首个 qword 已是内核指针。

**PSELECT_SHIFT。** 这是 `pselect` fdset 窗口相对 `rt_mutex_waiter` 栈槽的 word 位移, 只能由栈帧测量 (已有 `sys_pselect6.asm` / PLAN-A/B 文档) 得出, kallsyms 给不出。维持 `-2` 仅为继承假设。

**configfs_buffer。** `CFG_PAGE_OFF=16` 与 5.10 源码一致。`CFG_BIN_BUFFER_OFF=88` 来自 Pixel; 5.10 的 `struct mutex` 含 `ANDROID_OEM_DATA_ARRAY(1,2)`, 会把后续字段往后推。未用 pahole/编译 vmlinux 前不能当黄金值。

### 5.4 已设置的偏移落点

- `work/boot_out/target_pd2238_verified.h`
- `src/aristotle-root/src/targets/pd2238-16.3.15.0.W10/target.h`

未向 `CyberMeowfia-main/exploit/src/targets/` 复制一份 (本轮交付物以 `report.md` 与上述 header 为准)。

---

## 6. 可复现步骤

```text
1. 确认 work/ota_out/boot.img SHA-256 = work/boot_out/boot.img
2. Image 内搜索 "Linux version 5.10.246-android12-9"
3. python work/boot_out/round1_verify.py
4. 对照 round1_verify.json 中 extracted_symbols 与 elf_dumps
```

工具: 仓库内 `tools/python/python.exe` + `pyelftools`; 不依赖本机 PATH 上的 `nm`。

---

## 7. 建议的下一轮 (本轮停止, 仅记录)

1. 用 `sys_pselect6.asm` / `do_futex.asm` 实测 `PSELECT_WAITER_WORD_SHIFT`
2. pahole 或编译 `vivo-mtk510-src` 得到 `configfs_buffer` / `selinux_state` / `pipe_inode_info` 字段
3. QEMU 读运行时 `loggers[0][1]` 是否变为 `&nfulnl_logger`
4. 为 5.10 设计 ashmem/configfs 槽位策略 (`.read`/`.write` vs iter)
5. 再谈编译 `preload.so`

---

**第一轮执行完毕，等待后续指令**
