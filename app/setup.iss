; Inno Setup Script for Duckov Mod Manager
; Generated for Flet Windows build

[Setup]
; 应用基本信息
AppName=Duckov Mod Manager
AppVersion=0.1.0
AppVerName=Duckov Mod Manager 0.1.0
AppPublisher=Flet
AppPublisherURL=https://flet.dev
AppSupportURL=https://flet.dev
AppUpdatesURL=https://flet.dev
DefaultDirName={autopf}\Duckov Mod Manager
DefaultGroupName=Duckov Mod Manager
AllowNoIcons=yes
; 安装程序信息
LicenseFile=
InfoBeforeFile=
InfoAfterFile=
; 输出设置
OutputDir=Releases
OutputBaseFilename=DuckovModManager-Setup-0.1.0
SetupIconFile=
Compression=lzma
SolidCompression=yes
; Windows版本要求
MinVersion=6.1
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; 主程序文件
Source: "build\windows\app.exe"; DestDir: "{app}"; Flags: ignoreversion
; DLL文件
Source: "build\windows\*.dll"; DestDir: "{app}"; Flags: ignoreversion
; 数据目录
Source: "build\windows\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
; Python相关目录
Source: "build\windows\DLLs\*"; DestDir: "{app}\DLLs"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "build\windows\Lib\*"; DestDir: "{app}\Lib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "build\windows\site-packages\*"; DestDir: "{app}\site-packages"; Flags: ignoreversion recursesubdirs createallsubdirs

; 注意: 确保所有必要的文件都被包含
; 如果还有其他文件需要包含，请添加相应的Source行

[Icons]
Name: "{group}\Duckov Mod Manager"; Filename: "{app}\app.exe"
Name: "{group}\{cm:UninstallProgram,Duckov Mod Manager}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Duckov Mod Manager"; Filename: "{app}\app.exe"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\Duckov Mod Manager"; Filename: "{app}\app.exe"; Tasks: quicklaunchicon

[Run]
Filename: "{app}\app.exe"; Description: "{cm:LaunchProgram,Duckov Mod Manager}"; Flags: nowait postinstall skipifsilent

[Code]
// 自定义安装过程代码（可选）
function InitializeSetup(): Boolean;
begin
  // 可以在这里添加安装前的检查
  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // 安装完成后可以执行的操作
  end;
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Messages]
WelcomeLabel2=此安装程序将安装 Duckov Mod Manager 到您的计算机。%n%n建议在继续安装之前关闭所有其他应用程序。
