# PD2238 preload.so 部署手册 (安全版)

日期: 2026-08-23 | 产物: build/pd2238-16.3.15.0.W10/bin/preload.so (SHA256 见下)
SHA256: 121380C4D29D7E16F8BBA46E5B0492061453F4210AB720C1652591CA1DED7093

## ⚠️ 先读: 当前状态与预期

**这不是一键 root。** 这是移植研究的第一阶段产物:

| 组件 | 状态 |
|---|---|
| 符号偏移 (21个) | ✅ 已实测验证 (QEMU) |
| 结构体偏移 | ✅ 继承同芯片同内核分支的 gdb 验证值 |
| fdset 布局参数 (WORD_SHIFT/δ) | ⏳ **QEMU 扫描进行中** (后台运行, 结果待查 sweep_bg.log) |
| 完整提权 | ❓ 未实证 — 首次真机测试大概率 panic 重启若干次 |

**预期管理**: 首次部署的正确预期是"收集日志"而非"拿到 root"。
每次失败 = 内核 panic = 自动重启 = 无任何持久损伤。

## 一、为什么这不会变砖 (原理)

preload.so 的全部操作在**内存**里:
```
LD_PRELOAD 注入 → futex 竞态(内存) → KASLR 泄露(读 boot_id 文件)
→ 内核内存写 → 落地 su 到 tmpfs(/apex/... 内存盘)
```
- ❌ 不打开 /dev/block/* 任何节点
- ❌ 不调用任何 flash/分区写入接口
- ✅ 最坏情况: 内核 panic → 硬件看门狗重启 → 一切如初
- ✅ 已实测先例: PoC 触发 panic 后重启, 数据/BL状态/系统完好

## 二、部署前检查清单

```
[ ] 数据已完整备份 (虽然本操作不清数据, 但以防万一)
[ ] 电量 ≥ 80% (panic 重启本身不耗电, 但避免意外)
[ ] USB 调试开启, adb devices 能看到设备
[ ] 卡刷包 PD2238_A_16.3.15.0.W10.V000L1-update-full.zip 在电脑上备用
[ ] 冻结系统更新: adb shell pm uninstall --user 0 com.bbk.updater
[ ] preload.so SHA256 校验 = 上方值
```

## 三、部署步骤

### 步骤 1: 推送 (无风险)
```powershell
adb push preload.so /data/local/tmp/preload.so
adb shell chmod 644 /data/local/tmp/preload.so
```

### 步骤 2: 冷启动 (关键!)
```
手动重启手机到桌面 (pristine boot_id 是成功前提)
```

### 步骤 3: 执行提权
```powershell
# 方式 A: 直接注入 toybox (最简单)
adb shell LD_PRELOAD=/data/local/tmp/preload.so /system/bin/toybox id

# 方式 B: 注入 app_process (若 A 被 SELinux 拦)
adb shell LD_PRELOAD=/data/local/tmp/preload.so app_process / id
```

### 步骤 4: 判读结果
```
✓ 看到 "slide-kaslr-ok" 或 "uid=0"     → 阶段成功, 立即抓日志
✓ 看到 "direct-map base="              → slide 过了, 后续阶段问题
✗ 手机自动重启                          → panic, 正常现象, 记录后可重试
✗ 命令卡住 >60 秒                       → Ctrl-C, 手机可能软重启
```

### 步骤 5: 抓日志 (无论成败都做)
```powershell
adb shell dmesg > dmesg_after.log    # 若权限允许
adb logcat -b all -d > logcat_after.log
```
把日志带回分析 — 每次失败的日志都是调参依据。

## 四、失败处理矩阵

| 现象 | 含义 | 处置 |
|---|---|---|
| panic 重启 | 利用链某阶段失败 | 无害; 收集日志重试 (≤3 次/天) |
| 无输出直接返回 | LD_PRELOAD 被拒 (SELinux) | 试方式 B; 或换注入目标 |
| 卡死不动 | 内核 hang (罕见) | 长按电源 10s 强制重启 |
| 反复 panic 同一地址 | 该阶段偏移错误 | 停止重试, 带日志回来分析 |

**红线**: 如果手机出现无法开机 → 进入救砖流程 (见五), 不要慌,
你的数据在未解锁前不会被擦除。

## 五、救砖方案 (四级递进)

### L1: 强制重启 (99% 情况够用)
长按电源 10 秒。适用于: panic 循环、卡死。

### L2: recovery 卡刷 (系统损坏)
```
关机 → 音量上+电源 → recovery → 安装升级包
→ 选 PD2238_A_16.3.15.0.W10.V000L1-update-full.zip
注意: 会清数据; BL 锁不影响此操作
```

### L3: mtkclient / SP Flash Tool 线刷 (分区级损坏)
```
物料: work\ota_out\ 全套镜像 + scatter.txt + 东海论坛 V2238A 线刷包
工具: mtkclient (开源) 或 SP Flash Tool
前置: MT6895 V6 协议, preloader 模式联机 (与解锁同一套技术)
可修: boot/vendor_boot/vbmeta/system 等所有非 bootrom 分区
```

### L4: 售后
vivo 官方刷机 (保内免费)。最终兜底。

## 六、绝对禁止事项

```
❌ 手动 dd 写任何 /dev/block/by-name/* 分区 (除非你完全明白后果)
❌ 刷 lk.img / preloader_*.img (无签名镜像 = 硬砖, 只能拆字库)
❌ 使用来源不明的其他机型 preload.so (偏移不匹配 = 必然 panic)
❌ 把 preload.so 传播给其他机型用户
❌ 连续 panic 超过 5 次仍强行重试 (每次对闪存都有微小磨损)
```

## 七、成功之后 (未来流程预览)

```
临时 root 成功瞬间:
  1. [高优先] 立即用 root 权限做全量备份 (tar /data, dd boot 等)
  2. 尝试 seccfg 解锁写入 (需 mtkclient 格式解析配合)
  3. 重启 → BL unlocked → fastboot 可刷
  4. SakiSU 修补 init_boot/vendor_boot (选 vivo KMI + 去 vr.ko)
  5. fastbootd 刷入 → KernelSU LKM 永久 root
每一步都有独立回退方案 (刷回 work\ota_out\ 对应官方镜像)
```

## 八、法律与道德

仅限本人设备安全研究。不得用于他人设备、规避企业管控、
或任何违法用途。漏洞利用代码的传播可能违反当地法律。
