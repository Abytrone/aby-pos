# Builds the Windows installer: build\installer\AbySetup-<version>.exe
#
#   powershell -ExecutionPolicy Bypass -File build_windows.ps1
#
# 1. A release build, obfuscated. The symbols needed to read crash reports
#    go to build\symbols\<version>: keep a copy of them for every version
#    you ship, and never ship them.
# 2. The Visual C++ runtime goes in next to aby_pos.exe, so Aby starts on
#    a freshly installed Windows that does not have it.
# 3. Inno Setup turns the folder into one installer (installer\aby_pos.iss).
#
# Needs Inno Setup 6: winget install JRSoftware.InnoSetup

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$line = Select-String -Path pubspec.yaml -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)' | Select-Object -First 1
if ($null -eq $line) { throw 'No version: line in pubspec.yaml.' }
$version = $line.Matches[0].Groups[1].Value
$release = 'build\windows\x64\runner\Release'
$symbols = "build\symbols\$version"

$iscc = @(
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if ($null -eq $iscc) { throw 'Inno Setup 6 is not installed. Install it with: winget install JRSoftware.InnoSetup' }

Write-Host "Building Aby $version..."
# A clean folder, so nothing from an older build ends up in the installer.
if (Test-Path $release) { Remove-Item -Recurse -Force $release }
flutter build windows --release --obfuscate "--split-debug-info=$symbols"
if ($LASTEXITCODE -ne 0) { throw 'flutter build failed.' }

foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    Copy-Item "$env:WINDIR\System32\$dll" $release
}

Write-Host 'Making the installer...'
& $iscc "/DAppVersion=$version" installer\aby_pos.iss
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed.' }

Write-Host ''
Write-Host "Installer: build\installer\AbySetup-$version.exe"
Write-Host "Symbols:   $symbols (keep these to read crash reports from $version)"
