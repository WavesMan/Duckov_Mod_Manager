# ModManagerBridge API 文档

ModManagerBridge 是一个基于 WebSocket 的 API，允许外部应用程序与 Duckov 游戏的模组管理系统进行交互。它提供了对游戏模组的实时控制和监控功能。

## 概述

ModManagerBridge 在端口 9001 上公开了一个 WebSocket 服务器，外部应用程序可以连接该服务器来管理和监控游戏模组。该 API 支持各种操作，包括列出模组、激活/停用模组、重新扫描新模组，以及顺序控制（设置优先级、批量重排、应用顺序并统一激活）。此外，服务端支持“事件推送”，在扫描、重排、激活/停用和状态变化时主动广播变更，降低客户端轮询成本；并提供“速率限制”，保障服务端稳定性与吞吐的可控性。

## 目录

- [ModManagerBridge API 文档](#modmanagerbridge-api-文档)
  - [概述](#概述)
  - [目录](#目录)
  - [WebSocket 连接](#websocket-连接)
    - [握手说明](#握手说明)
    - [压缩帧支持](#压缩帧支持)
  - [请求/响应格式](#请求响应格式)
    - [请求格式](#请求格式)
    - [响应格式](#响应格式)
  - [使用示例](#使用示例)
    - [Python 示例](#python-示例)
  - [错误处理](#错误处理)
  - [故障排查](#故障排查)
  - [顺序控制说明](#顺序控制说明)
  - [事件推送](#事件推送)
  - [速率限制](#速率限制)

## WebSocket 连接

要连接到 ModManagerBridge API，请建立到以下地址的 WebSocket 连接：
```
ws://127.0.0.1:9001/
```

兼容性建议：
- 使用 IPv4 地址 `127.0.0.1`（避免 `localhost` 解析为 IPv6）
- 末尾包含根路径 `/`（部分客户端在无路径时行为不一致）
- 使用现代标准 WebSocket 客户端（浏览器、Dart、.NET）

### 握手说明
- 服务端读取完整 HTTP 头（直到 `\r\n\r\n`），并大小写不敏感解析关键字段
- 关键头包括：`Connection: Upgrade`、`Upgrade: websocket`、`Sec-WebSocket-Version: 13`、`Sec-WebSocket-Key`
- 兼容模式：若缺少 `Sec-WebSocket-Key`，服务端会生成随机键完成握手（不用于认证），标准客户端不受影响
 - 日志中的“握手警告，Upgrade/Connection 头异常”用于提示头部异常但不影响建立连接

### 压缩帧支持
- 服务端在帧层兼容 `permessage-deflate` 文本压缩：当收到启用压缩的文本帧（`RSV1` 置位）时，会自动解压并按 UTF-8 解析
- 该兼容为透明行为，握手阶段不强制扩展协商；标准与 Dart 客户端均可正常收发

服务器期望接收格式正确的 JSON 请求，并将返回 JSON 响应。

## 请求/响应格式

所有请求和响应都使用 JSON 格式。有关每个端点的详细信息，请参阅 [API 参考](api.md)。

注意：`data` 字段为字符串类型；当需要传递数组（如批量操作）时，请将数组先 `JSON` 序列化为字符串再放入 `data`。

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
ws.connect("ws://127.0.0.1:9001/")

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

## 故障排查

- 端口监听：Windows 使用 `netstat -ano | findstr 9001`
- 连接失败：检查是否使用 `ws://127.0.0.1:9001/`，以及防火墙与端口占用
- 批量操作：确保将数组 `JSON` 序列化为字符串放入 `data`
- 请求乱码：若服务端日志显示不可读字符，确认客户端未发送二进制帧；压缩文本帧已自动解压

## 顺序控制说明

- 激活顺序语义：按 `ActivateMod` 的调用顺序生效，覆盖型行为为“后写覆盖先写”。
- 重排不重激活：仅修改优先级不会重启已激活 MOD；`apply_order_and_rescan` 仅对未激活的 MOD 执行激活。
- 推荐工作流：
  - 批量停用受顺序影响的 MOD → 设置优先级 → `apply_order_and_rescan` 统一激活
  - 或按新顺序逐一调用 `activate_mod`，使调用顺序等于激活顺序
- 全量重排要求：`reorder_mods` 只重排传入的名称；未列出的 MOD 保留旧优先级。需要全量确定性顺序时，请传入“所有 MOD 名称”的完整数组。
- 详见 [API 参考](api.md) 与 [使用示例](examples.md)

## 事件推送

- 推送格式：`{"type":"<事件类型>","data":{...}}`
- 事件类型：`scan`、`reorder`、`mod_activated`、`mod_deactivated`、`status_changed`
- 使用方式：客户端在 `onmessage` 回调中解析 JSON，若包含 `type` 则按事件类型分发处理；否则按响应对象处理
- 事件数据：详见 [API 参考](api.md) 的“事件推送协议”章节

## 速率限制

- 限制维度：每连接 `requests_per_second`；批量项 `items_per_second`
- 默认阈值：`requests_per_second`=20、`items_per_second`=50
- 超限行为：请求速率超限返回错误 `rate_limit_exceeded: requests_per_second`；批量项按秒级节流，耗时增加但不报错
- 建议：客户端进行批次控制或退避重试；详见 [API 参考](api.md)