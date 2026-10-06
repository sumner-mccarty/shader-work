# slrender toolchain for Windows. Idempotent.
#
#   powershell -ExecutionPolicy Bypass -File Tools/setup_toolchain.ps1          # dxc + spirv-cross + python deps
#   powershell -ExecutionPolicy Bypass -File Tools/setup_toolchain.ps1 -Mesa    # also Mesa llvmpipe (SLRENDER_SOFTWARE=1)
#
# spirv-cross is built from the pinned tag with CMake + Visual Studio (C++ workload).
param([switch]$Mesa, [switch]$Check)
$ErrorActionPreference = 'Stop'

$Repo = Split-Path -Parent $PSScriptRoot
$TC = Join-Path $Repo '.toolchain'
$M = Get-Content (Join-Path $Repo 'Tools/toolchain.json') -Raw | ConvertFrom-Json
New-Item -ItemType Directory -Force (Join-Path $TC 'bin') | Out-Null
function Log($s) { Write-Host "[slrender-setup] $s" }

if (-not $Check) {
    # dxc
    $dxc = Join-Path $TC 'dxc/bin/x64/dxc.exe'
    if (-not (Test-Path $dxc)) {
        Log "dxc $($M.dxc.tag)"
        $zip = Join-Path $env:TEMP 'slr_dxc.zip'
        Invoke-WebRequest -UseBasicParsing -OutFile $zip "https://github.com/microsoft/DirectXShaderCompiler/releases/download/$($M.dxc.tag)/$($M.dxc.windows.asset)"
        $sum = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        if ($sum -ne $M.dxc.windows.sha256) { throw "dxc checksum mismatch ($sum)" }
        Expand-Archive -Force $zip (Join-Path $TC 'dxc')
        Remove-Item $zip
    }

    # spirv-cross
    $sc = Join-Path $TC 'bin/spirv-cross.exe'
    if (-not (Test-Path $sc)) {
        if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) { throw 'spirv-cross needs CMake + Visual Studio C++ to build' }
        $src = Join-Path $TC 'spirv-cross-src'
        if (-not (Test-Path (Join-Path $src '.git'))) {
            git clone -q --depth 1 --branch $M.spirv_cross.tag $M.spirv_cross.repo $src
        }
        Log "building spirv-cross $($M.spirv_cross.tag)"
        cmake -S $src -B (Join-Path $src 'build') -DSPIRV_CROSS_ENABLE_TESTS=OFF -DSPIRV_CROSS_SHARED=OFF -DSPIRV_CROSS_STATIC=ON -DSPIRV_CROSS_CLI=ON | Out-Null
        cmake --build (Join-Path $src 'build') --config Release --target spirv-cross -j 8 | Out-Null
        Copy-Item (Join-Path $src 'build/Release/spirv-cross.exe') $sc
    }

    # Mesa llvmpipe (optional)
    if ($Mesa -and -not (Test-Path (Join-Path $TC 'mesa/x64/opengl32.dll'))) {
        Log "mesa $($M.mesa_windows.tag)"
        $arc = Join-Path $env:TEMP 'slr_mesa.7z'
        Invoke-WebRequest -UseBasicParsing -OutFile $arc "https://github.com/pal1000/mesa-dist-win/releases/download/$($M.mesa_windows.tag)/$($M.mesa_windows.asset)"
        New-Item -ItemType Directory -Force (Join-Path $TC 'mesa') | Out-Null
        & "$env:SystemRoot\System32\tar.exe" -xf $arc -C (Join-Path $TC 'mesa')
        Remove-Item $arc
    }

    # python
    python -c "import moderngl, numpy, PIL" 2>$null
    if ($LASTEXITCODE -ne 0) { Log 'pip install'; python -m pip install -q @($M.python) }
}

Set-Location $Repo
python -m slrender doctor
