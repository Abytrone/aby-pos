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
# 4. With a code-signing certificate, aby_pos.exe, the installer and the
#    uninstaller are signed, so Windows SmartScreen does not warn shops.
#    Put the certificate in your Windows certificate store and set its
#    thumbprint first:  $env:ABY_SIGN_CERT = '<SHA-1 thumbprint>'
#    Without it the installer is built unsigned, with a warning.
#
# Needs Inno Setup 6: winget install JRSoftware.InnoSetup
# Signing also needs signtool, from the Windows SDK.

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

# The version the app shows and sends to the hub must be this one.
if (-not (Select-String -Path lib\app\core\app_version.dart -SimpleMatch "'$version'" -Quiet)) {
    throw "lib\app\core\app_version.dart does not say $version, as pubspec.yaml does."
}

$cert = $env:ABY_SIGN_CERT
$signtool = $null
if ($cert) {
    $signtool = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\signtool.exe" -ErrorAction SilentlyContinue |
        Sort-Object FullName -Descending | Select-Object -First 1 -ExpandProperty FullName
    if ($null -eq $signtool) { throw 'ABY_SIGN_CERT is set but signtool is not installed (Windows SDK).' }
}
$signArgs = "sign /sha1 $cert /fd sha256 /tr http://timestamp.digicert.com /td sha256"

Write-Host "Building Aby $version..."
# A clean folder, so nothing from an older build ends up in the installer.
if (Test-Path $release) { Remove-Item -Recurse -Force $release }
flutter build windows --release --obfuscate "--split-debug-info=$symbols"
if ($LASTEXITCODE -ne 0) { throw 'flutter build failed.' }

foreach ($dll in 'msvcp140.dll', 'vcruntime140.dll', 'vcruntime140_1.dll') {
    Copy-Item "$env:WINDIR\System32\$dll" $release
}

Write-Host 'Making the installer...'
if ($signtool) {
    & $signtool $signArgs.Split(' ') "$release\aby_pos.exe"
    if ($LASTEXITCODE -ne 0) { throw 'Signing aby_pos.exe failed.' }
    # Inno Setup runs this for the installer and uninstaller; $f is the file.
    & $iscc "/DAppVersion=$version" '/DSign' "/Saby=`$q$signtool`$q $signArgs `$f" installer\aby_pos.iss
} else {
    & $iscc "/DAppVersion=$version" installer\aby_pos.iss
}
if ($LASTEXITCODE -ne 0) { throw 'Inno Setup failed.' }

Write-Host ''
Write-Host "Installer: build\installer\AbySetup-$version.exe"
if (-not $signtool) { Write-Warning 'Not signed: Windows SmartScreen will warn shops. Set ABY_SIGN_CERT to sign.' }
Write-Host "Symbols:   $symbols (keep these to read crash reports from $version)"
