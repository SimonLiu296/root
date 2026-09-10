# PD2238 操作安全手册 (变砖风险评估 + 救砖方案)

日期: 2026-08-23 | 设备: iQOO Neo7 SE (V2238A/PD2238) | 内核 5.10.246-android12-9-dirty

## 〇、核心原则

1. **当前阶段 (临时 root) 完全不写分区** — 只做内核内存操作
2. **任何分区写入操作前, 必须先验证救砖路径可用**
3. **数据备份 > 一切** — 解锁/降级/救砖都会清数据
4. 操作顺序永远: 备份 → 验证救砖 → 操作 → 验证结果

## 一、风险等级表

| 操作 | 风险 | 变砖可能 | 数据影响 | 说明 |
|---|---|---|---|---|
| 编译 preload.so | 🟢 无 | 无 | 无 | 纯本地 |
| QEMU 运行 | 🟢 无 | 无 | 无 | 模拟环境 |
| 真机跑 preload.so (临时root) | 🟡 低 | **几乎不可能** | 无 | 最坏 = 内核 panic 重启, 已实证无损伤 |
| 真机跑 PoC/探测 | 🟡 低 | 几乎不可能 | 无 | panic 重启无害 |
| 写 seccfg (解锁) | 🟠 中 | 低~中 | **解锁首次会清数据** | seccfg 写错可 mtkclient 修复 |
| 刷 boot/vendor_boot (SakiSU) | 🟠 中 | 中 | 无 | 镜像错误=不开机, 可线刷救 |
| 刷 lk/preloader | 🔴 高 | **高** | 无 | **绝对避免** — 无签名镜像会直接死 |
| 拆字库 | 🔴 极高 | 极高 | 无 | 硬件级, 需专业师傅 |

## 二、为什么"临时 root"阶段几乎不会变砖

```
preload.so 做的事:
  内存注入 → KASLR 绕过 → 内存提权 → 内存内 su daemon
  └── 全程不碰 /dev/block/*, 不写任何分区
最坏结果: 内核 panic → 自动重启 → 系统恢复原状
          (已实测: PoC panic 后重启, 数据无损, BL 状态不变)
```

**只要不执行"写分区"命令, 变砖概率 ≈ 0。**

## 三、救砖方案 (按优先级)

### 方案 1: 卡刷包本地修复 (最简单, 适用系统级损坏)
```
关机 → 音量上+电源进 recovery (vivo 为 Funtouch/OriginOS recovery)
→ 本地升级/安装系统 → 选择全量卡刷包 PD2238_A_16.3.15.0.W10.V000L1-update-full.zip
→ 等待完成 → 重启
适用: 系统文件损坏、无法开机、bootloop
注意: 会清数据 (或保留数据选项视 recovery 版本)
```

### 方案 2: mtkclient 线刷 (适用分区损坏, 含 boot/vendor_boot/seccfg)
```
# 已有物料: work/ota_out/ 全套镜像 + mtkclient (需安装)
python mtk.py w boot work\ota_out\boot.img
python mtk.py w vendor_boot work\ota_out\vendor_boot.img
python mtk.py w vbmeta work\ota_out\vbmeta.img
python mtk.py da seccfg lock   # 回锁 (若解锁后想恢复)
先决: MT6895 需要 V6 loader + DA 授权绕过 (与解锁同一套技术)
```

### 方案 3: SP Flash Tool 线刷 (MTK 官方工具, 最可靠)
```
物料: 东海论坛/HalabTech 的 V2238A 全量线刷包 + scatter.txt
流程: 装驱动 → SP Flash Tool 加载 scatter → 全选 → Download
适用: 深度损坏, 含 preloader/lk 级别
```

### 方案 4: 售后 (最后手段)
```
vivo 售后刷机服务 (收费), 或保修期内免费
适用: 一切软件/固件问题
```

## 四、红线清单 (绝对禁止)

1. ❌ **禁止写 preloader / lk 分区** — 无签名镜像 = 硬砖, 只能拆字库
2. ❌ **禁止在未备份时解锁** — 解锁必清数据
3. ❌ **禁止用不匹配版本的镜像刷机** — 内核/分区版本必须一致
4. ❌ **禁止断电刷机** — 刷机中途断电 = 变砖 (先充满电)
5. ❌ **禁止在未验证救砖路径时做分区操作**
6. ❌ **禁止把 preload.so 用于他人设备** — 偏移是 PD2238 专用的, 别的机型会 panic

## 五、当前物料清单 (救砖储备)

```
work/ota_out/
  boot.img          96MB   ← 原始官方镜像 (救砖关键)
  vendor_boot.img   64MB   ← 原始官方镜像
  lk.img            2.9MB  ← 只读参考, 不刷
  preloader_*.img   0.5MB  ← 只读参考, 不刷
  vbmeta*.img       小     ← 官方 vbmeta
  recovery.img      192MB  ← 官方 recovery
  scatter.txt              ← MTK 分区表 (SPFT 用)
  dtbo.img / 固件镜像      ← 其他分区
PD2238_A_16.3.15.0.W10.V000L1-update-full.zip (8.9GB, 卡刷包)
  ↑ 卡刷包 + 全部分区镜像 = 完整救砖弹药库
```

## 六、真机测试规程 (当决定跑 preload.so 时)

```
1. 备份全部数据 (解 BL 前的必修课)
2. 确认卡刷包文件完好 (SHA256 校验)
3. 充满电 (>=80%)
4. 用 adb 连接, 确认 USB 调试
5. 推送: adb push preload.so /data/local/tmp/
6. 冷启动手机 (pristine boot_id 要求)
7. 执行: adb shell LD_PRELOAD=/data/local/tmp/preload.so /system/bin/toybox id
8. 观察:
   - 看到 slide-kaslr-ok → 第一阶段成功
   - 手机重启 → panic, 无害, 记录日志后重试
9. 失败处理: 重启后系统恢复正常 = 正常状态 (无任何损伤)
```

## 七、解锁后的安全路径 (未来的事情)

```
解锁成功 → 立即备份 seccfg 原值 → SakiSU 修补镜像
→ 先刷 init_boot (小风险) → 验证 → 再刷 vendor_boot → 验证
→ 全程保留卡刷包救砖
```

**总结: 当前临时 root 阶段安全可控 (无分区写入); 真正的风险在解锁/刷机阶段, 届时有完整救砖弹药库 (卡刷包+全部分区镜像) 兜底。**
