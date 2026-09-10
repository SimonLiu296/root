# 04_build.ps1 — 编译 PD2238 preload.so (Windows, 免 make)
# 用法: powershell -File scripts\04_build.ps1
# 产物: src\aristotle-root\build\pd2238-16.3.15.0.W10\bin\preload.so
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$a    = "$root\src\aristotle-root"
$ndk  = "$root\tools\ndk"
$cc   = "$ndk\toolchains\llvm\prebuilt\windows-x86_64\bin\aarch64-linux-android35-clang.cmd"
$proj = "pd2238-16.3.15.0.W10"

if (-not (Test-Path $cc)) { Write-Error "NDK clang 未就绪: $cc"; exit 1 }
$tgt = "$a\src\targets\$proj"
if (-not (Test-Path "$tgt\target.h")) { Write-Error "缺少 target.h: $tgt"; exit 1 }

$outdir = "$a\build\$proj\bin"
$embed  = "$a\build\embed"
New-Item -ItemType Directory -Force -Path $outdir, $embed | Out-Null

# 1) 编译嵌入式 su_daemon (PIE)
Write-Host "[1/3] 编译 su_daemon..."
& $cc -O2 -fPIE -pie "$a\src\su_daemon.c" -fuse-ld=lld '-Wl,-dynamic-linker,/system/bin/linker64' -o "$embed\su_daemon_aarch64_pie"
if ($LASTEXITCODE -ne 0) { Write-Error "su_daemon 编译失败"; exit 1 }
"  su_daemon: $([math]::Round((Get-Item "$embed\su_daemon_aarch64_pie").Length/1KB,1))KB"

# 2) 编译 preload.so
Write-Host "[2/3] 编译 preload.so (PROJECT=$proj)..."
$srcs = @(
  "$a\src\main.c", "$a\src\util.c", "$a\src\slide.c", "$a\src\fops.c",
  "$a\src\sigret.c", "$a\src\pipe.c", "$a\src\root.c", "$a\src\heap_spray.c",
  "$a\src\preload.c", "$a\src\su_blob.S", "$a\src\wallpaper_blob.S"
)
$arg = @(
  '-O2','-g0','-Wall','-Wextra','-Isrc','-fPIC',
  '-Wno-unused-parameter','-Wno-sign-compare','-Wno-unused-function',
  ('-DTARGET_CONFIG_H=' + [char]34 + 'targets/' + $proj + '/target.h' + [char]34),
  '-fuse-ld=lld',
  '-shared','-pthread'
) + $srcs + @('-o', "$outdir\preload.so")
Push-Location $a
& $cc @arg
$code = $LASTEXITCODE
Pop-Location
if ($code -ne 0) { Write-Error "preload.so 编译失败 (exit=$code)"; exit 1 }
"  preload.so: $([math]::Round((Get-Item "$outdir\preload.so").Length/1KB,1))KB"
Copy-Item "$outdir\preload.so" "$root\preload.so" -Force
"  已复制到 $root\preload.so"

# 3) SHA256
Write-Host "[3/3] 校验和:"
Get-FileHash "$outdir\preload.so" -Algorithm SHA256 | ForEach-Object { "  $($_.Hash)  $($_.Path)" }
"`n完成: $outdir\preload.so"
