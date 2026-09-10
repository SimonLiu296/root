# 01_unpack_ota.ps1 — 从全量卡刷包提取关键分区镜像
# 用法: powershell -File scripts\01_unpack_ota.ps1 <OTA.zip路径>
param(
    [Parameter(Mandatory=$true)][string]$OtaZip
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$pdg  = "$root\tools\bin\payload-dumper-go.exe"
$out  = "$root\work\ota_out"

if (-not (Test-Path $OtaZip)) { Write-Error "找不到 $OtaZip"; exit 1 }
New-Item -ItemType Directory -Force -Path $out | Out-Null

Write-Host "[1/3] 列出 OTA 分区表..."
& $pdg -l $OtaZip | Tee-Object -FilePath "$out\partitions.txt"

Write-Host "[2/3] 提取关键分区 (boot init_boot vendor_boot vbmeta dtbo preloader)..."
# preloader 若不在 payload 中会自动跳过（vivo 可能只放线刷包）
& $pdg -o $out -p 'boot,init_boot,vendor_boot,vbmeta,dtbo,preloader,preloader_a,preloader_b,vendor_boot_a,vendor_boot_b' $OtaZip
if ($LASTEXITCODE -ne 0) {
    Write-Host "  指定分区提取失败，回退为全量提取..."
    & $pdg -o $out $OtaZip
}

Write-Host "[3/3] 结果:"
Get-ChildItem $out -Filter *.img | ForEach-Object { "  {0}  {1:N1} MB" -f $_.Name, ($_.Length/1MB) }
Write-Host "`n完成。镜像位于: $out"
Write-Host "下一步: powershell -File scripts\02_boot_kallsyms.ps1 $out\boot.img"
