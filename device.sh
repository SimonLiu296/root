#!/system/bin/sh
#===========================================================
# Android 系统信息采集脚本 —— 无 Root 也可运行
# 功能：获取内核版本、处理器、系统版本、ABI、安全补丁等
#===========================================================

echo "========================================"
echo "  📱 Android 设备信息报告"
echo "========================================"
echo ""

# 1️⃣ 内核版本
echo "┌─ 1. 内核版本 ──────────────────────────"
KERNEL=$(uname -r 2>/dev/null)
echo "│ 内核版本    : ${KERNEL:-无法获取}"
echo "└─────────────────────────────────────────"
echo ""

# 2️⃣ 处理器代号/架构
echo "┌─ 2. 处理器信息 ────────────────────────"
ARCH=$(uname -m 2>/dev/null)
echo "│ 处理器架构  : ${ARCH:-无法获取}"

# 从系统属性获取 CPU 平台代号（无 root 可读）
# 常见代号如: sm8550(骁龙), mt6983(天玑), exynos2200, kirin9000 等
CPU_PLATFORM=$(getprop ro.board.platform 2>/dev/null)
CHIPNAME=$(getprop ro.chipname 2>/dev/null)
HARDWARE=$(getprop ro.hardware 2>/dev/null)
SOC_MANUF=$(getprop ro.soc.manufacturer 2>/dev/null)
SOC_MODEL=$(getprop ro.soc.model 2>/dev/null)
echo "│ 平台代号    : ${CPU_PLATFORM:-未获取到}"
[ -n "$CHIPNAME" ]  && echo "│ 芯片名称    : $CHIPNAME"
[ -n "$HARDWARE" ]  && echo "│ 硬件平台    : $HARDWARE"
[ -n "$SOC_MANUF" ] && echo "│ SoC制造商   : $SOC_MANUF"
[ -n "$SOC_MODEL" ] && echo "│ SoC型号     : $SOC_MODEL"

# 尝试从 /proc/cpuinfo 获取更多处理器信息
CPU_INFO=$(cat /proc/cpuinfo 2>/dev/null | grep -i "Processor\|Hardware\|model name" | head -3)
if [ -n "$CPU_INFO" ]; then
    echo "$CPU_INFO" | while read line; do
        echo "│ $line"
    done
fi
echo "└─────────────────────────────────────────"
echo ""

# 3️⃣ 系统版本（指纹/版本号）
echo "┌─ 3. 系统版本 ──────────────────────────"
BUILD_FINGERPRINT=$(getprop ro.build.fingerprint 2>/dev/null)
BUILD_DESC=$(getprop ro.build.description 2>/dev/null)
BUILD_ID=$(getprop ro.build.id 2>/dev/null)
echo "│ Build ID   : ${BUILD_ID:-无法获取}"
echo "│ 描述       : ${BUILD_DESC:-无法获取}"
echo "│ 指纹       : ${BUILD_FINGERPRINT:-无法获取}"
echo "└─────────────────────────────────────────"
echo ""

# 4️⃣ Android 版本
echo "┌─ 4. Android 版本 ──────────────────────"
SDK=$(getprop ro.build.version.sdk 2>/dev/null)
RELEASE=$(getprop ro.build.version.release 2>/dev/null)
CODENAME=$(getprop ro.build.version.codename 2>/dev/null)
echo "│ Android 版本 : ${RELEASE:-无法获取}"
echo "│ SDK 版本     : ${SDK:-无法获取}"
echo "│ 开发代号     : ${CODENAME:-无法获取}"
echo "└─────────────────────────────────────────"
echo ""

# 5️⃣ 设备名称
echo "┌─ 5. 设备名称 ──────────────────────────"
MODEL=$(getprop ro.product.model 2>/dev/null)
BRAND=$(getprop ro.product.brand 2>/dev/null)
MANUF=$(getprop ro.product.manufacturer 2>/dev/null)
MARKET_NAME=$(getprop ro.product.marketname 2>/dev/null)
echo "│ 品牌         : ${BRAND:-无法获取}"
echo "│ 制造商       : ${MANUF:-无法获取}"
echo "│ 型号         : ${MODEL:-无法获取}"
if [ -n "$MARKET_NAME" ]; then
    echo "│ 市场名称     : $MARKET_NAME"
fi
echo "└─────────────────────────────────────────"
echo ""

# 6️⃣ 设备代号
echo "┌─ 6. 设备代号 ──────────────────────────"
DEVICE=$(getprop ro.product.device 2>/dev/null)
BOARD=$(getprop ro.product.board 2>/dev/null)
NAME=$(getprop ro.product.name 2>/dev/null)
echo "│ 设备代号     : ${DEVICE:-无法获取}"
echo "│ 主板代号     : ${BOARD:-无法获取}"
echo "│ 产品名称     : ${NAME:-无法获取}"
echo "└─────────────────────────────────────────"
echo ""

# 7️⃣ ABI 支持
echo "┌─ 7. ABI（应用二进制接口）支持 ─────────"
ABI=$(getprop ro.product.cpu.abi 2>/dev/null)
ABI2=$(getprop ro.product.cpu.abi2 2>/dev/null)
ABI_LIST=$(getprop ro.product.cpu.abilist 2>/dev/null)
ABI_LIST32=$(getprop ro.product.cpu.abilist32 2>/dev/null)
ABI_LIST64=$(getprop ro.product.cpu.abilist64 2>/dev/null)
echo "│ 主 ABI       : ${ABI:-无法获取}"
[ -n "$ABI2" ]       && echo "│ 次 ABI       : $ABI2"
[ -n "$ABI_LIST" ]   && echo "│ 全部 ABI     : $ABI_LIST"
[ -n "$ABI_LIST32" ] && echo "│ 32位 ABI     : $ABI_LIST32"
[ -n "$ABI_LIST64" ] && echo "│ 64位 ABI     : $ABI_LIST64"
echo "└─────────────────────────────────────────"
echo ""

# 8️⃣ 安全补丁日期
echo "┌─ 8. 安全补丁 ──────────────────────────"
PATCH=$(getprop ro.build.version.security_patch 2>/dev/null)
VNDK_PATCH=$(getprop ro.vendor.build.security_patch 2>/dev/null)
echo "│ Android 安全补丁 : ${PATCH:-无法获取}"
[ -n "$VNDK_PATCH" ] && echo "│ Vendor 安全补丁 : $VNDK_PATCH"
echo "└─────────────────────────────────────────"
echo ""

# 9️⃣ 是否支持 su 命令
echo "┌─ 9. su 命令检测 ───────────────────────"
SU_CHECK="未找到"
if command -v su >/dev/null 2>&1; then
    SU_CHECK="✅ 支持（$(command -v su)）"
elif [ -f "/system/bin/su" ] || [ -f "/system/xbin/su" ] || [ -f "/sbin/su" ] || [ -f "/su/bin/su" ]; then
    SU_CHECK="⚠️  文件存在但不在 PATH 中"
else
    SU_CHECK="❌ 不支持（未找到 su 命令）"
fi
echo "│ $SU_CHECK"
echo "└─────────────────────────────────────────"
echo ""

# 🔟 额外：SELinux 状态
echo "┌─ 10. 额外信息 ─────────────────────────"
SESTATUS=$(getenforce 2>/dev/null)
echo "│ SELinux     : ${SESTATUS:-无法获取}"
UPTIME=$(uptime 2>/dev/null | sed 's/^[[:space:]]*//')
echo "│ 运行时间    : ${UPTIME:-无法获取}"
echo "└─────────────────────────────────────────"
echo ""

echo "========================================"
echo "  ✅ 采集完成"
echo "========================================"
