# ModManagerBridge API 参考

本文档提供了 ModManagerBridge 中所有可用 API 端点的详细信息。

## 基本信息

- **协议**: WebSocket
- **端口**: 9001
- **端点**: `ws://127.0.0.1:9001/`
 - **压缩**: 文本帧支持 `permessage-deflate`（服务端自动解压；握手不强制扩展协商）

## 通用数据结构

### ModInfo

表示模组的详细信息。

| 字段 | 类型 | 描述 |
|-------|------|-------------|
| name | string | 模组的内部名称 |
| displayName | string | 模组的显示名称 |
| description | string | 模组的描述 |
| path | string | 模组目录的文件路径 |
| isActive | boolean | 模组当前是否处于活动状态 |
| dllFound | boolean | 是否找到模组的 DLL 文件 |
| isSteamItem | boolean | 模组是否来自 Steam 创意工坊 |
| publishedFileId | number | Steam 创意工坊发布的文件 ID（如适用） |
| dllPath | string | 模组 DLL 文件的完整路径 |
| hasPreview | boolean | 模组是否有预览图像 |
| priority | number | 模组的加载优先级 |

### WebSocketRequest

所有发送到 API 的请求的结构。

| 字段 | 类型 | 描述 |
|-------|------|-------------|
| action | string | 要执行的操作 |
| data | string | 操作的附加数据（字符串）。批量操作请将数组先 JSON 序列化为字符串后传入 |

示例：
```json
{ "action": "activate_mods", "data": "[\"ExampleMod1\", \"ExampleMod2\"]" }
```

注意：
- 单项操作的数据直接传字符串，例如 `"ExampleMod"`
- 批量操作的数据为数组的 JSON 字符串，而不是数组对象本身

### WebSocketResponse

所有来自 API 的响应的结构。

| 字段 | 类型 | 描述 |
|-------|------|-------------|
| success | boolean | 请求是否成功 |
| message | string | 包含附加信息的可选消息 |
| data | string/object | 操作返回的可选数据 |

## API 端点

### 获取模组列表

检索所有已安装模组的详细信息列表。

**操作**: `get_mod_list`

**数据**: 无（空字符串）

**响应数据**: [ModInfo](#modinfo) 对象的 JSON 数组

**请求示例**:
```json
{
  "action": "get_mod_list",
  "data": ""
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "",
  "data": "[{\"name\":\"ExampleMod\",\"displayName\":\"Example Mod\",\"description\":\"An example mod\",\"path\":\"C:\\\\Mods\\\\ExampleMod\",\"isActive\":true,\"dllFound\":true,\"isSteamItem\":false,\"publishedFileId\":0,\"dllPath\":\"C:\\\\Mods\\\\ExampleMod\\\\ExampleMod.dll\",\"hasPreview\":false,\"priority\":0}]"
}
```

### 激活模组

按名称激活模组。

**操作**: `activate_mod`

**数据**: 要激活的模组名称

**响应数据**: 无

**请求示例**:
```json
{
  "action": "activate_mod",
  "data": "ExampleMod"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "Mod激活成功"
}
```

### 停用模组

按名称停用模组。

**操作**: `deactivate_mod`

**数据**: 要停用的模组名称

**响应数据**: 无

**请求示例**:
```json
{
  "action": "deactivate_mod",
  "data": "ExampleMod"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "Mod停用成功"
}
```

### 批量激活模组

按名称批量激活模组（最多10个）。

**操作**: `activate_mods`

**数据**: 要激活的模组名称数组（作为 JSON 字符串传入）

**响应数据**: 无

**请求示例**:
```json
{
  "action": "activate_mods",
  "data": "[\"ExampleMod1\", \"ExampleMod2\"]"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "success: 2/4.  true: 'mod1','mod2'; false: 'mod3','mod4'."
}
```

### 批量停用模组

按名称批量停用模组（最多10个）。

**操作**: `deactivate_mods`

**数据**: 要停用的模组名称数组（作为 JSON 字符串传入）

**响应数据**: 无

**请求示例**:
```json
{
  "action": "deactivate_mods",
  "data": "[\"ExampleMod1\", \"ExampleMod2\"]"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "success: 2/4.  true: 'mod1','mod2'; false: 'mod3','mod4'."
}
```

### 重新扫描模组

重新扫描模组目录以查找新的或更新的模组。

**操作**: `rescan_mods`

**数据**: 无（空字符串）

**响应数据**: 无

**请求示例**:
```json
{
  "action": "rescan_mods",
  "data": ""
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "Mods重新扫描成功"
}
```

## 错误响应

所有端点都可以返回以下格式的错误响应：

```json
{
  "success": false,
  "message": "Error description"
}
```

常见错误消息包括：
- "未知操作: [action_name]" - 提供了无效操作时
- "未找到mod: [mod_name]" - 尝试激活/停用不存在的模组时
- "无法激活mod" - 模组激活失败时
- "一次最多只能激活/停用10个mods" - 超过批量操作限制时