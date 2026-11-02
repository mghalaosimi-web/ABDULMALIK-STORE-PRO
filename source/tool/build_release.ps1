# Windows-only release pipeline. Android packaging is intentionally deferred.
[CmdletBinding()]
param([switch]$SkipTests)

$ErrorActionPreference = 'Stop'
$sourceRoot = Split-Path -Parent $PSScriptRoot
$repoRoot = Split-Path -Parent $sourceRoot
Push-Location $sourceRoot
try {
    $flutter = Get-Command flutter -ErrorAction SilentlyContinue
    if (-not $flutter) { throw 'Flutter is not on PATH. Install the Flutter stable SDK and Windows desktop toolchain first.' }

    $versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)'
    if (-not $versionLine) { throw 'Could not read app version from pubspec.yaml.' }
    $version = $versionLine.Matches[0].Groups[1].Value
    $builds = Join-Path $repoRoot 'builds'
    New-Item -ItemType Directory -Force -Path $builds | Out-Null

    Write-Host "== ABDULMALIK ERP $version / Windows x64 =="
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'flutter pub get failed.' }

    if (-not $SkipTests) {
        flutter analyze
        if ($LASTEXITCODE -ne 0) { throw 'flutter analyze failed. Resolve analyzer errors before packaging.' }
        flutter test --reporter expanded
        if ($LASTEXITCODE -ne 0) { throw 'Flutter tests failed. Installer was not created.' }
    }

    flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw 'Windows Release build failed.' }

    $release = Join-Path $sourceRoot 'build\windows\x64\runner\Release'
    $exe = Join-Path $release 'abdulmalik_erp.exe'
    if (-not (Test-Path $exe)) { throw "Windows executable not found: $exe" }

    # Include the official Microsoft x64 VC++ runtime installer so first-time
    # installs can complete without a separate manual prerequisite download.
    $vcRuntime = Join-Path $release 'vc_redist.x64.exe'
    if (-not (Test-Path $vcRuntime)) {
        Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile $vcRuntime
    }
    if ((Get-Item $vcRuntime).Length -lt 1MB) { throw 'Downloaded Visual C++ Redistributable looks incomplete.' }

    $isccCandidates = @(
        (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Inno Setup 6\ISCC.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6\ISCC.exe')
    )
    $iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $iscc) { throw 'Inno Setup 6 ISCC.exe was not found.' }

    & $iscc "/DAppVersion=$version" "/DOutputDir=$builds" (Join-Path $sourceRoot 'installer\abdulmalik_erp.iss')
    if ($LASTEXITCODE -ne 0) { throw 'Inno Setup compilation failed.' }

    $installer = Join-Path $builds "ABDULMALIK-ERP-Setup-$version.exe"
    if (-not (Test-Path $installer)) { throw 'Installer output is missing.' }
    $hash = (Get-FileHash $installer -Algorithm SHA256).Hash
    Write-Host "SUCCESS: $installer"
    Write-Host "SHA256: $hash"
}
finally {
    Pop-Location
}
