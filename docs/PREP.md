# PREP — 卡刷包到位前的准备工作档案 (2026-08-23)

## 一、工具链状态 — 全部就绪 ✓

| 工具 | 版本/来源 | 位置 | 验证 |
|---|---|---|---|
| payload-dumper-go | 2.0.2 官方 | tools\bin\payload-dumper-go.exe | 已下载解压 |
| magiskboot | e159716 win-x64 standalone (PinNaCode 构建) | tools\bin\magiskboot\magiskboot.exe | 运行测试通过 |
| Python | 3.11.9 便携嵌入版 (不污染系统) | tools\python\python.exe | pip 可用 |
| vmlinux-to-elf | **1.2.3** (新版依赖 minilzo 需 C 编译器已绕开) | tools\vmlinux-to-elf | kallsyms_finder 冒烟测试通过 |

⚠️ Python 为嵌入版隔离模式: 第三方库路径已写入 python311._pth (含 ..\vmlinux-to-elf),
新增库用 `tools\python\python.exe -m pip install <包>` 即可, 不要设 PYTHONPATH (会被忽略)。

## 二、一键脚本 (卡刷包下载完成后依次执行)

```
powershell -File scripts\01_unpack_ota.ps1 <OTA.zip路径>     → work\ota_out\*.img
powershell -File scripts\02_boot_kallsyms.ps1 work\ota_out\boot.img → work\boot_out\kallsyms.txt + symbols_found.txt
```
脚本均通过 PowerShell 解析器语法校验; 中文编码问题已修 (UTF-8 BOM)。
02 号脚本自动: magiskboot 解包 → 识别 gzip/lz4/zstd/裸 Image → kallsyms 提取 → 检索 21 个 GhostLock 必需符号并输出 MISSING 清单。

## 三、分析产出

1. **docs/PD2238-TARGET-CHECKLIST.md** — target.h 全字段清单:
   - 39 位 VA 内存布局常量已按本地源码公式算完 (与 Pixel 模板差异巨大, 勿照抄)
   - 符号偏移等 boot.img; 结构体偏移待源码推导
   - 新发现的利用阻力: INIT_ON_ALLOC=y / SLUB_MIRROR=y / KASAN_HW_TAGS(判定为无效残留)
   - ⚠️ 本机 NF_LOG 全关 → 官方 slide 锚点(nfnl_logger)可能不存在, 需换锚点
2. GPL 源码 = 5.10.177 vs 设备 5.10.246, 差 69 sublevel, 核心结构体大概率稳定但需交叉验证
3. 官方 exploit 构建体系: make PROJECT=<target> → preload.so (内嵌 su_daemon+壁纸), 需 Android NDK r29 (Linux 工具链路径, Windows 需下 NDK Windows 版 ~600MB, 待偏移就绪后再装)

## 四、卡刷包到位后的执行序列

1. scripts\01 解包 → 确认 preloader 是否在包内
2. scripts\02 跑 boot.img → symbols_found.txt 里 MISSING 数量决定成败:
   - 0 MISSING → 符号关通过, 进入结构体推导阶段
   - ashmem/configfs 符号缺失 → fops 劫持目标没了, 利用链需大改
   - kallsyms 提取本身失败 → vivo 改了符号表格式 (少见), 手动逆向
3. 同时可并行: 把 vendor_boot.img 交给 SakiSU 验证 vr.ko 识别 (解锁成功后的 B 计划物料)

## 五、风险提示存档

- UBSAN_TRAP + PANIC_ON_OOPS 致命组合未变 — 任何实机测试都可能 panic 重启 (无害但烦)
- 免解锁提权即使成功也只是临时 root + 被 vr.ko 盯防
- 本目录所有产物仅供安全研究, 请仅用于本人设备
