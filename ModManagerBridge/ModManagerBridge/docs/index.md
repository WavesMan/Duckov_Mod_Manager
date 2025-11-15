# ModManagerBridge API 文档

ModManagerBridge 是一个基于 WebSocket 的 API，允许外部应用程序与 Duckov 游戏的模组管理系统进行交互。它提供了对游戏模组的实时控制和监控功能。

## 概述

ModManagerBridge 在端口 9001 上公开了一个 WebSocket 服务器，外部应用程序可以连接该服务器来管理和监控游戏模组。该 API 支持各种操作，包括列出模组、激活/停用模组以及重新扫描新模组。

## 目录

- [WebSocket 连接](#websocket-connection)
- [API 参考](api.md)
- [使用示例](examples.md)
- [请求/响应格式](#requestresponse-format)
- [错误处理](#error-handling)

## WebSocket 连接

要连接到 ModManagerBridge API，请建立到以下地址的 WebSocket 连接：
```
ws://localhost:9001
```

服务器期望接收格式正确的 JSON 请求，并将返回 JSON 响应。

## 请求/响应格式

所有请求和响应都使用 JSON 格式。有关每个端点的详细信息，请参阅 [API 参考](api.md)。

### 请求格式
```json
{
  "action": "action_name",
  "data": "additional_data"
}
```

### 响应格式
```json
{
  "success": true,
  "message": "Optional message",
  "data": "Optional data"
}
```

## 使用示例

有关各种编程语言的详细示例，请参阅 [使用示例](examples.md)。

### Python 示例
```python
import websocket
import json

# 连接到 WebSocket 服务器
ws = websocket.WebSocket()
ws.connect("ws://localhost:9001")

# 发送获取模组列表的请求
request = {
    "action": "get_mod_list",
    "data": ""
}
ws.send(json.dumps(request))

# 接收响应
response = ws.recv()
data = json.loads(response)
print(data)

# 关闭连接
ws.close()
```

## 错误处理

所有响应都包含一个 `success` 字段，指示操作是否成功。如果操作失败，`message` 字段将包含有关错误的详细信息。

```json
{
  "success": false,
  "message": "Error description"
}
```