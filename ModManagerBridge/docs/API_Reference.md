# Mod Manager Bridge API 参考文档

## 概述

Mod Manager Bridge API 提供基于 WebSocket 的完整接口，用于远程管理 Duckov 模组。该 API 通过 WebSocket 连接遵循 RESTful 原则，并使用 HMAC-SHA256 实现安全认证。

## 连接详情

### WebSocket 端点
```
ws://127.0.0.1:8765/mods
```

### 子协议
```
duckov-mods-v1
```

### 连接头信息
```http
GET /mods HTTP/1.1
Host: 127.0.0.1:8765
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: <base64编码密钥>
Sec-WebSocket-Version: 13
Sec-WebSocket-Protocol: duckov-mods-v1
```

## 认证流程

### 1. Hello 交换
**客户端请求：**
```json
{
  "type": "request",
  "action": "hello",
  "id": "唯一请求ID",
  "data": {
    "client_id": "客户端标识符",
    "version": "1.0.0",
    "capabilities": ["read_mods", "manage_activation", "manage_priority", "manage_settings"]
  }
}
```

**服务器响应：**
```json
{
  "type": "response",
  "action": "hello",
  "id": "唯一请求ID",
  "data": {
    "server_version": "1.0.0",
    "protocol_version": "1.0.0",
    "nonce": "服务器生成的随机数"
  }
}
```

### 2. 认证
**客户端请求：**
```json
{
  "type": "request",
  "action": "auth",
  "id": "唯一请求ID",
  "data": {
    "client_id": "客户端标识符",
    "nonce": "服务器生成的随机数",
    "timestamp": 1731540000,
    "hmac": "hmac-sha256签名"
  }
}
```

**服务器响应：**
```json
{
  "type": "response",
  "action": "auth",
  "id": "唯一请求ID",
  "data": {
    "ok": true,
    "permissions": ["read_mods", "manage_activation"]
  }
}
```

## 核心操作

### 模组管理

#### 扫描模组
发现 Duckov 模组目录中的所有可用模组。

**请求：**
```json
{
  "type": "request",
  "action": "scan_mods",
  "id": "scan-request-123"
}
```

**响应：**
```json
{
  "type": "response",
  "action": "scan_mods",
  "id": "scan-request-123",
  "data": {
    "mods": [
      {
        "name": "ExampleMod",
        "displayName": "示例模组",
        "description": "用于演示的示例模组",
        "dllPath": "Mods/ExampleMod/ExampleMod.dll",
        "preview": "base64编码的图像数据",
        "publishedFileId": 0,
        "folderPath": "Mods/ExampleMod",
        "active": false,
        "priority": 0
      }
    ],
    "count": 1
  }
}
```

#### 获取模组
检索当前模组状态和配置。

**请求：**
```json
{
  "type": "request",
  "action": "get_mods",
  "id": "get-mods-request-456"
}
```

**响应：**
```json
{
  "type": "response",
  "action": "get_mods",
  "id": "get-mods-request-456",
  "data": {
    "mods": [
      {
        "name": "ExampleMod",
        "displayName": "示例模组",
        "description": "示例模组",
        "active": true,
        "priority": 1,
        "dependencies": [],
        "conflicts": [],
        "loadOrder": 1
      }
    ],
    "allowLoading": true,
    "totalCount": 1,
    "activeCount": 1
  }
}
```

#### 激活模组
激活特定模组。

**请求：**
```json
{
  "type": "request",
  "action": "activate_mod",
  "id": "activate-request-789",
  "data": {
    "name": "ExampleMod",
    "priority": 1
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "activate_mod",
  "id": "activate-request-789",
  "data": {
    "status": "ok",
    "modName": "ExampleMod",
    "message": "模组激活成功"
  }
}
```

#### 停用模组
停用特定模组。

**请求：**
```json
{
  "type": "request",
  "action": "deactivate_mod",
  "id": "deactivate-request-012",
  "data": {
    "name": "ExampleMod"
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "deactivate_mod",
  "id": "deactivate-request-012",
  "data": {
    "status": "ok",
    "modName": "ExampleMod",
    "message": "模组停用成功"
  }
}
```

### 批量操作

#### 批量激活
在单个操作中激活多个模组。

**请求：**
```json
{
  "type": "request",
  "action": "batch_activate",
  "id": "batch-activate-request-345",
  "data": {
    "mods": [
      { "name": "Mod1", "priority": 1 },
      { "name": "Mod2", "priority": 2 }
    ],
    "continueOnError": true
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "batch_activate",
  "id": "batch-activate-request-345",
  "data": {
    "status": "partial",
    "results": [
      { "name": "Mod1", "success": true, "message": "已激活" },
      { "name": "Mod2", "success": false, "error": "缺少依赖项" }
    ],
    "successCount": 1,
    "failureCount": 1
  }
}
```

### 优先级管理

#### 设置优先级
更改模组优先级/加载顺序。

**请求：**
```json
{
  "type": "request",
  "action": "set_priority",
  "id": "priority-request-678",
  "data": {
    "name": "ExampleMod",
    "priority": 5
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "set_priority",
  "id": "priority-request-678",
  "data": {
    "status": "ok",
    "modName": "ExampleMod",
    "oldPriority": 1,
    "newPriority": 5
  }
}
```

### 配置管理

#### 获取设置
检索系统设置。

**请求：**
```json
{
  "type": "request",
  "action": "get_settings",
  "id": "settings-request-901"
}
```

**响应：**
```json
{
  "type": "response",
  "action": "get_settings",
  "id": "settings-request-901",
  "data": {
    "allowLoading": true,
    "maxConcurrentOperations": 4,
    "operationTimeout": 3000,
    "retryAttempts": 3,
    "batchSize": 50
  }
}
```

#### 设置允许加载
全局启用/禁用模组加载系统。

**请求：**
```json
{
  "type": "request",
  "action": "set_allow_loading",
  "id": "allow-loading-request-234",
  "data": {
    "allow": false
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "set_allow_loading",
  "id": "allow-loading-request-234",
  "data": {
    "status": "ok",
    "allowLoading": false,
    "message": "模组加载已禁用"
  }
}
```

## 依赖和冲突管理

### 检查依赖项
分析模组依赖项和冲突。

**请求：**
```json
{
  "type": "request",
  "action": "check_dependencies",
  "id": "deps-request-567",
  "data": {
    "name": "ComplexMod"
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "check_dependencies",
  "id": "deps-request-567",
  "data": {
    "modName": "ComplexMod",
    "dependencies": [
      { "name": "BaseMod", "required": true, "available": true, "active": true },
      { "name": "UtilsMod", "required": false, "available": true, "active": false }
    ],
    "conflicts": [
      { "name": "IncompatibleMod", "severity": "high", "description": "功能重叠" }
    ],
    "canActivate": false,
    "issues": ["缺少必需依赖项: UtilsMod"]
  }
}
```

### 解决冲突
尝试自动解决模组冲突。

**请求：**
```json
{
  "type": "request",
  "action": "resolve_conflicts",
  "id": "resolve-request-890",
  "data": {
    "targetMod": "ComplexMod",
    "strategy": "disable_conflicting"
  }
}
```

**响应：**
```json
{
  "type": "response",
  "action": "resolve_conflicts",
  "id": "resolve-request-890",
  "data": {
    "status": "partial",
    "actions": [
      { "type": "deactivate", "mod": "IncompatibleMod", "success": true },
      { "type": "activate", "mod": "UtilsMod", "success": true }
    ],
    "remainingConflicts": [],
    "canNowActivate": true
  }
}
```

## 实时事件

### 事件结构
```json
{
  "type": "event",
  "action": "event_name",
  "timestamp": 1731540000,
  "data": { /* 事件特定数据 */ }
}
```

### 可用事件

#### 模组扫描完成
模组扫描完成时触发。
```json
{
  "type": "event",
  "action": "mods_scanned",
  "timestamp": 1731540000,
  "data": {
    "modCount": 5,
    "newMods": ["NewMod1", "NewMod2"],
    "removedMods": ["OldMod1"]
  }
}
```

#### 模组已激活
模组成功激活时触发。
```json
{
  "type": "event",
  "action": "mod_activated",
  "timestamp": 1731540000,
  "data": {
    "modName": "ExampleMod",
    "priority": 1,
    "loadTime": 150
  }
}
```

#### 模组即将停用
停用前通知。
```json
{
  "type": "event",
  "action": "mod_will_deactivate",
  "timestamp": 1731540000,
  "data": {
    "modName": "ExampleMod",
    "reason": "user_request"
  }
}
```

#### 模组状态变更
通用状态变更通知。
```json
{
  "type": "event",
  "action": "mod_status_changed",
  "timestamp": 1731540000,
  "data": {
    "modName": "ExampleMod",
    "oldStatus": "inactive",
    "newStatus": "active",
    "priority": 2
  }
}
```

#### 模组加载失败
加载失败通知。
```json
{
  "type": "event",
  "action": "mod_loading_failed",
  "timestamp": 1731540000,
  "data": {
    "modName": "BrokenMod",
    "error": "DLL 未找到",
    "dllPath": "Mods/BrokenMod/BrokenMod.dll"
  }
}
```

## 错误处理

### 错误响应结构
```json
{
  "type": "response",
  "action": "operation_name",
  "id": "request-id",
  "error": {
    "code": "ERROR_CODE",
    "message": "人类可读的错误信息",
    "details": { /* 附加错误详情 */ }
  }
}
```

### 错误代码

#### 认证错误
- `AUTH_FAILED`: 认证凭据无效
- `TOKEN_EXPIRED`: 认证令牌已过期
- `PERMISSION_DENIED`: 操作权限不足

#### 模组操作错误
- `MOD_NOT_FOUND`: 指定模组不存在
- `MOD_ALREADY_ACTIVE`: 模组已激活
- `MOD_NOT_ACTIVE`: 模组当前未激活
- `DEPENDENCY_MISSING`: 必需依赖项不可用
- `CONFLICT_DETECTED`: 模组与活动模组冲突

#### 系统错误
- `INTERNAL_ERROR`: 常规系统错误
- `OPERATION_TIMEOUT`: 操作超时
- `QUEUE_FULL`: 操作队列已满
- `SYSTEM_OVERLOADED`: 系统资源耗尽

#### 配置错误
- `INVALID_PRIORITY`: 优先级值超出范围
- `INVALID_BATCH_SIZE`: 批量大小超出限制
- `SETTINGS_LOCKED`: 设置无法修改

### 错误响应示例
```json
{
  "type": "response",
  "action": "activate_mod",
  "id": "error-request-123",
  "error": {
    "code": "DEPENDENCY_MISSING",
    "message": "由于缺少依赖项，无法激活模组",
    "details": {
      "modName": "ComplexMod",
      "missingDependencies": ["BaseMod", "UtilsMod"],
      "availableDependencies": ["BaseMod"]
    }
  }
}
```

## 速率限制

### 限制
- **常规请求**: 每个客户端每分钟 60 次请求
- **批量操作**: 每分钟 10 次批量操作
- **认证**: 每个客户端每分钟 5 次尝试

### 速率限制响应
```json
{
  "type": "response",
  "action": "operation_name",
  "id": "rate-limited-request",
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "超出速率限制。请在 30 秒后重试。",
    "details": {
      "retryAfter": 30,
      "limit": 60,
      "window": 60
    }
  }
}
```

## 性能考虑

### 批处理
- **最大批量大小**: 50 个操作
- **处理间隔**: 批次之间 100-150ms
- **队列容量**: 1000 个待处理操作

### 连接管理
- **最大连接数**: 100 个并发客户端
- **连接超时**: 60 秒空闲超时
- **心跳间隔**: 15 秒
- **消息大小限制**: 每条消息 1MB

### 资源限制
- **内存使用**: 45MB 降级阈值
- **CPU 使用**: 80% 节流阈值
- **线程池**: 4-16 个动态线程
- **操作超时**: 每个操作 3 秒

## 客户端实现示例

### JavaScript/WebSocket 客户端
```javascript
const WebSocket = require('ws');

class ModManagerClient {
  constructor(url = 'ws://127.0.0.1:8765/mods') {
    this.url = url;
    this.ws = null;
    this.authenticated = false;
    this.messageHandlers = new Map();
  }

  async connect() {
    return new Promise((resolve, reject) => {
      this.ws = new WebSocket(this.url, 'duckov-mods-v1');
    
      this.ws.on('open', () => {
        this.sendHello().then(resolve).catch(reject);
      });
    
      this.ws.on('message', (data) => {
        this.handleMessage(JSON.parse(data));
      });
    
      this.ws.on('error', reject);
    });
  }

  async sendHello() {
    return this.sendRequest('hello', {
      client_id: 'my-client',
      version: '1.0.0',
      capabilities: ['read_mods', 'manage_activation']
    });
  }

  async sendRequest(action, data) {
    const id = this.generateId();
    return new Promise((resolve, reject) => {
      this.messageHandlers.set(id, { resolve, reject });
    
      this.ws.send(JSON.stringify({
        type: 'request',
        action,
        id,
        data
      }));
    
      // 30 秒后超时
      setTimeout(() => {
        if (this.messageHandlers.has(id)) {
          this.messageHandlers.delete(id);
          reject(new Error('请求超时'));
        }
      }, 30000);
    });
  }

  handleMessage(message) {
    if (message.type === 'response' && this.messageHandlers.has(message.id)) {
      const handler = this.messageHandlers.get(message.id);
      this.messageHandlers.delete(message.id);
    
      if (message.error) {
        handler.reject(new Error(message.error.message));
      } else {
        handler.resolve(message.data);
      }
    }
  }

  generateId() {
    return Math.random().toString(36).substr(2, 9);
  }
}
```

### Python 客户端
```python
import websocket
import json
import threading
import time

class ModManagerClient:
    def __init__(self, url='ws://127.0.0.1:8765/mods'):
        self.url = url
        self.ws = None
        self.authenticated = False
        self.pending_requests = {}
      
    def connect(self):
        self.ws = websocket.WebSocketApp(
            self.url,
            subprotocols=['duckov-mods-v1'],
            on_open=self.on_open,
            on_message=self.on_message,
            on_error=self.on_error,
            on_close=self.on_close
        )
      
        threading.Thread(target=self.ws.run_forever).start()
      
    def on_open(self, ws):
        print("已连接到 Mod Manager Bridge")
        self.send_hello()
      
    def on_message(self, ws, message):
        data = json.loads(message)
        self.handle_message(data)
      
    def send_hello(self):
        return self.send_request('hello', {
            'client_id': 'python-client',
            'version': '1.0.0',
            'capabilities': ['read_mods', 'manage_activation']
        })
      
    def send_request(self, action, data):
        request_id = str(int(time.time() * 1000))
      
        event = threading.Event()
        response_data = {'result': None, 'error': None}
      
        self.pending_requests[request_id] = {
            'event': event,
            'response': response_data
        }
      
        message = {
            'type': 'request',
            'action': action,
            'id': request_id,
            'data': data
        }
      
        self.ws.send(json.dumps(message))
      
        # 带超时的等待响应
        if event.wait(timeout=30):
            if response_data['error']:
                raise Exception(response_data['error'])
            return response_data['result']
        else:
            raise Exception('请求超时')
          
    def handle_message(self, message):
        if message['type'] == 'response' and message['id'] in self.pending_requests:
            request_data = self.pending_requests.pop(message['id'])
          
            if 'error' in message:
                request_data['response']['error'] = message['error']['message']
            else:
                request_data['response']['result'] = message.get('data')
              
            request_data['event'].set()
```

本 API 参考文档为与 Mod Manager Bridge 系统集成提供了完整的文档说明。基于 WebSocket 的协议确保了实时通信，同时保持了生产级模组管理应用所需的安全性和性能标准。