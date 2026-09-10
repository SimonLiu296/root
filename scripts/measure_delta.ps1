# measure_delta.ps1 — 单会话完成: 启动QEMU→等REQUEUE→gdb扫描悬垂pib→清理
$ErrorActionPreference = 'Continue'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$qemu = "$root\tools\qemu\qemu-system-aarch64.exe"
$img  = "$root\work\boot_out\Image"
$gdb  = "$root\tools\aarch64-gcc\gcc-v16.2.0-aarch64-none-elf\bin\gdb.exe"
$out  = "$root\work\qemu"

Get-Process qemu-system-aarch64 -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Remove-Item "$out\md_qemu.log","$out\md_gdb.log" -Force -ErrorAction SilentlyContinue

# 启动 QEMU (本会话后台 job, 生命周期跟随本会话)
$qjob = Start-Job -ScriptBlock {
    param($q,$i,$o)
    & $q -M virt -cpu cortex-a72 -smp 2 -m 1024 -kernel $i -initrd "$o\initramfs_sw.cpio" -append "console=ttyAMA0 nokaslr rdinit=/init panic=-1" -nographic -no-reboot -s *> "$o\md_qemu.log"
} -ArgumentList $qemu,$img,$out

# 等 REQUEUE_DONE
$ready=$false; $waited=0
for($i=0;$i -lt 60;$i++){
    Start-Sleep -Seconds 2
    $waited=$i*2
    $c = Get-Content "$out\md_qemu.log" -Raw -ErrorAction SilentlyContinue
    if($c -match 'REQUEUE_DONE'){ $ready=$true; break }
}
Write-Host "REQUEUE_DONE=$ready waited=${waited}s"
if(-not $ready){ Stop-Job $qjob; Remove-Job $qjob -Force; exit 1 }

# 多等几秒让 waiter 进入轮次窗口
Start-Sleep -Seconds 6

# gdb 冻结扫描 (读全部任务的 pib)
& $gdb -q -batch -x "$out\dump_pib_all.txt" > "$out\md_gdb.log" 2>&1

# 收尾
Get-Process qemu-system-aarch64 -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Job $qjob -ErrorAction SilentlyContinue; Remove-Job $qjob -Force -ErrorAction SilentlyContinue

Write-Host "`n=== 扫描结果 ==="
$nz = Get-Content "$out\md_gdb.log" | Select-String -Pattern "NONZERO"
if($nz){
    Write-Host "发现非零 pib:"
    Get-Content "$out\md_gdb.log" | Select-String -Pattern "NONZERO" -Context 0,4 | ForEach-Object {
        $_.Line.Trim(); $_.Context.PostContext | ForEach-Object { "    $_" }
    }
} else {
    Write-Host "无非零 pib (所有任务 pi_blocked_on=0)"
}
Write-Host "`n=== 任务列表尾部 ==="
Get-Content "$out\md_gdb.log" | Select-String -Pattern "^\[" | Select-Object -Last 10 | ForEach-Object { $_.Line.Trim().Substring(0,[Math]::Min(115,$_.Line.Trim().Length)) }
Write-Host "`n=== QEMU e2e 时序 ==="
Get-Content "$out\md_qemu.log" -ErrorAction SilentlyContinue | Select-String -Pattern "WTID|REQUEUE|ROUND|WAITER_RET|BOOTID=" | Select-Object -Last 8 | ForEach-Object { $_.Line.Trim().Substring(0,[Math]::Min(110,$_.Line.Trim().Length)) }
