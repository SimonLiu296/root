# 02_boot_kallsyms.ps1 — 解包 boot.img 并静态提取 kallsyms 符号表
# 用法: powershell -File scripts\02_boot_kallsyms.ps1 <boot.img路径>
param(
    [Parameter(Mandatory=$true)][string]$BootImg
)
$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$mb    = "$root\tools\bin\magiskboot\magiskboot.exe"
$py    = "$root\tools\python\python.exe"
$kfind = "$root\tools\vmlinux-to-elf\vmlinux_to_elf\scripts\kallsyms_finder.py"
$out   = "$root\work\boot_out"

if (-not (Test-Path $BootImg)) { Write-Error "找不到 $BootImg"; exit 1 }
New-Item -ItemType Directory -Force -Path $out | Out-Null
Push-Location $out
try {
    Copy-Item $BootImg "$out\boot.img" -Force

    Write-Host "[1/4] magiskboot 解包..."
    & $mb unpack boot.img | Tee-Object -FilePath "$out\unpack_log.txt"
    if (-not (Test-Path "$out\kernel")) { Write-Error "kernel 未解出"; exit 1 }

    Write-Host "[2/4] 识别内核压缩格式..."
    $fs   = [System.IO.File]::OpenRead("$out\kernel")
    $head = New-Object byte[] 4
    [void]$fs.Read($head, 0, 4)
    $fs.Close()
    $magic = ($head | ForEach-Object { $_.ToString('x2') }) -join ''
    $kimg  = "$out\kernel"
    if ($magic -eq '1f-8b-08-00' -or $magic.StartsWith('1f-8b-08')) {
        Write-Host "  gzip 压缩 -> 解压"
        $src = [System.IO.File]::OpenRead("$out\kernel")
        $gz  = [System.IO.Compression.GzipStream]::new($src, [System.IO.Compression.CompressionMode]::Decompress)
        $dst = [System.IO.File]::Create("$out\Image")
        $gz.CopyTo($dst)
        $dst.Close(); $gz.Close(); $src.Close()
        $kimg = "$out\Image"
    }
    elseif ($magic.StartsWith('04-22-4d-18')) { Write-Error "lz4 压缩: 需先安装 lz4.exe 再手动解压 kernel"; exit 1 }
    elseif ($magic.StartsWith('28-b5-2f-fd')) { Write-Error "zstd 压缩: 需先安装 zstd.exe 再手动解压 kernel"; exit 1 }
    else { Write-Host "  未压缩原始 Image (magic=$magic)" }

    Write-Host "[3/4] kallsyms 静态提取..."
    & $py $kfind $kimg --output "$out\kallsyms.txt" 2>&1 | Tee-Object -FilePath "$out\kallsyms_log.txt"

    Write-Host "[4/4] 检索 GhostLock 所需符号..."
    $syms = @(
        'ashmem_misc_fops','ashmem_ioctl','ashmem_compat_ioctl','ashmem_mmap',
        'ashmem_open','ashmem_release','ashmem_show_fdinfo',
        'configfs_read_iter','configfs_bin_write_iter',
        'copy_splice_read','noop_llseek',
        'init_task','init_uts_ns','empty_zero_page','root_task_group',
        'selinux_blob_sizes','selinux_enforcing','security_hook_heads',
        'kmalloc_caches','anon_pipe_buf_ops',
        'nfnl_log','sysctl_bootid'
    )
    "symbol lookup results ($(Get-Date))" > "$out\symbols_found.txt"
    foreach ($s in $syms) {
        $hit = Select-String -Path "$out\kallsyms.txt" -Pattern ([regex]::Escape($s)) |
               Select-Object -First 3
        if ($hit) { $hit | ForEach-Object { $_.Line } | Add-Content "$out\symbols_found.txt" }
        else      { "MISSING: $s" | Add-Content "$out\symbols_found.txt" }
    }
    Get-Content "$out\symbols_found.txt"
}
finally { Pop-Location }
Write-Host "`n完成。产物位于: $out"
