# 03_qemu_boot.ps1 — PD2238 内核 QEMU 冒烟测试 (Windows 版 harness)
# 用法: powershell -File scripts\03_qemu_boot.ps1 [-Gdb] [-Shell] [-Verify]
param(
    [switch]$Gdb,
    [switch]$Shell,
    [switch]$Verify
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$qemu = "$root\tools\qemu\qemu-system-aarch64.exe"
$py   = "$root\tools\python\python.exe"
$img  = "$root\work\boot_out\Image"
$initc= "$root\work\qemu\init_pd2238.c"
$out  = "$root\work\qemu"
$clang= "$root\tools\ndk\toolchains\llvm\prebuilt\windows-x86_64\bin\clang.exe"

if (-not (Test-Path $qemu)) { Write-Error "qemu 未安装: $qemu"; exit 1 }
if (-not (Test-Path $img))  { Write-Error "内核 Image 不存在: $img (先跑 02 脚本)"; exit 1 }
if (-not (Test-Path $clang)){ Write-Error "NDK clang 未就绪"; exit 1 }
New-Item -ItemType Directory -Force -Path $out | Out-Null

# 1) 编译 freestanding init (aarch64-linux-gnu 目标)
Write-Host "[1/4] 编译 init..."
& $clang --target=aarch64-linux-gnu -ffreestanding -nostdlib -static '-Wl,-e,_start' -o "$out\init" $initc
if ($LASTEXITCODE -ne 0) { Write-Error "init 编译失败"; exit 1 }

# 2) bsdtar 生成 newc initramfs + 补丁 mode 为 0755
Write-Host "[2/4] 生成 initramfs..."
New-Item -ItemType Directory -Force -Path "$out\rootdir" | Out-Null
Copy-Item "$out\init" "$out\rootdir\init" -Force
Push-Location "$out\rootdir"
tar.exe --format=newc -cf "$out\initramfs_raw.cpio" init
Pop-Location
# 补丁 newc mode 字段 (offset 14): 0666(000081b6) -> 0755(000081ed)
$cpb = [System.IO.File]::ReadAllBytes("$out\initramfs_raw.cpio")
$modeBytes = [System.Text.Encoding]::ASCII.GetBytes("000081ed")
[Array]::Copy($modeBytes, 0, $cpb, 14, 8)
[System.IO.File]::WriteAllBytes("$out\initramfs.cpio", $cpb)
"  initramfs: $([math]::Round((Get-Item "$out\initramfs.cpio").Length/1KB,1))KB (mode 已补丁为 0755)"

# 4) 运行 (经 cmd.exe 包装保证引号正确)
$cmdline = 'console=ttyAMA0 nokaslr rdinit=/init panic=-1'
$fullCmd = '"{0}" -M virt -cpu cortex-a72 -smp 2 -m 1024 -kernel "{1}" -initrd "{2}" -append "{3}" -nographic -no-reboot' -f $qemu, $img, "$out\initramfs.cpio", $cmdline
if ($Verify) { $fullCmd += ' -monitor telnet:127.0.0.1:5555,server,nowait' }
elseif ($Shell -or $Gdb) { $fullCmd += ' -s' }
Write-Host "[4/4] 运行 (Ctrl-A x 退出; boot 模式 40s 超时自动退出)..."
if ($Shell) { cmd /c $fullCmd; exit }
elseif ($Verify) {
    # 后台 PowerShell 直接调 QEMU (monitor telnet 5555), 避免 cmd 逗号问题
    $bgScript = "& '$qemu' -M virt -cpu cortex-a72 -smp 2 -m 1024 -kernel '$img' -initrd '$out\initramfs.cpio' -append 'console=ttyAMA0 nokaslr rdinit=/init panic=-1' -nographic -no-reboot -monitor 'telnet:127.0.0.1:5555,server,nowait'"
    Start-Process -FilePath "powershell.exe" -ArgumentList '-NoProfile','-Command',('& {' + $bgScript + '}') -WindowStyle Hidden | Out-Null
    Start-Sleep -Seconds 14
    "=== 运行 QEMU monitor 偏移验证: ==="
    & $py "$root\work\qemu\verify_vaddr.py"
    Get-Process -Name qemu-system-aarch64 -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
else {
    cmd /c $fullCmd > "$out\qemu_stdout.log" 2>&1
    $hit = Select-String -Path "$out\qemu_stdout.log" -Pattern 'userspace reached' -Quiet
    "=== QEMU 输出尾部: ==="
    Get-Content "$out\qemu_stdout.log" -Tail 8 -ErrorAction SilentlyContinue | ForEach-Object { $_.Trim().Substring(0,[Math]::Min(110,$_.Trim().Length)) }
    if ($hit) { "`n>>> 成功: 内核启动到用户态 (marker 命中)" }
    else      { "`n>>> 未检测到 marker (内核启动失败或卡住, 见日志)" }
}
