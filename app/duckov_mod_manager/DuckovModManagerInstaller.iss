; =============================================================
; Escape from Duckov Mod Manager – Windows 安装程序 (Inno Setup 6)
; =============================================================

[Setup]
; 应用信息 ----------------------------------------------------
AppName=Duckov Mod Manager
AppVersion=0.2.5
AppPublisher=WaveYou
AppCopyright=Copyright © 2025 WaveYou
; 安装目录、开始菜单组等 --------------------------------------
DefaultDirName={pf}\DuckovModManager
DefaultGroupName=Duckov Mod Manager
; 输出 --------------------------------------------------------
OutputDir=dist
OutputBaseFilename=DuckovModManagerSetup
Compression=lzma
SolidCompression=yes

[Files]
; 将 Flutter Release 目录中的全部文件递归复制到安装目录
Source: "build\windows\x64\runner\Release\*"; \
        DestDir: "{app}"; \
        Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
; 桌面和开始菜单快捷方式（如有需要，可添加 WorkingDir 等参数）
Name: "{group}\Duckov Mod Manager"; \
      Filename: "{app}\duckov_mod_manager.exe"
Name: "{group}\Uninstall Duckov Mod Manager"; \
      Filename: "{uninstallexe}"

[Run]
; 安装完成后立即启动（可选）
; Filename: "{app}\duckov_mod_manager.exe"; Description: "{cm:LaunchProgram,Duckov Mod Manager}"; Flags: nowait postinstall skipifsilent
