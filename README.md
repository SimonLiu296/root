# iQOO 临时 Root 工具箱优化版

面向 **iQOO Neo7 SE（PD2238 / V2238A）** 的本机研究工具箱，配套 Windows 一键入口、PowerShell 主流程、Linux / Termux 菜单脚本、设备信息采集脚本、固件包、预编译产物、源码树、文档、工具链、日志与备份目录。

当前主适配固件：`PD2238_A_16.3.15.0.W10`（设备报告中的内核为 `5.10.246-android12-9-g9c94fefc2317-dirty`，Android 16 / OriginOS）。脚本侧同时保留对部分其它机型入口的检测，**未在本仓库完成适配的机型一律视为不支持**。

本仓库提供的是**临时**权限研究流程，不是解锁 Bootloader、不是 Magisk 永久 Root、也不是官方售后方案。重启后状态会丢失，需重新走完整流程。

---

## ⚠️ 重要警告

**刷机、ROOT、内核内存操作均可能造成无法开机、数据丢失、失去保修，甚至变砖。**

请在继续之前完整阅读以下条款。使用本仓库即视为你已理解并自行承担全部后果。

1. **变砖风险**：错误机型、错误固件、错误镜像、中途断电、写入 `preloader` / `lk` 等关键分区，都可能导致无法开机。临时流程虽然原则上不写分区，一旦配合线刷、解锁或刷入错误镜像，风险立刻上升。
2. **保修风险**：ROOT、刷机、解锁 Bootloader 通常被视为私自改装，厂商可能拒绝保修。
3. **数据风险**：解锁、卡刷、线刷、救砖、系统还原都可能清空用户数据。操作前必须自行完整备份。
4. **稳定性风险**：内核 panic、自动重启、USB 掉线、调试授权丢失均为常见现象，**不等于成功**。
5. **仅限学习研究**：本项目仅供安全研究、固件分析和本人设备上的实验记录使用。
6. **禁止商用**：禁止出售、收费代刷、打包成“一键商用工具”、以及任何盈利性传播。
7. **禁止用于他人设备**：偏移、符号和载荷按 PD2238 本机固件裁剪，用到其它机型极易直接 panic。
8. **禁止违法用途**：不得用于未授权设备、窃取数据、绕过他人安全控制或任何违法活动。
9. **电量与环境**：操作前建议电量 ≥ 80%，使用可传输数据的原装或合格数据线，并关闭自动系统更新。
10. **救砖准备**：卡刷包 `PD2238_A_16.3.15.0.W10.V000L1-update-full.zip` 必须留在电脑上备用。未准备救砖物料时，不要进行任何分区级操作。

更细的风险分级与救砖思路见 [`docs/SAFETY.md`](docs/SAFETY.md)。旧版 [`说明.txt`](说明.txt) 中“无变砖风险”的表述**不作为安全承诺**，以本 README 与 `docs/SAFETY.md` 为准。

---

## 项目简介

| 项目 | 说明 |
|---|---|
| 名称 | iQOO 临时 Root 工具箱优化版 |
| 目标机型 | iQOO Neo7 SE / `PD2238` / `V2238A` |
| 目标固件 | `PD2238_A_16.3.15.0.W10`（卡刷包文件名带 `V000L1-update-full`） |
| 权限形态 | 临时（冷启动后失效） |
| Windows 入口 | `一键临时root.bat` → `root.ps1` |
| Linux / Termux 入口 | `IQOO临时root工具箱优化版.sh` |
| 设备采集 | `device.sh` → `设备信息报告.txt` |
| 研究文档 | `docs/`、`report.md` |
| 源码 | `src/` |
| 工具链 | `tools/` |
| 工作产物 | `work/` |
| 运行日志 | `logs/` |
| 备份目录 | `backups/` |

设计目标：把“设备检测 → 推送产物 → 记录日志 → 对照文档分析”收拢到同一仓库，避免散落在多台电脑、多个目录。

---

## 目录结构说明

仓库根目录（列出本 README 需要覆盖的全部路径；`等` 表示同级还可能出现本机生成文件）：

```tree
.
├── .gitattributes
├── .gitignore
├── apk/
├── backups/
├── device.sh
├── docs/
│   ├── ASSESSMENT.md
│   ├── DEPLOY.md
│   ├── MASTER-PLAN.md
│   ├── PD2238-TARGET-CHECKLIST.md
│   ├── PLAN-A-FDSET.md
│   ├── PLAN-B-FRAMES.md
│   ├── PLAN-C-BLUNLOCK.md
│   ├── PLAN1-COPYFROMUSER.md
│   ├── PREP.md
│   ├── ROADMAP.md
│   ├── SAFETY.md
│   ├── SIGFRAME-LAYOUT.md
│   └── TEMPROOT-RESEARCH.md
├── IQOO临时root工具箱优化版.sh
├── logs/
│   ├── archive-20260909/
│   ├── inject_stdout.txt
│   └── log_*.txt
├── PD2238_A_16.3.15.0.W10.V000L1-update-full.zip
├── poc
├── preload.so
├── README.md
├── report.md
├── root.ps1
├── scripts/
│   ├── 01_unpack_ota.ps1
│   ├── 02_boot_kallsyms.ps1
│   ├── 03_qemu_boot.ps1
│   ├── 04_build.ps1
│   ├── check_exploit.ps1
│   ├── measure_delta.ps1
│   ├── probe_pd2238.ps1
│   └── run_sigret_trace.ps1
├── src/
│   ├── aristotle-root/
│   └── vivo-mtk510-src/
├── tools/
│   ├── bin/
│   ├── mtkclient/
│   ├── ndk/
│   ├── platform-tools/
│   ├── python/
│   ├── qemu/
│   └── vmlinux-to-elf/
├── work/
│   ├── boot_out/
│   ├── ota_out/
│   ├── qemu/
│   └── run_exp.sh
├── 一键临时root.bat
├── 设备信息报告.txt
└── 说明.txt
```

`apk/`、`backups/` 可能为空目录，仅作占位，供后续放入安装包与备份文件。`tools/`、`src/`、`work/` 体积很大，部分内容是嵌套仓库或本机解包产物，不一定全部纳入 Git。

---

## 环境依赖

### 设备侧

- iQOO Neo7 SE（`PD2238` / `V2238A`），固件与卡刷包版本一致。
- 开启 **开发者选项 → USB 调试**（Windows 有线流程）或 **无线调试**（Linux / Termux 菜单流程）。
- 首次连接必须在手机上点允许调试授权。
- 建议关闭自动更新；研究阶段常见做法是冻结系统更新应用，具体命令见 `docs/DEPLOY.md`。
- 不要求已解锁 Bootloader。本工具箱当前阶段按“锁 BL + 临时内存操作”设计。

### Windows

- Windows 10 / 11，PowerShell 5+（系统自带即可）。
- `adb.exe`，按以下优先级查找：
  1. 仓库根目录 `adb.exe`
  2. `E:\adb\adb.exe`
  3. `tools\platform-tools\adb.exe`
  4. 系统 `PATH` 中的 `adb.exe`
- 可传输数据的 USB 线。
- 编译 `preload.so` 时还需要 `tools\ndk` 内的 Android NDK（`aarch64-linux-android35-clang`）。
- 解包 / 符号提取还需要：`tools\bin\payload-dumper-go.exe`、`tools\bin\magiskboot\magiskboot.exe`、`tools\python\python.exe`、`tools\vmlinux-to-elf`。
- QEMU 冒烟需要 `tools\qemu\qemu-system-aarch64.exe`。

### Linux / Termux

- 已安装 `adb`，并能访问设备。
- `bash`（Termux 路径常见为 `/data/data/com.termux/files/usr/bin/bash`）。
- `tput`、常规 coreutils（脚本用于自适应菜单宽度）。
- 设备上执行 `device.sh` 时，解释器为 `/system/bin/sh`，**无需 Root**。

### 明确不包含的承诺

- 不保证任意 OriginOS / Android 大版本通用。
- 不保证内核小版本升级后仍可用。
- 不提供商业售后、远程代操作或“百分百成功”承诺。

---

## 使用方法（Windows）

适合：电脑 + USB 数据线。

1. 手机用 USB 连接电脑，打开 USB 调试，弹出授权时点允许。
2. 确认仓库根目录存在 `preload.so`（或已由 `scripts\04_build.ps1` 编译到 `src\aristotle-root\build\...`）。
3. 双击 `一键临时root.bat`。它只做一件事：用 Bypass 策略调用同目录 `root.ps1`。
4. 也可在仓库根目录手动执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\root.ps1
```

5. 按屏幕提示确认机型、内核，并在**确认已经冷启动过手机**后输入 `y`。
6. 脚本会检测设备、清理残留、推送 `preload.so`、尝试息屏注入，并把设备上的 `log_*.txt` 拉到 `logs\`。
7. 失败后先看 `logs\`，不要连续狂点。需要干净的 `boot_id` 时，应先重启手机再跑下一轮。

`root.ps1` 对 PD2238 默认走 write-proof 观察流程：以日志里的判定句作为阶段结果，**不以“出现 su”或“USB 掉线”当成功**。

---

## 使用方法（Linux / Termux）

适合：已安装 adb 的 Linux 主机，或手机上的 Termux + 无线调试。

```bash
chmod +x "./IQOO临时root工具箱优化版.sh"
bash "./IQOO临时root工具箱优化版.sh"
```

菜单功能：

| 选项 | 作用 |
|---|---|
| `[1] 无线配对` | `adb pair`，输入无线调试的配对地址和配对码 |
| `[2] 设备连接` | `adb connect`，清理 offline 设备后建立连接 |
| `[3] 推送 preload.so` | 把载荷推到设备 `/data/local/tmp/preload.so` |
| `[4] 息屏注入` | 按脚本流程触发注入并尝试息屏 |
| `[5] root 提权` | 进入脚本内的后续提权 / shell 菜单 |
| `[6] B站主页` | 作者推广入口 |
| `[0] 退出程序` | 退出 |

在设备上采集硬件与系统信息（无需 Root）：

```bash
adb push device.sh /data/local/tmp/device.sh
adb shell sh /data/local/tmp/device.sh
```

输出可重定向保存为 `设备信息报告.txt`。

---

## 操作步骤

下面是推荐的完整研究流程。每一步都可能失败；失败时停下来看日志，而不是跳过备份和救砖准备。

### 0. 备份与物料

1. 把手机重要数据拷到电脑或云盘（相册、短信、验证器、应用数据）。
2. 确认卡刷包 `PD2238_A_16.3.15.0.W10.V000L1-update-full.zip` 完整可用。
3. 需要时可把当前 `preload.so`、关键日志、设备报告复制进 `backups/`。
4. 阅读 [`docs/SAFETY.md`](docs/SAFETY.md)、[`docs/PREP.md`](docs/PREP.md)、[`docs/DEPLOY.md`](docs/DEPLOY.md)。

### 1. 确认设备

在电脑上：

```bat
adb devices
adb shell getprop ro.product.device
adb shell getprop ro.build.display.id
adb shell cat /proc/version
```

或把 `device.sh` 推到手机执行，对照 `设备信息报告.txt`。必须同时满足：机型 `PD2238` / `V2238A`，固件与本仓库卡刷包一致。

### 2. （可选）解包固件与提取符号

仅在需要对照内核符号、重建分析环境时执行：

```powershell
powershell -File .\scripts\01_unpack_ota.ps1 .\PD2238_A_16.3.15.0.W10.V000L1-update-full.zip
powershell -File .\scripts\02_boot_kallsyms.ps1 .\work\ota_out\boot.img
```

产物分别进入 `work\ota_out\` 与 `work\boot_out\`。静态对照说明见 [`report.md`](report.md)。

### 3. （可选）本地编译

```powershell
powershell -File .\scripts\04_build.ps1
```

编译成功后，把新的 `preload.so` 复制到仓库根目录，再交给 `root.ps1` 推送。不要混用其它机型、其它固件编出来的 so。

### 4. （可选）QEMU 冒烟

```powershell
powershell -File .\scripts\03_qemu_boot.ps1
```

只在模拟环境验证内核 / 栈帧假设，不能代替真机结论。

### 5. 真机跑入口脚本

- Windows：双击 `一键临时root.bat`，确认已重启后输入 `y`。
- Linux / Termux：运行 `IQOO临时root工具箱优化版.sh`，按菜单 1→2→3→4 执行。

### 6. 判读结果

先看 `logs\log_*.txt` 和 `logs\inject_stdout.txt`，再决定是否重试。

| 现象 | 含义（研究阶段） |
|---|---|
| 日志出现 `WRITE-PROOF POSITIVE` | 当前 write-proof 阶段的预期正向信号 |
| 仅有注入启动、随后 USB 断开并重启 | 常见为内核 panic，**不是**提权成功 |
| 设备上出现 `su` 且 `uid=0` | 仅在完整提权构建且脚本明确进入该阶段时才有意义 |
| 壁纸或 KernelSU 管理器变化 | 旧版 `说明.txt` 中的成功画面，PD2238 当前 write-proof 构建不应以此为准 |

### 7. 失败后的处理

1. 等待手机自己重启并重新授权 USB 调试。
2. 拉取并归档本次 `logs/`，不要覆盖后再说“没留下记录”。
3. 需要干净 `boot_id` 时：**先重启，再跑下一轮**。
4. 若已无法开机，只用预先准备的卡刷包 / 线刷方案救砖，见 `docs/SAFETY.md`。不要临时下载不明镜像。

---

## 文件说明

逐条说明根目录及清单中的每一个路径。

### 仓库根目录

| 路径 | 作用 |
|---|---|
| `.gitattributes` | Git 属性：`* text=auto`，自动识别文本并做 LF 规范化，减少跨平台换行问题。 |
| `.gitignore` | Git 忽略规则。当前模板偏 Android / Gradle（`.gradle/`、`*.apk`、`.idea/`、密钥与日志等），避免把构建缓存、安装包和本地密钥提交进库。 |
| `apk/` | 安装包放置目录。用于存放 KernelSU 管理器或其它辅助 APK；目录可为空，不参与一键脚本的必需检查。 |
| `backups/` | 人工备份目录。建议放入历史 `preload.so`、重要 `log_*.txt`、设备报告副本、以及从手机导出的个人数据索引。目录可为空。 |
| `device.sh` | 设备端 `/system/bin/sh` 采集脚本。无需 Root，输出内核、SoC、指纹、Android / SDK、机型代号、ABI、安全补丁、`su` 是否存在、SELinux 与 uptime。 |
| `docs/` | 研究与操作文档目录，见下一节。 |
| `IQOO临时root工具箱优化版.sh` | Linux / Termux 菜单式工具箱（作者标注：清风南辞【酷安】）。覆盖无线配对、连接、推送 so、息屏注入、提权菜单和日志轮转。 |
| `logs/` | PC 侧运行与崩溃日志目录，见“日志”一章。 |
| `PD2238_A_16.3.15.0.W10.V000L1-update-full.zip` | PD2238 全量卡刷包。既是符号 / 分区解包的输入，也是救砖备用包。体积大，通常不进 Git。 |
| `poc` | 独立 PoC / 探测产物占位文件（无扩展名）。用于与正式 `preload.so` 区分的实验二进制，不作为一键脚本默认推送对象。 |
| `preload.so` | 当前一键流程默认推送的共享库。`root.ps1` 优先使用仓库根目录这一份；若缺失则回退到 `src\aristotle-root\build\pd2238-16.3.15.0.W10\bin\preload.so`。 |
| `README.md` | 本说明文件。 |
| `report.md` | Round-1 静态分析报告：boot 解包、vmlinux / kallsyms、PD2238 偏移对照与结论，对应 `work/boot_out/` 中的验证产物。 |
| `root.ps1` | Windows 主脚本。USB 检测、机型 / 内核门禁、推送 so、息屏注入、拉取双写崩溃日志；PD2238 走 write-proof 判定。 |
| `scripts/` | 固件解包、符号提取、QEMU、编译与探测用 PowerShell 脚本，见下表。 |
| `src/` | 源码目录：利用链移植树与 MTK 5.10 内核源码树。 |
| `tools/` | 本机工具链与平台工具，尽量便携、不污染系统 Python / NDK。 |
| `work/` | 解包、符号、QEMU、本机实验的工作目录，可重建，不应当作唯一备份。 |
| `一键临时root.bat` | Windows 双击入口。设置 UTF-8 代码页并调用 `root.ps1`，失败时 `pause`。 |
| `设备信息报告.txt` | `device.sh` 的一次真实采集结果，便于对照机型、内核、指纹、补丁级别和 SELinux。 |
| `说明.txt` | 早期中文速查（无线调试 + 双击 bat）。部分成功标志和“无变砖风险”表述已过时，以本 README 为准。 |
| `等` | 根目录还可能出现本机文件，例如 `adb.exe`、临时 `inject_out.txt`、编辑器备份、嵌套 `.git` 对象等，不属于稳定发布清单。 |

### `docs/` 文档

| 文件 | 作用 |
|---|---|
| `docs/ASSESSMENT.md` | 可行性与现状评估。 |
| `docs/DEPLOY.md` | `preload.so` 部署手册（检查清单、推送与日志收集约定）。 |
| `docs/MASTER-PLAN.md` | 总计划，串起各 PLAN 文档。 |
| `docs/PD2238-TARGET-CHECKLIST.md` | `target.h` 字段清单与 PD2238 内存布局核对表。 |
| `docs/PLAN-A-FDSET.md` | 方案 A：fdset / pselect 相关栈布局研究。 |
| `docs/PLAN-B-FRAMES.md` | 方案 B：栈帧 / overlay 路线说明。 |
| `docs/PLAN-C-BLUNLOCK.md` | 方案 C：Bootloader 解锁相关讨论。**分区级操作，风险高于临时流程。** |
| `docs/PLAN1-COPYFROMUSER.md` | `copy_from_user` 相关计划笔记。 |
| `docs/PREP.md` | 卡刷包到位前的工具链与脚本准备档案。 |
| `docs/ROADMAP.md` | 阶段路线图。 |
| `docs/SAFETY.md` | 安全手册：风险分级、红线、救砖优先级。操作前必读。 |
| `docs/SIGFRAME-LAYOUT.md` | `rt_sigframe` / 保留区布局笔记。 |
| `docs/TEMPROOT-RESEARCH.md` | 临时 Root 研究综述。 |

### `scripts/` 脚本

| 文件 | 作用 |
|---|---|
| `scripts/01_unpack_ota.ps1` | 用 `payload-dumper-go` 从全量包提取 `boot` / `vendor_boot` / `vbmeta` 等，输出到 `work/ota_out/`。 |
| `scripts/02_boot_kallsyms.ps1` | 用 magiskboot + `vmlinux-to-elf` 解包 `boot.img` 并提取 kallsyms，输出到 `work/boot_out/`。 |
| `scripts/03_qemu_boot.ps1` | 用本地 QEMU + NDK clang 做 PD2238 内核冒烟（可选 `-Gdb` / `-Shell` / `-Verify`）。 |
| `scripts/04_build.ps1` | Windows 下编译 `su_daemon` 与 `preload.so`（不依赖 make）。 |
| `scripts/check_exploit.ps1` | 检查当前构建 / 设备条件是否满足既定研究检查项。 |
| `scripts/measure_delta.ps1` | 测量或核对栈 / 对象间距等 delta 参数。 |
| `scripts/probe_pd2238.ps1` | PD2238 真机或环境探测脚本。 |
| `scripts/run_sigret_trace.ps1` | 运行 sigret 追踪，配合 `work/qemu/` 下的 trace 产物。 |

### `src/` 源码

| 路径 | 作用 |
|---|---|
| `src/aristotle-root/` | 主源码树（可含独立 `.git`）。含 `main.c`、`util.c`、`sigret.c`、`fops.c`、各机型 `targets/`、以及 `targets/pd2238-16.3.15.0.W10/target.h`。 |
| `src/vivo-mtk510-src/` | vivo MTK 5.10 内核源码对照树，用于结构体与配置交叉验证，不是给手机直接刷入的发布内核。 |

### `tools/` 工具

| 路径 | 作用 |
|---|---|
| `tools/bin/` | 解包类可执行文件，例如 `payload-dumper-go.exe`、`magiskboot/`。 |
| `tools/mtkclient/` | MTK 线刷 / 研究用客户端（嵌套仓库）。只在救砖或分区研究时使用，误写分区风险高。 |
| `tools/ndk/` | 便携 Android NDK，供 `04_build.ps1` 与 QEMU 相关编译。 |
| `tools/platform-tools/` | Android platform-tools 目录（`adb` 候选路径之一）。 |
| `tools/python/` | 嵌入式 Python 3.11，隔离于系统 Python；`PREP.md` 要求用它安装第三方库。 |
| `tools/qemu/` | `qemu-system-aarch64` 等本地模拟器文件。 |
| `tools/vmlinux-to-elf/` | 从内核 Image 恢复 ELF / 提取 kallsyms 的工具树。 |

### `work/` 工作目录

| 路径 | 作用 |
|---|---|
| `work/ota_out/` | `01_unpack_ota.ps1` 的分区镜像输出（`boot.img`、`vendor_boot.img`、`scatter.txt` 等）。 |
| `work/boot_out/` | boot 解包与符号产物：`Image`、`kallsyms.txt`、`round1_verify.*`、`target_pd2238_verified.h`、反汇编片段等。 |
| `work/qemu/` | QEMU 串口 / gdb / sweep / sigret 追踪的中间文件与日志。 |
| `work/run_exp.sh` | 工作区内的实验启动脚本，不是给最终用户的一键入口。 |
| `work/dev_run*.log` | 本机开发轮次日志。 |

---

## 日志

日志是本工具箱判断“跑到哪一步”的唯一可靠依据。不要只看 USB 是否断开。

### PC 侧：`logs/`

| 路径 | 作用 |
|---|---|
| `logs/log_*.txt` | 从设备拉回的主日志。文件名中的数字一般为 Unix 时间戳。 |
| `logs/inject_stdout.txt` | 注入命令的本机标准输出快照。 |
| `logs/archive-20260909/` | 按日期归档的旧日志，避免新一轮覆盖历史样本。 |

`root.ps1` 会在注入开始和轮询过程中，把设备上的 `log_*.txt` 拉到该目录。

### 设备侧（双写）

脚本会尝试同时写入：

- `/data/local/tmp/.temp/log_<unix>.txt` — panic 后仍较容易残留
- `/storage/emulated/0/Download/.temp/` 与 `/sdcard/Download/.temp/` — 方便文件管理器查看

不要用 shell glob 去猜文件名；先 `ls` 再按文件名拉取。

### 建议归档方式

```powershell
New-Item -ItemType Directory -Force -Path .\backups\logs-$(Get-Date -Format yyyyMMdd) | Out-Null
Copy-Item .\logs\log_*.txt .\backups\logs-$(Get-Date -Format yyyyMMdd)\ -ErrorAction SilentlyContinue
```

一轮实验结束后，把对应 `preload.so` 的哈希、`boot_id`、`设备信息报告.txt` 和日志放在同一备份子目录，否则事后无法对照。

---

## 备份

| 应该备份什么 | 建议位置 |
|---|---|
| 手机相册、短信、验证器、不可再生应用数据 | 电脑 / 云盘（不要只放在手机内部） |
| 当前可用的卡刷包 | 仓库根目录原文件 + 另一块磁盘副本 |
| 历史可用的 `preload.so` | `backups/` |
| 关键 `log_*.txt` 与 `inject_stdout.txt` | `backups/` 或 `logs/archive-*` |
| `设备信息报告.txt` | `backups/` |
| `work/ota_out/` 里已验证的分区镜像 | 仅在你明确要做救砖演练时复制；日常不要当唯一副本 |

`backups/` 本身不会自动备份。一键脚本也不会在开跑前强制检查该目录是否为空——**备份是操作者的责任**。

解锁 Bootloader、卡刷、线刷之前，把“数据已备份、卡刷包可打开、线刷工具能识别端口”三条全部勾完，再继续。

---

## 常见问题

### 双击 bat 提示找不到 adb

把官方 platform-tools 放到 `tools\platform-tools\`，或把 `adb.exe` 放到仓库根目录 / `E:\adb\`。必须使用 `adb.exe` 全路径；不要在 PowerShell 里写一个叫 `Adb` 的函数再去调用短名 `adb`，会递归到函数自身。

### `adb devices` 没有 `device`

检查数据线是否支持数据、换 USB 口、重新打开 USB 调试、点掉授权弹窗。无线流程则先做配对再 `connect`。设备状态若是 `unauthorized` 或 `offline`，脚本会直接失败。

### 提示不支持的机型

`root.ps1` 目前放行的检测项是 `pd2453` / `V2453A` 与 `PD2238` / `V2238A`。其它型号会被拒绝。即便名称相近，只要 `ro.product.device` 对不上就不要强行改门禁。

### 内核版本被拒绝

Z10 路径上，脚本会拒绝已被修复的高版本内核。PD2238 以本机 `5.10.246-...` 与对应卡刷包为准；内核一经 OTA 变更，旧 `preload.so` 即失效。

### 为什么必须先重启再输入 `y`

流程依赖干净的 `boot_id`。上一轮失败或注入残留后继续跑，结果不可对照。输入 `y` 只表示你确认已经冷启动，脚本不会替你重启到“研究用干净状态”。

### USB 突然断开，是不是成功了

不是。研究阶段里这通常是内核 panic 后的软重启。等设备重新出现在 `adb devices` 后拉日志。

### 找不到 `/data/local/tmp/.temp`

注入没写到该目录、权限不足，或你在看错误的用户存储路径。先列出 `/data/local/tmp/.temp`，不要依赖 Download 一定可写（部分账号对 `mkdir /storage/emulated/0/Download` 会 Permission denied）。

### `preload.so` 和 `poc` 有什么区别

`preload.so` 是一键脚本默认推送的共享库；`poc` 是单独的探测 / 实验产物。不要把来源不明、哈希对不上的 so 推到手机。

### `apk/` 是空的怎么办

空目录不影响 Windows 一键脚本。只有你需要安装管理器或其它辅助应用时才往里面放 APK。

### 卡刷包能不能删

不要删。它同时承担“分析输入”和“救砖备用”。删除前至少在其它磁盘留一份校验过的副本。

### Linux 脚本和 Windows 脚本必须一起用吗

不必。同一台设备不要两条入口并行注入。选定一条链路跑完并归档日志。

### 可以商用或代刷吗

不可以。见下方免责声明。

---

## 免责声明

1. 本仓库按“现状（AS IS）”提供，不提供任何明示或默示担保，包括但不限于适销性、特定用途适用性、不侵权、不会损坏设备或数据。
2. 作者与贡献者不对下列后果负责：变砖、无法开机、保修失效、数据丢失、账号封禁、财产损失、以及因使用或滥用本仓库引起的任何直接或间接损害。
3. 使用者必须仅在**本人合法拥有**的设备上、在当地法律允许的范围内，出于学习与安全研究目的使用本仓库。
4. **禁止商用**，禁止无授权传播收费包装，禁止用于未授权的第三方设备。
5. 本仓库出现的第三方名称（vivo、iQOO、Android、KernelSU、QEMU 等）仅作技术说明，不代表任何官方授权或合作。
6. 继续运行 `一键临时root.bat`、`root.ps1`、`IQOO临时root工具箱优化版.sh` 或向设备推送任何 so / poc，即表示你已阅读并同意本 README 的全部警告与免责条款。

---

## 许可与贡献

未单独声明其它许可证时，默认仅供个人学习研究，不授予商用再分发权。`src/`、`tools/` 下的嵌套仓库沿用各自上游许可证（例如内核源码的 GPL）。

提交改动前：

- 不要把密钥、`*.jks`、完整卡刷包、个人设备序列号大段日志强制推到公开远程。
- 不要删除 `docs/SAFETY.md` 或弱化本 README 的风险章节。
- 针对新固件的改动必须同步更新 `设备信息报告.txt` 采集结果与 `report.md` 对照结论。
)
