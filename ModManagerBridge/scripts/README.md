# ModManagerBridge 测试脚本套件

这个目录包含用于测试 ModManagerBridge 功能的 Python 脚本套件。

## 脚本说明

### 1. simple_test.py
简单的测试脚本，执行基本命令来测试 ModManagerBridge：
- 获取 mod 列表
- 获取特定 mod 的信息
- 启用 mod
- 禁用 mod

### 2. comprehensive_test.py
综合测试工具，提供多种测试模式：
- 综合测试（运行所有测试用例）
- 命令行模式（直接执行特定命令）
- 交互模式（手动选择测试功能）

### 3. mod_manager_client.py
ModManagerBridge 客户端库，提供统一的 JSON 格式和错误处理。

## 使用方法

确保 ModManagerBridge mod 已在游戏中加载并运行，然后执行 Python 脚本：

```bash
# 运行简单测试
python simple_test.py

# 运行综合测试
python comprehensive_test.py

# 命令行模式
python comprehensive_test.py list        # 获取 mod 列表
python comprehensive_test.py info <mod> # 获取 mod 信息
python comprehensive_test.py enable <mod> # 启用 mod
python comprehensive_test.py disable <mod> # 禁用 mod
python comprehensive_test.py test       # 运行综合测试

# 使用客户端库
python mod_manager_client.py
```

## API 命令说明

### get_mod_list
获取所有已安装 mod 的列表，包括每个 mod 的启用状态、版本和作者信息。

请求格式：
```json
{
  "command": "get_mod_list",
  "parameters": {}
}
```

响应格式：
```json
{
  "status": "success",
  "data": [
    {
      "name": "Mod名称",
      "enabled": true/false,
      "version": "版本号",
      "author": "作者"
    }
  ]
}
```

### get_mod_info
获取指定 mod 的详细信息。

请求格式：
```json
{
  "command": "get_mod_info",
  "parameters": {
    "ModName": "Mod名称"
  }
}
```

响应格式：
```json
{
  "status": "success",
  "data": {
    "name": "Mod名称",
    "enabled": true/false,
    "version": "版本号",
    "author": "作者"
  }
}
```

### enable_mod
启用指定的 mod。

请求格式：
```json
{
  "command": "enable_mod",
  "parameters": {
    "ModName": "Mod名称"
  }
}
```

响应格式：
```json
{
  "status": "success",
  "message": "Mod enabled successfully"
}
```

### disable_mod
禁用指定的 mod。

请求格式：
```json
{
  "command": "disable_mod",
  "parameters": {
    "ModName": "Mod名称"
  }
}
```

响应格式：
```json
{
  "status": "success",
  "message": "Mod disabled successfully"
}
```

## 客户端库使用示例

```python
from mod_manager_client import ModManagerClient

# 创建客户端
client = ModManagerClient()

# 测试连接
if client.test_connection():
    print("连接成功")
    
    # 获取 mod 列表
    mods = client.get_mod_list()
    for mod in mods:
        print(f"{mod['name']} - {'已启用' if mod['enabled'] else '已禁用'}")
    
    # 获取特定 mod 信息
    mod_info = client.get_mod_info("ModManagerBridge")
    if mod_info:
        print(f"Mod 信息: {mod_info}")
    
    # 启用 mod
    if client.enable_mod("DisplayTotalReward"):
        print("Mod 启用成功")
    
    # 禁用 mod
    if client.disable_mod("DisplayTotalReward"):
        print("Mod 禁用成功")
```

## 先决条件

- Python 3.x
- 游戏正在运行且 ModManagerBridge 已加载

## 注意事项

- ModManagerBridge 默认在端口 38274 上监听
- 如果需要更改端口，请相应修改脚本中的端口设置
- 确保防火墙没有阻止本地连接
- 启用/禁用 mod 后可能需要重新加载场景才能看到效果
- 所有 JSON 通信使用 `ModName` 参数名（首字母大写）

## 故障排除

### 连接被拒绝
- 确保 ModManagerBridge mod 已正确加载
- 检查游戏是否正在运行
- 确认端口 38274 没有被其他程序占用

### 命令执行失败
- 检查 JSON 格式是否正确
- 确认参数名称为 `ModName`（首字母大写）
- 查看游戏控制台日志获取详细错误信息

### 响应超时
- 增加客户端超时时间设置
- 检查网络连接是否正常
- 确认游戏没有卡顿或崩溃

## 开发说明

脚本已根据 DisplayItemValue mod 的 JSON 通信模式进行调整，确保使用一致的参数命名规范（`ModName` 而非 `modName`）。
