# ModManagerBridge API 接口规范

## 概述

ModManagerBridge 是一个基于 TCP 的 JSON-RPC 风格 API，用于在游戏运行时动态管理 mod。它允许外部程序通过简单的 JSON 命令与游戏中的 mod 系统进行交互。

## 基础信息

- **协议**: TCP
- **端口**: 38274 (默认)
- **地址**: 127.0.0.1 (本地回环)
- **数据格式**: JSON
- **编码**: UTF-8

## 请求格式

所有请求必须遵循以下 JSON 格式：

```json
{
  "command": "命令名称",
  "parameters": {
    "参数名": "参数值"
  }
}
```

### 请求字段说明

| 字段 | 类型 | 必需 | 说明 |
|------|------|------|------|
| command | string | 是 | 要执行的命令名称 |
| parameters | object | 否 | 命令参数，默认为空对象 |

## 响应格式

所有响应都遵循以下 JSON 格式：

```json
{
  "status": "success/error/failed",
  "message": "描述信息",
  "data": "响应数据"
}
```

### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| status | string | 执行状态：success(成功), error(错误), failed(失败) |
| message | string | 状态描述信息 |
| data | any | 响应数据，根据命令不同而变化 |

## 命令接口规范

### 1. get_mod_list - 获取 mod 列表

获取当前加载的所有 mod 及其状态信息。

**请求示例:**
```json
{
  "command": "get_mod_list",
  "parameters": {}
}
```

**响应示例:**
```json
{
  "status": "success",
  "message": "",
  "data": [
    {
      "name": "ModManagerBridge",
      "enabled": true,
      "version": "1.0.0",
      "author": "Unknown"
    },
    {
      "name": "DisplayTotalReward",
      "enabled": false,
      "version": "1.0.0",
      "author": "Unknown"
    }
  ]
}
```

**数据字段说明:**
- `name`: mod 名称 (string)
- `enabled`: 是否启用 (boolean)
- `version`: 版本号 (string)
- `author`: 作者信息 (string)

### 2. get_mod_info - 获取 mod 详细信息

获取指定 mod 的详细信息。

**请求示例:**
```json
{
  "command": "get_mod_info",
  "parameters": {
    "ModName": "ModManagerBridge"
  }
}
```

**参数说明:**
- `ModName`: 要查询的 mod 名称 (string, 必需)

**响应示例:**
```json
{
  "status": "success",
  "message": "",
  "data": {
    "name": "ModManagerBridge",
    "enabled": true,
    "version": "1.0.0",
    "author": "Unknown"
  }
}
```

### 3. enable_mod - 启用 mod

启用指定的 mod。

**请求示例:**
```json
{
  "command": "enable_mod",
  "parameters": {
    "ModName": "DisplayTotalReward"
  }
}
```

**参数说明:**
- `ModName`: 要启用的 mod 名称 (string, 必需)

**响应示例:**
```json
{
  "status": "success",
  "message": "Mod enabled successfully"
}
```

### 4. disable_mod - 禁用 mod

禁用指定的 mod。

**请求示例:**
```json
{
  "command": "disable_mod",
  "parameters": {
    "ModName": "DisplayTotalReward"
  }
}
```

**参数说明:**
- `ModName`: 要禁用的 mod 名称 (string, 必需)

**响应示例:**
```json
{
  "status": "success",
  "message": "Mod disabled successfully"
}
```

## 错误处理规范

### 错误状态码

| 状态码 | 说明 | 可能原因 |
|--------|------|----------|
| success | 命令执行成功 | - |
| error | 命令执行错误 | 参数错误、命令不存在等 |
| failed | 命令执行失败 | mod 操作失败等 |

### 常见错误响应

**未知命令错误:**
```json
{
  "status": "error",
  "message": "Unknown command"
}
```

**参数缺失错误:**
```json
{
  "status": "error",
  "message": "Missing required parameter: ModName"
}
```

**mod 不存在错误:**
```json
{
  "status": "failed",
  "message": "Mod not found: InvalidModName"
}
```

**mod 操作失败:**
```json
{
  "status": "failed",
  "message": "Failed to enable mod: DisplayTotalReward"
}
```

## 客户端实现规范

### Python 客户端接口

```python
class ModManagerBridgeClient:
    def __init__(self, host='127.0.0.1', port=38274, timeout=5):
        self.host = host
        self.port = port
        self.timeout = timeout
    
    def send_command(self, command: str, parameters: dict = None) -> dict:
        """发送命令到 ModManagerBridge"""
        pass
    
    def get_mod_list(self) -> list:
        """获取 mod 列表"""
        pass
    
    def get_mod_info(self, mod_name: str) -> dict:
        """获取 mod 信息"""
        pass
    
    def enable_mod(self, mod_name: str) -> bool:
        """启用 mod"""
        pass
    
    def disable_mod(self, mod_name: str) -> bool:
        """禁用 mod"""
        pass
```

### 连接管理

- 客户端应使用 TCP socket 连接
- 连接超时时间建议设置为 5 秒
- 每次命令发送后应等待响应
- 连接异常时应进行重试或错误处理

### 数据验证

- 验证 JSON 格式是否正确
- 检查必需参数是否存在
- 验证响应状态码
- 处理网络超时和连接错误

## 安全考虑

1. **本地访问**: API 仅监听本地回环地址 (127.0.0.1)
2. **无认证**: 由于是本地通信，不包含认证机制
3. **参数验证**: 服务端应对所有输入参数进行验证
4. **错误处理**: 客户端应妥善处理各种异常情况

## 性能建议

1. **连接复用**: 建议复用 TCP 连接而不是频繁创建新连接
2. **批量操作**: 避免短时间内发送大量命令
3. **超时设置**: 合理设置连接和读取超时时间
4. **错误重试**: 对于临时性错误可进行有限次重试

## 扩展性设计

### 未来可能的扩展命令

```json
// 重新加载所有 mod
{
  "command": "reload_all_mods",
  "parameters": {}
}

// 获取 mod 配置
{
  "command": "get_mod_config",
  "parameters": {
    "ModName": "ExampleMod"
  }
}

// 设置 mod 配置
{
  "command": "set_mod_config",
  "parameters": {
    "ModName": "ExampleMod",
    "config": {
      "key": "value"
    }
  }
}
```

## 兼容性说明

- 所有参数名称使用 PascalCase 命名规范
- JSON 字段使用双引号
- 字符串编码使用 UTF-8
- 布尔值使用 true/false 小写形式

## 示例代码

### Python 完整示例

```python
import socket
import json

class ModManagerBridge:
    def __init__(self, host='127.0.0.1', port=38274):
        self.host = host
        self.port = port
    
    def call(self, command, parameters=None):
        """调用 ModManagerBridge API"""
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
                sock.settimeout(5)
                sock.connect((self.host, self.port))
                
                request = {
                    "command": command,
                    "parameters": parameters or {}
                }
                
                sock.send(json.dumps(request).encode('utf-8'))
                response = sock.recv(4096).decode('utf-8')
                return json.loads(response)
                
        except Exception as e:
            return {
                "status": "error",
                "message": f"Connection failed: {str(e)}"
            }
    
    def get_mods(self):
        """获取所有 mod"""
        response = self.call("get_mod_list")
        if response.get("status") == "success":
            return response.get("data", [])
        return []
    
    def enable_mod(self, mod_name):
        """启用 mod"""
        response = self.call("enable_mod", {"ModName": mod_name})
        return response.get("status") == "success"
```

这个规范文档为 ModManagerBridge 提供了完整的 API 接口定义和使用指南。
