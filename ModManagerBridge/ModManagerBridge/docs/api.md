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

按名称批量激活模组（不限制数量）。

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

按名称批量停用模组（不限制数量）。

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

### 设置单个模组优先级

设置指定模组的加载优先级，并立即重新扫描。

**操作**: `set_priority`

**数据**: 形如 `"ModName:Priority"` 的字符串（例如：`"ExampleMod:3"`）

**响应数据**: 无

**请求示例**:
```json
{
  "action": "set_priority",
  "data": "ExampleMod:3"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "优先级已设置并重新扫描"
}
```

### 批量重排模组顺序

按提供的名称数组设置整体优先级顺序（数组索引为优先级），完成后重新扫描。

**操作**: `reorder_mods`

**数据**: 模组名称数组的 JSON 字符串（按期望顺序排列）

**响应数据**: 无

**请求示例**:
```json
{
  "action": "reorder_mods",
  "data": "[\"CoreTweaks\", \"ExampleMod\", \"UIFix\"]"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "success: 3/3. true: 'CoreTweaks','ExampleMod','UIFix'."
}
```

### 应用顺序并重新扫描与激活

一次性应用整体顺序，重新扫描，并在允许激活的前提下触发统一激活以保证运行期与持久化顺序一致。

**操作**: `apply_order_and_rescan`

**数据**: 模组名称数组的 JSON 字符串（按期望顺序排列）

**响应数据**: 无

**请求示例**:
```json
{
  "action": "apply_order_and_rescan",
  "data": "[\"CoreTweaks\", \"ExampleMod\", \"UIFix\"]"
}
```

**响应示例**:
```json
{
  "success": true,
  "message": "applied: 3/3. true: 'CoreTweaks','ExampleMod','UIFix'."
}
```

### 顺序与激活要求

- 激活顺序：严格由 `ActivateMod` 的调用顺序决定，覆盖型行为遵循“后写覆盖先写”。
- 重新排序不重激活：单纯修改优先级不会对已激活 MOD 进行重启；`apply_order_and_rescan` 仅激活尚未激活的 MOD。
- 推荐流程：
  - 受顺序影响的 MOD：先批量停用 → 设置优先级 → 通过 `apply_order_and_rescan` 统一激活
  - 或按新顺序逐一调用 `activate_mod`，确保调用顺序即激活顺序
- 全量确定性：`reorder_mods` 只重排传入的名称；未列出的 MOD 保留旧优先级。若需全量确定性顺序，请传入“所有 MOD 名称”的完整数组。

### 事件推送协议

服务端在连接存活期间会主动推送变更事件，以降低客户端轮询成本。事件统一采用如下格式：

```json
{"type":"<事件类型>","data":{...}}
```

可用事件：
- `scan`：重新扫描完成
  - `data.mods`：数组，元素包含 `name`、`priority`
- `reorder`：顺序发生变更
  - `data.names`：按当前顺序排列的名称数组
  - `data.priorities`：名称到优先级的映射对象
- `mod_activated`：某模组被激活
  - `data.name`：模组名称
- `mod_deactivated`：某模组被停用
  - `data.name`：模组名称
- `status_changed`：激活状态发生变化（摘要）
  - `data.active`：当前激活中的模组数量

客户端在接收消息时，应区分“响应对象”（包含 `success` 字段）与“事件对象”（包含 `type` 字段）。
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
- "优先级解析失败" - `set_priority` 的数据格式不正确时

## 速率限制说明

- 限制维度：
  - 每连接 `requests_per_second`（请求速率）
  - 批量项 `items_per_second`（批量处理节流）
- 默认阈值：
  - `requests_per_second` = 20
  - `items_per_second` = 50
- 超限行为：
  - 请求速率超限：立即返回错误
    - 示例：`{"success":false,"message":"rate_limit_exceeded: requests_per_second"}`
  - 批量项超出节流阈值：服务端按秒级节流处理，整体耗时增加但不报错
- 客户端建议：大批量操作可拆分批次或采用退避策略；UI 展示可能的耗时增加提示