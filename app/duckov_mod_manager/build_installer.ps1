<#  build-installer.ps1
    使用 Inno Setup 6 打包 Flutter Windows 应用
#>

# 1) 修改为你本机 Inno Setup Compiler 的完整路径
$ISCC_PATH = 'D:\Application\System_Application\Inno Setup 6\ISCC.exe'

# ================== 以下通常无需改动 ==================
$ErrorActionPreference = 'Stop'     # 遇错立即退出

# 项目根目录（脚本所在目录）
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Inno Setup 脚本 (.iss) 路径
$IssFile = Join-Path $ProjectRoot 'DuckovModManagerInstaller.iss'

# 确保 .iss 文件存在
if (-not (Test-Path $IssFile)) {
    throw "无法找到 Inno Setup 脚本：$IssFile"
}

# 如果 .iss 中指定的输出目录不存在，先创建
# 读取 OutputDir 行
$OutputDirLine = Select-String -Path $IssFile -Pattern '^\s*OutputDir\s*=\s*(.+)$' | Select-Object -First 1
if ($OutputDirLine) {
    $OutputDir = ($OutputDirLine.Matches.Groups[1].Value).Trim()
    $OutputDirFull = if ([System.IO.Path]::IsPathRooted($OutputDir)) {
        $OutputDir
    } else {
        Join-Path $ProjectRoot $OutputDir
    }
    New-Item -ItemType Directory -Path $OutputDirFull -Force | Out-Null
}

# 调用 Inno Setup Compiler 进行打包
Write-Host "Building installer using $IssFile ..."
& "$ISCC_PATH" "$IssFile"

Write-Host "Done! Installer generated to the configured OutputDir."