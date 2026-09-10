# run_sigret_trace.ps1 — 完整 sigreturn 路径跟踪
# 流程: QEMU启动 → exploit运行 → CALL_SIGRET → 冻结 → dump寄存器+栈+搜FPSIMD
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$qemu = "$root\tools\qemu\qemu-system-aarch64.exe"
$img  = "$root\work\boot_out\Image"
$initrd = "$root\work\qemu\initramfs_sr.cpio"
$out  = "$root\work\qemu"
$py   = "$root\tools\python\python.exe"

Get-Process qemu-system-aarch64 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Remove-Item "$out\trace_serial.log" -Force -ErrorAction SilentlyContinue

Write-Host "[1/3] 启动 QEMU (2核, serial直写)..."
$inner = "& '$qemu' -M virt -cpu cortex-a72 -smp 2 -m 1024 -kernel '$img' -initrd '$initrd' -append 'console=ttyAMA0 nokaslr rdinit=/init panic=-1' -display none -no-reboot -serial 'file:$out\trace_serial.log' -monitor 'telnet:127.0.0.1:5555,server,nowait'"
Start-Process powershell.exe -ArgumentList '-NoProfile','-Command',$inner -WindowStyle Hidden

Write-Host "[2/3] 等 CALL_SIGRET..."
$ready=$false
for($i=0;$i -lt 60;$i++){
    Start-Sleep -Seconds 1
    $c = Get-Content "$out\trace_serial.log" -Raw -ErrorAction SilentlyContinue
    if($c -match 'CALL_RT_SIGRETURN'){ $ready=$true; break }
}
"CALL_SIGRET: $ready ($($i)s)"
if(-not $ready){
    Write-Host "未到达 sigreturn, 最后输出:"
    Get-Content "$out\trace_serial.log" -Tail 8 | ForEach-Object { $_.Trim() }
    Get-Process qemu-system-aarch64 -ErrorAction SilentlyContinue | Stop-Process -Force
    exit 1
}
# 再等 3 秒确保 sigreturn 已进入内核路径
Start-Sleep -Seconds 3

Write-Host "[3/3] 冻结并 dump..."
& $py "$out\sigret_trace.py"
Get-Process qemu-system-aarch64 -ErrorAction SilentlyContinue | Stop-Process -Force

Write-Host "`n结果已保存到: $LOG"
Write-Host "串口日志: $out\trace_serial.log"
