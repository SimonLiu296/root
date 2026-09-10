# probe_pd2238.ps1 — PD2238 mtkclient HeapBait 零风险探测
# 用法: powershell -File scripts\probe_pd2238.ps1 [-Loader <DA_BR.bin路径>]
# 前置: 手机关机, 不按任何按键, 直接插 USB 线 (preloader 模式)
param(
    [string]$Loader = ""
)
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$m    = "$root\tools\mtkclient"
$py   = "$root\tools\python\python.exe"
$log  = "$root\work\probe_result.log"

Push-Location $m
$args = @('printgpt')
if ($Loader -ne "") { $args = @('--loader', $Loader) + $args }
Write-Host "[*] 等待设备接入 preloader 模式 (120s 超时)..."
& $py mtk.py @args *>&1 | Tee-Object -FilePath $log
Pop-Location

"================ 判读 ================"
$r = Get-Content $log -Raw
if ($r -match 'pgdet|Partition gauge|name:.*offset') {
    "✓✓✓ DA 认证绕过成功! 分区表已读取 → HeapBait 路线活着!"
    "下一步: python mtk.py da seccfg unlock"
} elseif ($r -match 'patched against carbonara|Device is protected') {
    "✗ 设备保护生效 → 该 DA/漏洞被堵, 尝试 --loader 换 DA_BR 或等 heapbait 参数更新"
} elseif ($r -match 'waiting for PreLoader|no device') {
    "? 未检测到设备 → 确认手机关机后直接插线 (不按任何键)"
} else {
    "? 未知输出, 把日志发给分析"
}
