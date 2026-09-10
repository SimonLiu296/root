# ============================================================
#  iQOO Neo7 SE (PD2238) 临时 root 一键脚本 (PC 版, USB 有线)
#  流程: USB 检测 -> 门禁 -> 推送 so -> 息屏注入
#        PD2238 当前: write-proof (拉日志看 POSITIVE, 不检查 su)
#        完整提权后: 等待 su -> ksud late-load
#  崩溃日志: /data/local/tmp/.temp/ 与 Download/.temp/ (双写)
#  用法: 双击 一键临时root.bat (需 USB 连接手机并开启 USB 调试)
# ============================================================

$ErrorActionPreference = "Continue"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---------- 颜色输出 ----------
function Info($m)  { Write-Host "[*] $m" -ForegroundColor Cyan }
function Ok($m)    { Write-Host "[+] $m" -ForegroundColor Green }
function Warn($m)  { Write-Host "[!] $m" -ForegroundColor Yellow }
function Err($m)   { Write-Host "[x] $m" -ForegroundColor Red }

# ---------- adb 定位 (必须用 adb.exe 完整路径, 禁止用短名 "adb") ----------
# 原因: 函数若叫 Adb, PowerShell 大小写不敏感, `& "adb"` 会递归调用函数本身而不是 adb.exe
$adb = $null
$adbCandidates = @(
    (Join-Path $scriptDir "adb.exe"),
    "E:\adb\adb.exe",
    (Join-Path $scriptDir "tools\platform-tools\adb.exe")
)
foreach ($c in $adbCandidates) {
    if ($c -and (Test-Path -LiteralPath $c)) {
        $adb = (Resolve-Path -LiteralPath $c).Path
        break
    }
}
if (-not $adb) {
    $cmd = Get-Command adb.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $adb = $cmd.Source }
}
if (-not $adb) {
    Err "未找到 adb.exe"
    Err "请安装 platform-tools, 或把 adb.exe 放到 E:\adb\ 或本脚本目录"
    Read-Host "按回车退出"
    exit 1
}

function Invoke-Adb {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Arguments)
    $old = $ErrorActionPreference
    $ErrorActionPreference = "SilentlyContinue"
    try {
        $out = & $script:adb @Arguments 2>$null
        if ($null -eq $out) { return "" }
        return ($out | Out-String)
    } finally {
        $ErrorActionPreference = $old
    }
}

function Get-OnlineAdbDevices {
    (Invoke-Adb devices) -split "`r?`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -match '\s+device$' -and $_ -notmatch '^List of devices' }
}

# 预热 adb server (静默启动 daemon)
& $adb start-server 2>$null | Out-Null
Start-Sleep -Milliseconds 500

# ---------- 1. 检测 USB 设备 (有线) ----------
Write-Host ""
Write-Host "==============================================" -ForegroundColor White
Write-Host "   vivo/iQOO 临时root 工具箱" -ForegroundColor Green
Write-Host "   (USB 有线, 适配 iQOO Neo7 SE PD2238 / 16.3.15.0.W10)" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor White
Write-Host ""
Info "使用 adb: $adb"
Warn "请确认: 1) USB 数据线连接电脑 2) 手机开启 [开发者选项 -> USB 调试] 3) 弹窗允许调试"
Write-Host ""

$found = $false
$devices = @()
for ($t = 0; $t -lt 6; $t++) {
    $devices = @(Get-OnlineAdbDevices)
    if ($devices.Count -gt 0) {
        $found = $true
        break
    }
    if ($t -eq 0) { Info "等待 USB 设备识别 (最多 30 秒)..." }
    Start-Sleep -Seconds 5
}
if (-not $found) {
    Err "未检测到 USB 设备 (状态为 device)"
    Err "请检查: 数据线是否支持数据传输 / USB 调试是否开启 / 手机弹窗是否允许"
    Write-Host "--- adb devices ---" -ForegroundColor Yellow
    Write-Host (Invoke-Adb devices)
    Read-Host "按回车退出"
    exit 1
}
Ok "USB 设备已连接"
$devices | ForEach-Object { Info $_ }
Invoke-Adb shell "echo ok" | Out-Null

# ---------- 2. 机型/内核门禁 ----------
Write-Host ""
$device = (Invoke-Adb shell getprop ro.product.device).Trim()
$model  = (Invoke-Adb shell getprop ro.product.model).Trim()
$kver   = (Invoke-Adb shell cat /proc/version).Trim()
$build  = (Invoke-Adb shell getprop ro.build.display.id).Trim()
Info "设备: $device / $model"
Info "固件: $build"
Info "内核: $kver"

$allowed = @(
    @{ Device = "pd2453"; Model = "V2453A"; Name = "iQOO Z10 Turbo Pro" },
    @{ Device = "PD2238"; Model = "V2238A"; Name = "iQOO Neo7 SE" }
)
$hit = $allowed | Where-Object {
    $_.Device -ieq $device -or $_.Model -ieq $model
} | Select-Object -First 1
if (-not $hit) {
    Err "不支持的机型, 当前: $device / $model"
    Err "支持: pd2453 (Z10 Turbo Pro) / PD2238 (Neo7 SE)"
    Read-Host "按回车退出"
    exit 1
}
Ok "机型门禁通过: $($hit.Name) ($device / $model)"

if ($kver -match "(\d+)\.(\d+)\.(\d+)") {
    $maj = [int]$Matches[1]; $min = [int]$Matches[2]; $pat = [int]$Matches[3]
    $isZ10 = $hit.Device -ieq "pd2453"
    if ($isZ10 -and ($maj -gt 6 -or ($maj -eq 6 -and ($min -gt 6 -or ($min -eq 6 -and $pat -ge 140))))) {
        Err "内核 $maj.$min.$pat >= 6.6.140, CVE-2026-43499 已修复, 无法使用"
        Read-Host "按回车退出"
        exit 1
    }
    Ok "内核 $maj.$min.$pat, 可以继续"
}
Warn "重要: 本工具依赖 pristine boot_id, 若之前尝试过失败, 请先重启手机再运行!"
$go = Read-Host "确认已重启手机? 输入 y 继续 (其他退出)"
if ($go -ne "y") { exit 0 }

function Pull-CrashLogs {
    param(
        [string]$Why,
        [switch]$Quiet
    )
    $logDir = Join-Path $scriptDir "logs"
    New-Item -ItemType Directory -Force -Path $logDir | Out-Null
    if (-not $Quiet) { Info "拉取崩溃日志 ($Why) -> $logDir" }
    $dirs = @(
        "/data/local/tmp/.temp",
        "/storage/emulated/0/Download/.temp",
        "/sdcard/Download/.temp"
    )
    $pulled = 0
    $newest = $null
    foreach ($d in $dirs) {
        $listing = (Invoke-Adb shell "ls -1 $d 2>/dev/null").Trim()
        if (-not $listing) { continue }
        foreach ($line in ($listing -split "`r?`n")) {
            $bn = $line.Trim()
            if (-not $bn -or $bn -notmatch '^log_.*\.txt$') { continue }
            $p = "$d/$bn"
            $dest = Join-Path $logDir $bn
            & $script:adb pull $p $dest 2>$null | Out-Null
            if (-not $Quiet) { Info "  $p" }
            $pulled++
            if (-not $newest -or $bn -gt $newest) { $newest = $bn }
        }
    }
    if ($pulled -eq 0) {
        if (-not $Quiet) {
            Warn "设备上未找到 log_*.txt (先看 /data/local/tmp/.temp, 不要用 glob)"
            foreach ($d in $dirs) {
                Write-Host (Invoke-Adb shell "ls -la $d 2>/dev/null")
            }
        }
    } elseif ($newest -and -not $Quiet) {
        Info "最新日志: $newest"
    }
    return $pulled
}

function Read-NewestLocalLog {
    $logDir = Join-Path $scriptDir "logs"
    $f = Get-ChildItem -Path $logDir -Filter "log_*.txt" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 1
    if (-not $f) { return "" }
    return (Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue)
}

$writeProof = ($hit.Device -ieq "PD2238")
if ($writeProof) {
    Warn "PD2238 当前是 write-proof 构建: 不会出现 su / 不会换 fops。"
    Warn "成功标志: 日志里 SCRATCH-WRITE-PROOF POSITIVE 或 BOOTID-WRITE-PROOF POSITIVE。"
    Warn "注入后内核 panic 软重启属于预期, 不是提权成功。"
}

# ---------- 3. 清理残留 + 推送 so ----------
Write-Host ""
Info "清理残留 (旧 preload.so / su; 保留 Download 日志) ..."
Invoke-Adb shell "rm -f /data/local/tmp/preload.so /data/local/tmp/su_daemon.log /data/local/tmp/tornado-trace.log /data/local/tmp/temp_su.sock /data/local/tmp/su" | Out-Null
Ok "残留已清理"
Info "推送 preload.so ..."
$so = Join-Path $scriptDir "preload.so"
$built = Join-Path $scriptDir "src\aristotle-root\build\pd2238-16.3.15.0.W10\bin\preload.so"
if (-not (Test-Path $so) -and (Test-Path $built)) { $so = $built }
if (-not (Test-Path $so)) { Err "缺少 preload.so (请先编译或放到本脚本目录)"; Read-Host "按回车退出"; exit 1 }
Invoke-Adb push $so /data/local/tmp/preload.so | Out-Null
Invoke-Adb shell "chmod 755 /data/local/tmp/preload.so" | Out-Null
Invoke-Adb shell "mkdir -p /storage/emulated/0/Download/.temp /sdcard/Download/.temp /data/local/tmp/.temp" | Out-Null
$sz = (Invoke-Adb shell "wc -c < /data/local/tmp/preload.so").Trim()
Ok "preload.so 已就位 ($sz 字节) 源=$so"
Info "崩溃日志双写: /data/local/tmp/.temp/ 与 Download/.temp/"

# ---------- 4. 息屏注入 (检测输出后自动息屏, 高成功率流程) ----------
Write-Host ""
Info "注入: LD_PRELOAD /system/bin/id (实时检测输出)"
Warn "流程提示: 注入时屏幕会自动熄灭 -> 等 5 秒手动打开 -> 可能再次熄灭 -> 再等 5 秒打开"
Warn "运行完成后: write-proof 可能 panic 软重启; 完整提权才会留下 su"
Write-Host ""

$outFile = Join-Path $env:TEMP "inject_out.txt"
Remove-Item $outFile -Force -ErrorAction SilentlyContinue
$screenOff = $false
$proc = Start-Process $adb -ArgumentList @("shell", "LD_PRELOAD=/data/local/tmp/preload.so /system/bin/id") -NoNewWindow -RedirectStandardOutput $outFile -PassThru

# 轮询输出: 匹配关键词后自动息屏 (仅一次)
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 500
    if (Test-Path $outFile) {
        $content = Get-Content $outFile -Raw -ErrorAction SilentlyContinue
        if ($content) {
            # 实时显示新增行 (简单方式: 显示最后 3 行)
            $lines = $content -split "`r?`n" | Where-Object { $_ -ne "" }
            if ($lines.Count -gt 0) {
                $show = $lines | Select-Object -Last 1
                if ($show -ne $lastShown) { Write-Host "  $show" -ForegroundColor DarkGray; $lastShown = $show }
            }
            if (-not $screenOff -and $content -match "preload starting pid=|slide child context|slide-kaslr-ok") {
                Write-Host ""
                Ok "检测到注入输出, 自动息屏"
                Invoke-Adb shell input keyevent 26 | Out-Null
                $screenOff = $true
                Warn "请等 5 秒后手动打开屏幕; 若再次熄灭再等 5 秒打开"
                Start-Sleep -Seconds 5
            }
        }
    }
    if ($proc.HasExited) { break }
}
if (-not $screenOff) {
    Warn "stdout 没有注入输出 (正常: 日志写在手机 /data/local/tmp/.temp, 不走 stdout)"
}
Info "注入仍在跑 (KernelSnitch 约 30-50 秒). 先拉日志, 不等 200 秒软重启."
if ($writeProof) {
    [void](Pull-CrashLogs "inject-start")
}

# ---------- 4.5 write-proof: 按日志结束, 软重启只是加分 ----------
$rebooted = $false
$hitPos = $false
$hitHold = $false
$hitDone = $false
$waitSlots = if ($writeProof) { 24 } else { 40 }
for ($i = 0; $i -lt $waitSlots; $i++) {
    Start-Sleep -Seconds 5
    $devNow = @(Get-OnlineAdbDevices)
    if ($devNow.Count -eq 0) {
        Warn "检测到设备断开 (内核 panic / 软重启中) ..."
        for ($j = 0; $j -lt 40; $j++) {
            Start-Sleep -Seconds 5
            $dev2 = @(Get-OnlineAdbDevices)
            if ($dev2.Count -gt 0) { $rebooted = $true; break }
        }
        break
    }
    if ($writeProof) {
        [void](Pull-CrashLogs "poll $($i+1)/$waitSlots" -Quiet)
        $t = Read-NewestLocalLog
        if ($t -match "WRITE-PROOF POSITIVE") { $hitPos = $true; break }
        if ($t -match "sigret hold done") { $hitHold = $true }
        if ($t -match "sigret route done|pipe-physrw-summary") {
            $hitDone = $true
            Info "日志显示本轮已结束, 再等 8 秒看会不会 panic"
            Start-Sleep -Seconds 8
            break
        }
    } else {
        $suChk = (Invoke-Adb shell "ls /data/local/tmp/su 2>/dev/null").Trim()
        if ($suChk -match "su") { $rebooted = $true; break }
    }
}
if ($rebooted) {
    Ok "设备已重新上线"
    Warn "若刚软重启: 请重新确认 USB 授权弹窗 (允许调试)"
} elseif ($writeProof -and -not $hitPos -and -not $hitDone) {
    Warn "未检测到软重启 (write-proof 未落地时这是正常的, 不是脚本没跑)"
}

if ($writeProof) {
    Write-Host ""
    Info "write-proof: 不检查 su, 只拉日志看 store 是否落地"
    [void](Pull-CrashLogs "write-proof")
    $logDir = Join-Path $scriptDir "logs"
    $hitPos = $false
    $hitHold = $false
    $newestName = $null
    Get-ChildItem -Path $logDir -Filter "log_*.txt" -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        Select-Object -First 6 |
        ForEach-Object {
            if (-not $newestName) { $newestName = $_.Name }
            Info ("本地 " + $_.Name)
            $t = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
            if ($t -match "WRITE-PROOF POSITIVE") { $hitPos = $true }
            if ($t -match "sigret hold done") { $hitHold = $true }
        }
    if ($newestName) {
        Ok "本机最新: logs\$newestName"
    }
    if ($hitPos) {
        Ok "WRITE-PROOF POSITIVE — 链上 store 已执行。下一步才是真 KASLR + fops, 不要本轮开 su。"
    } elseif ($hitHold) {
        Warn "sigret hold 已回来但 store 未 POSITIVE。把 logs\\ 最新文件发回来即可。"
    } else {
        Warn "日志里还没有 POSITIVE / hold done。优先看 /data/local/tmp/.temp/"
    }
    Write-Host ""
    Read-Host "按回车退出"
    if ($hitPos) { exit 0 } else { exit 1 }
}

# ---------- 5. 等待 su (120秒) ----------
$found = $false
for ($i = 0; $i -lt 24; $i++) {
    Start-Sleep -Seconds 5
    $su = (Invoke-Adb shell "ls -la /data/local/tmp/su 2>/dev/null").Trim()
    if ($su -match "su") {
        $found = $true
        break
    }
    Write-Host "   等待提权 [$($i+1)/24] ..." -ForegroundColor DarkGray
}
if (-not $found) {
    Err "su 未出现, 提权可能失败"
    Write-Host "--- 诊断 ---"
    Write-Host (Invoke-Adb shell "ls -la /data/local/tmp/preload.so /data/local/tmp/su_daemon.log 2>&1")
    Write-Host (Invoke-Adb shell "tail -c 2000 /data/local/tmp/su_daemon.log 2>/dev/null")
    Pull-CrashLogs "su 未出现"
    Read-Host "按回车退出"
    exit 1
}
Ok "su 已出现!"

$id = (Invoke-Adb shell "/data/local/tmp/su -c id").Trim()
Write-Host "root 验证: $id"
if ($id -notmatch "uid=0") {
    Err "未获得 root 权限"
    Read-Host "按回车退出"
    exit 1
}
Ok "临时 root 已获得 (uid=0)!"
Warn "手机壁纸应已变为 '提权成功' 画面 (成功信号)"

# ---------- 6. ksud late-load 激活 KernelSU ----------
Write-Host ""
Info "推送 ksud 并激活 KernelSU ..."
$ksud = Join-Path $scriptDir "ksud"
if (-not (Test-Path $ksud)) { Warn "缺少 ksud 文件, 跳过 KSU 激活 (仅临时 root)"; exit 0 }
Invoke-Adb push $ksud /data/local/tmp/ksud | Out-Null
Invoke-Adb shell "chmod 755 /data/local/tmp/ksud" | Out-Null
$ksudSz = (Invoke-Adb shell "wc -c < /data/local/tmp/ksud").Trim()
Ok "ksud 已就位 ($ksudSz 字节)"

$pkg = Read-Host "请输入 KernelSU 管理器包名 [默认 me.weishu.kernelsu]"
if (-not $pkg) { $pkg = "me.weishu.kernelsu" }
Info "执行 ksud late-load (需等待数十秒) ..."
$late = Invoke-Adb shell "/data/local/tmp/su -c `"/data/local/tmp/ksud late-load --allow-shell --package-name $pkg`""
Write-Host $late
Start-Sleep -Seconds 10

# ---------- 7. 最终验证 ----------
Write-Host ""
$final = (Invoke-Adb shell "/data/local/tmp/su -c id").Trim()
Info "最终 root 验证: $final"
if ($final -match "uid=0") {
    Ok "=== 完成: 临时 root + KernelSU 已激活 ==="
    Ok "打开 KernelSU 管理器授权即可使用; 重启后 root 消失需重跑"
} else {
    Warn "root 验证失败, 但 su 可能存在, 请手动检查"
}
Write-Host ""
Read-Host "按回车退出"
