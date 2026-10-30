; The Windows installer for Aby. Built by build_windows.ps1, which passes the
; version from pubspec.yaml; compiling this by hand uses the defaults below.
;
; The shop's data (Documents\aby_pos.sqlite, backups, the license) is not
; part of the install: uninstalling or upgrading never touches it.

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif
#ifndef BuildDir
  #define BuildDir "..\build\windows\x64\runner\Release"
#endif

#define AppName "Aby"
#define AppPublisher "Aby"
#define AppExe "aby_pos.exe"

[Setup]
; Never change AppId: it is how Windows knows a new installer upgrades Aby
; rather than installing a second copy.
AppId={{7D97A860-4E33-4FAA-ADE9-C5F4D2CF3460}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
; Program Files, so only an administrator can change the program itself.
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=..\build\installer
OutputBaseFilename=AbySetup-{#AppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Closes a running Aby before upgrading it.
CloseApplications=yes
; Shown before installing once there is a license agreement:
; LicenseFile=eula.txt
; Signs the installer and uninstaller once there is a code-signing
; certificate (Tools > Configure Sign Tools in the Inno Setup IDE):
; SignTool=signtool

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
; The hub serves the shop's other tills over Wi-Fi (TCP 8787, and a UDP
; beacon). Allowing it here means a cashier is never asked by Windows
; Firewall, and cannot block it by pressing Cancel. Removed first so an
; upgrade does not add the rule twice.
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""{#AppName}"""; Flags: runhidden; StatusMsg: "Setting up the network..."
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""{#AppName}"" dir=in action=allow program=""{app}\{#AppExe}"" enable=yes profile=any"; Flags: runhidden
Filename: "{app}\{#AppExe}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""{#AppName}"""; Flags: runhidden; RunOnceId: "RemoveFirewallRule"
