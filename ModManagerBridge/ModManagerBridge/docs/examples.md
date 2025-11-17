# ModManagerBridge 使用示例

本文档提供了如何在各种编程语言中使用 ModManagerBridge API 的实际示例。

## Python 示例

### 基本连接和模组列表获取

```python
import websocket
import json

def get_mod_list():
    # 连接到 WebSocket 服务器
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    
    # 发送获取模组列表的请求
    request = {
        "action": "get_mod_list",
        "data": ""
    }
    ws.send(json.dumps(request))
    
    # 接收并解析响应
    response = ws.recv()
    data = json.loads(response)
    
    if data["success"]:
        # 解析模组列表（数据字段中的 JSON 字符串）
        mods = json.loads(data["data"])
        print(f"找到 {len(mods)} 个模组:")
        for mod in mods:
            print(f"- {mod['displayName']} ({'已激活' if mod['isActive'] else '未激活'})")
    else:
        print(f"错误: {data['message']}")
    
    # 关闭连接
    ws.close()

# 运行函数
get_mod_list()
```

### 模组激活/停用

```python
import websocket
import json

def toggle_mod(mod_name, activate=True):
    # 连接到 WebSocket 服务器
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    
    # 发送激活/停用模组的请求
    action = "activate_mod" if activate else "deactivate_mod"
    request = {
        "action": action,
        "data": json.dumps(mod_name)  # 使用json.dumps确保名称被引号包裹
    }
    ws.send(json.dumps(request))
    
    # 接收并解析响应
    response = ws.recv()
    data = json.loads(response)
    
    if data["success"]:
        status = "激活" if activate else "停用"
        print(f"模组 '{mod_name}' {status} 成功")
    else:
        print(f"错误: {data['message']}")
    
    # 关闭连接
    ws.close()

# 使用示例
toggle_mod("ExampleMod", activate=True)   # 激活模组
toggle_mod("ExampleMod", activate=False)  # 停用模组
```

### 批量模组激活/停用

```python
import websocket
import json

def toggle_mods(mod_names, activate=True):
    # 连接到 WebSocket 服务器
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    
    # 发送批量激活/停用模组的请求
    action = "activate_mods" if activate else "deactivate_mods"
    request = {
        "action": action,
        "data": json.dumps(mod_names)  # mod名称数组
    }
    ws.send(json.dumps(request))
    
    # 接收并解析响应
    response = ws.recv()
    data = json.loads(response)
    
    if data["success"]:
        status = "激活" if activate else "停用"
        print(f"模组批量{status}成功: {data['message']}")
    else:
        print(f"错误: {data['message']}")
    
    # 关闭连接
    ws.close()

# 使用示例
toggle_mods(["ExampleMod1", "ExampleMod2", "ExampleMod3"], activate=True)   # 批量激活模组
toggle_mods(["ExampleMod1", "ExampleMod2", "ExampleMod3"], activate=False)  # 批量停用模组
```

### 订阅事件推送

```python
import websocket
import json

def listen_events():
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    try:
        while True:
            raw = ws.recv()
            msg = json.loads(raw)
            if "type" in msg:
                t = msg["type"]
                data = msg.get("data", {})
                print("事件:", t, data)
            else:
                print("响应:", msg)
    finally:
        ws.close()

listen_events()
```

### 设置优先级与重排顺序

```python
import websocket
import json

def set_priority(mod_name, priority):
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    request = {
        "action": "set_priority",
        "data": f"{mod_name}:{priority}"
    }
    ws.send(json.dumps(request))
    response = json.loads(ws.recv())
    print(response)
    ws.close()

def reorder_mods(order_names):
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    request = {
        "action": "reorder_mods",
        "data": json.dumps(order_names)
    }
    ws.send(json.dumps(request))
    response = json.loads(ws.recv())
    print(response)
    ws.close()

def apply_order_and_rescan(order_names):
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    request = {
        "action": "apply_order_and_rescan",
        "data": json.dumps(order_names)
    }
    ws.send(json.dumps(request))
    response = json.loads(ws.recv())
    print(response)
    ws.close()

# 使用示例
set_priority("ExampleMod", 3)
reorder_mods(["CoreTweaks", "ExampleMod", "UIFix"])  # 批量重排
apply_order_and_rescan(["CoreTweaks", "ExampleMod", "UIFix"])  # 应用并重新激活
```

### 重新扫描模组

```python
import websocket
import json

def rescan_mods():
    # 连接到 WebSocket 服务器
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    
    # 发送重新扫描模组的请求
    request = {
        "action": "rescan_mods",
        "data": ""
    }
    ws.send(json.dumps(request))
    
    # 接收并解析响应
    response = ws.recv()
    data = json.loads(response)
    
    if data["success"]:
        print("模组重新扫描成功")
    else:
        print(f"错误: {data['message']}")
    
    # 关闭连接
    ws.close()

# 运行函数
rescan_mods()
```

### 速率错误处理示例（Python）

```python
import websocket, json, time

def activate_many(mods):
    ws = websocket.WebSocket()
    ws.connect("ws://127.0.0.1:9001/")
    ws.send(json.dumps({"action":"activate_mods","data":json.dumps(mods)}))
    msg = json.loads(ws.recv())
    if (not msg.get("success", True)) and str(msg.get("message"," ")).startswith("rate_limit_exceeded:"):
        print("速率超限:", msg["message"], "1s后重试")
        time.sleep(1)
        ws.close()
        return activate_many(mods)
    print(msg)
    ws.close()
```

## JavaScript 示例

### 使用浏览器 WebSocket API

```javascript
function getModList() {
    // 连接到 WebSocket 服务器
    const ws = new WebSocket("ws://127.0.0.1:9001/");
    
    ws.onopen = function() {
        // 发送获取模组列表的请求
        const request = {
            action: "get_mod_list",
            data: ""
        };
        ws.send(JSON.stringify(request));
    };
    
    ws.onmessage = function(event) {
        const data = JSON.parse(event.data);
        
        if (data.success) {
            // 解析模组列表（数据字段中的 JSON 字符串）
            const mods = JSON.parse(data.data);
            console.log(`找到 ${mods.length} 个模组:`);
            mods.forEach(mod => {
                console.log(`- ${mod.displayName} (${mod.isActive ? '已激活' : '未激活'})`);
            });
        } else {
            console.error(`错误: ${data.message}`);
        }
        
        // 关闭连接
        ws.close();
    };
    
    ws.onerror = function(error) {
        console.error("WebSocket 错误:", error);
    };
}

// 运行函数
getModList();
```

### 顺序控制示例

```javascript
function reorderMods(orderNames) {
  const ws = new WebSocket("ws://127.0.0.1:9001/");
  ws.onopen = function() {
    const request = {
      action: "reorder_mods",
      data: JSON.stringify(orderNames)
    };
    ws.send(JSON.stringify(request));
  };
  ws.onmessage = function(event) {
    console.log("响应:", event.data);
    ws.close();
  };
}

function applyOrderAndRescan(orderNames) {
  const ws = new WebSocket("ws://127.0.0.1:9001/");
  ws.onopen = function() {
    const request = {
      action: "apply_order_and_rescan",
      data: JSON.stringify(orderNames)
    };
    ws.send(JSON.stringify(request));
  };
  ws.onmessage = function(event) {
    console.log("响应:", event.data);
    ws.close();
  };
}

// 使用示例
reorderMods(["CoreTweaks", "ExampleMod", "UIFix"]);
applyOrderAndRescan(["CoreTweaks", "ExampleMod", "UIFix"]);
```

### 订阅事件推送

```javascript
function connectAndListen() {
  const ws = new WebSocket("ws://127.0.0.1:9001/");
  ws.onopen = function() {
    console.log("连接已建立");
  };
  ws.onmessage = function(event) {
    const msg = JSON.parse(event.data);
    if (msg.type) {
      switch (msg.type) {
        case "scan":
          console.log("扫描完成", msg.data.mods);
          break;
        case "reorder":
          console.log("顺序变更", msg.data.names, msg.data.priorities);
          break;
        case "mod_activated":
          console.log("激活", msg.data.name);
          break;
        case "mod_deactivated":
          console.log("停用", msg.data.name);
          break;
        case "status_changed":
          console.log("状态变更，激活数:", msg.data.active);
          break;
        default:
          console.log("未知事件", msg);
      }
    } else {
      console.log("响应", msg);
    }
  };
}

connectAndListen();
```

### 速率错误处理示例（JavaScript）

```javascript
function activateMany(mods) {
  const ws = new WebSocket("ws://127.0.0.1:9001/");
  ws.onopen = function() {
    const req = { action: "activate_mods", data: JSON.stringify(mods) };
    ws.send(JSON.stringify(req));
  };
  ws.onmessage = function(event) {
    const msg = JSON.parse(event.data);
    if (msg.success === false && String(msg.message).startsWith("rate_limit_exceeded:")) {
      console.warn("速率超限:", msg.message, "将延迟重试");
      setTimeout(() => activateMany(mods), 1000);
    } else {
      console.log("响应:", msg);
      ws.close();
    }
  };
}
```

## C# 示例

### 使用 System.Net.WebSockets

```csharp
using System;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Newtonsoft.Json;

public class ModManagerBridgeClient
{
    private ClientWebSocket ws;

    public async Task ConnectAsync()
    {
        ws = new ClientWebSocket();
        await ws.ConnectAsync(new Uri("ws://127.0.0.1:9001/"), CancellationToken.None);
    }

    public async Task<string> SendRequestAsync(string action, string data)
    {
        var request = new { action = action, data = data };
        var json = JsonConvert.SerializeObject(request);
        var buffer = Encoding.UTF8.GetBytes(json);
        await ws.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
        var responseBuffer = new byte[4096];
        var result = await ws.ReceiveAsync(new ArraySegment<byte>(responseBuffer), CancellationToken.None);
        return Encoding.UTF8.GetString(responseBuffer, 0, result.Count);
    }

    public async Task CloseAsync()
    {
        if (ws != null && ws.State == WebSocketState.Open)
            await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
        ws?.Dispose();
    }
}

// 使用示例
// var client = new ModManagerBridgeClient();
// await client.ConnectAsync();
// var resp = await client.SendRequestAsync("get_mod_list", "");
// await client.CloseAsync();
```

## Dart 示例

### 使用 dart:io WebSocket

```dart
import 'dart:convert';
import 'dart:io';

Future<WebSocket> connectBridge() async {
  final uri = Uri.parse('ws://127.0.0.1:9001/');
  final ws = await WebSocket.connect(
    uri.toString(),
    headers: {
      'Origin': 'http://localhost',
    },
  );
  ws.pingInterval = const Duration(seconds: 20);
  return ws;
}

void sendGetModList(WebSocket ws) {
  ws.add(jsonEncode({'action': 'get_mod_list', 'data': ''}));
}

void sendActivateMod(WebSocket ws, String name) {
  ws.add(jsonEncode({'action': 'activate_mod', 'data': name}));
}

void sendActivateMods(WebSocket ws, List<String> names) {
  final arr = jsonEncode(names); // 将数组序列化为字符串
  ws.add(jsonEncode({'action': 'activate_mods', 'data': arr}));
}

void sendDeactivateMods(WebSocket ws, List<String> names) {
  final arr = jsonEncode(names);
  ws.add(jsonEncode({'action': 'deactivate_mods', 'data': arr}));
}

void sendReorder(WebSocket ws, List<String> orderNames) {
  final arr = jsonEncode(orderNames);
  ws.add(jsonEncode({'action': 'reorder_mods', 'data': arr}));
}

void sendApplyOrderAndRescan(WebSocket ws, List<String> orderNames) {
  final arr = jsonEncode(orderNames);
  ws.add(jsonEncode({'action': 'apply_order_and_rescan', 'data': arr}));
}

Future<void> example() async {
  final ws = await connectBridge();
  sendGetModList(ws);
  ws.listen((data) {
    print('响应: $data');
    ws.close();
  }, onError: (e) {
    print('错误: $e');
  });
}
```

说明：
- Dart 客户端默认可能开启 `permessage-deflate` 压缩；服务端会自动解压文本帧，无需额外配置
- 批量操作时将 `List<String>` 经 `jsonEncode` 后放入 `data`


## 错误处理示例

### Python 错误处理

```python
import websocket
import json

def safe_mod_operation(action, data):
    try:
        # 连接到 WebSocket 服务器
        ws = websocket.WebSocket()
        ws.connect("ws://localhost:9001")
        
        # 发送请求
        request = {
            "action": action,
            "data": data
        }
        ws.send(json.dumps(request))
        
        # 接收并解析响应
        response = ws.recv()
        data = json.loads(response)
        
        # 处理响应
        if data["success"]:
            print("操作成功")
            if "data" in data and data["data"]:
                # 如果存在数据则处理
                try:
                    result_data = json.loads(data["data"])
                    return result_data
                except json.JSONDecodeError:
                    # 数据不是 JSON，按原样返回
                    return data["data"]
        else:
            print(f"操作失败: {data['message']}")
            return None
            
    except websocket.WebSocketException as e:
        print(f"WebSocket 错误: {e}")
        return None
    except json.JSONDecodeError as e:
        print(f"JSON 解析错误: {e}")
        return None
    except Exception as e:
        print(f"意外错误: {e}")
        return None
    finally:
        # 确保连接已关闭
        try:
            ws.close()
        except:
            pass

# 使用示例
mods = safe_mod_operation("get_mod_list", "")
if mods is not None:
    print(f"检索到 {len(mods)} 个模组")
```

这些示例演示了 ModManagerBridge API 的常见使用模式。请记住在您的应用程序中适当处理错误，并确保正确关闭 WebSocket 连接。

### C# 示例

```csharp
using System;
using System.Net.WebSockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Collections.Generic;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

public class ModManagerBridgeClient
{
    private readonly ClientWebSocket ws = new ClientWebSocket();

    public async Task ConnectAsync()
    {
        await ws.ConnectAsync(new Uri("ws://127.0.0.1:9001/"), CancellationToken.None);
    }

    private async Task<string> SendAsync(string json)
    {
        var buffer = Encoding.UTF8.GetBytes(json);
        await ws.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
        var recvBuffer = new byte[8192];
        var result = await ws.ReceiveAsync(new ArraySegment<byte>(recvBuffer), CancellationToken.None);
        return Encoding.UTF8.GetString(recvBuffer, 0, result.Count);
    }

    public async Task<JObject> RequestAsync(string action, object data)
    {
        var payload = new JObject
        {
            ["action"] = action,
            ["data"] = data is string ? JToken.FromObject(data) : JToken.FromObject(data)
        };
        var respText = await SendAsync(payload.ToString(Formatting.None));
        var resp = JObject.Parse(respText);
        if (!(resp.Value<bool?>("success") ?? true))
        {
            var msg = resp.Value<string>("message") ?? "";
            if (msg.StartsWith("rate_limit_exceeded:"))
            {
                await Task.Delay(1000);
                return await RequestAsync(action, data);
            }
        }
        return resp;
    }

    public async Task<List<string>> GetModsAsync()
    {
        var r = await RequestAsync("get_mod_list", "");
        var dataText = r.Value<string>("data");
        if (string.IsNullOrEmpty(dataText)) return new List<string>();
        return JsonConvert.DeserializeObject<List<string>>(dataText);
    }

    public async Task<JObject> ActivateModsAsync(IEnumerable<string> mods)
    {
        var data = JsonConvert.SerializeObject(mods);
        return await RequestAsync("activate_mods", data);
    }

    public async Task<JObject> DeactivateModsAsync(IEnumerable<string> mods)
    {
        var data = JsonConvert.SerializeObject(mods);
        return await RequestAsync("deactivate_mods", data);
    }

    public async Task CloseAsync()
    {
        if (ws.State == WebSocketState.Open)
            await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "close", CancellationToken.None);
        ws.Dispose();
    }
}
```