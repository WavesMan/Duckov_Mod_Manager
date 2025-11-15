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
    ws.connect("ws://localhost:9001")
    
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
    ws.connect("ws://localhost:9001")
    
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
    ws.connect("ws://localhost:9001")
    
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

### 重新扫描模组

```python
import websocket
import json

def rescan_mods():
    # 连接到 WebSocket 服务器
    ws = websocket.WebSocket()
    ws.connect("ws://localhost:9001")
    
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

## JavaScript 示例

### 使用浏览器 WebSocket API

```javascript
function getModList() {
    // 连接到 WebSocket 服务器
    const ws = new WebSocket("ws://localhost:9001");
    
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
        await ws.ConnectAsync(new Uri("ws://localhost:9001"), CancellationToken.None);
    }
    
    public async Task<string> SendRequestAsync(string action, string data)
    {
        var request = new
        {
            action = action,
            data = data
        };
        
        var json = JsonConvert.SerializeObject(request);
        var buffer = Encoding.UTF8.GetBytes(json);
        await ws.SendAsync(new ArraySegment<byte>(buffer), WebSocketMessageType.Text, true, CancellationToken.None);
        
        var responseBuffer = new byte[1024];
        var result = await ws.ReceiveAsync(new ArraySegment<byte>(responseBuffer), CancellationToken.None);
        var response = Encoding.UTF8.GetString(responseBuffer, 0, result.Count);
        
        return response;
    }
    
    public async Task DisconnectAsync()
    {
        await ws.CloseAsync(WebSocketCloseStatus.NormalClosure, "Closing", CancellationToken.None);
    }
    
    // 激活模组的便捷方法
    public async Task<string> ActivateModAsync(string modName)
    {
        // 使用 JsonConvert.SerializeObject 确保名称被引号包裹
        var quotedModName = JsonConvert.SerializeObject(modName);
        return await SendRequestAsync("activate_mod", quotedModName);
    }
    
    // 停用模组的便捷方法
    public async Task<string> DeactivateModAsync(string modName)
    {
        // 使用 JsonConvert.SerializeObject 确保名称被引号包裹
        var quotedModName = JsonConvert.SerializeObject(modName);
        return await SendRequestAsync("deactivate_mod", quotedModName);
    }
    
    // 批量激活模组的便捷方法
    public async Task<string> ActivateModsAsync(string[] modNames)
    {
        var jsonModNames = JsonConvert.SerializeObject(modNames);
        return await SendRequestAsync("activate_mods", jsonModNames);
    }
    
    // 批量停用模组的便捷方法
    public async Task<string> DeactivateModsAsync(string[] modNames)
    {
        var jsonModNames = JsonConvert.SerializeObject(modNames);
        return await SendRequestAsync("deactivate_mods", jsonModNames);
    }
}

// 使用示例
async Task Example()
{
    var client = new ModManagerBridgeClient();
    await client.ConnectAsync();
    
    var response = await client.SendRequestAsync("get_mod_list", "");
    var data = JsonConvert.DeserializeObject<dynamic>(response);
    
    if (data.success == true)
    {
        var mods = JsonConvert.DeserializeObject<dynamic>(data.data.ToString());
        Console.WriteLine($"找到 {mods.Count} 个模组:");
        foreach (var mod in mods)
        {
            Console.WriteLine($"- {mod.displayName} ({mod.isActive ? "已激活" : "未激活"})");
        }
    }
    else
    {
        Console.WriteLine($"错误: {data.message}");
    }
    
    // 激活模组示例
    var activateResponse = await client.ActivateModAsync("ExampleMod");
    Console.WriteLine($"激活响应: {activateResponse}");
    
    // 停用模组示例
    var deactivateResponse = await client.DeactivateModAsync("ExampleMod");
    Console.WriteLine($"停用响应: {deactivateResponse}");
    
    // 批量激活模组示例
    var activateModsResponse = await client.ActivateModsAsync(new string[] { "ExampleMod1", "ExampleMod2" });
    Console.WriteLine($"批量激活响应: {activateModsResponse}");
    
    // 批量停用模组示例
    var deactivateModsResponse = await client.DeactivateModsAsync(new string[] { "ExampleMod1", "ExampleMod2" });
    Console.WriteLine($"批量停用响应: {deactivateModsResponse}");
    
    await client.DisconnectAsync();
}
```

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