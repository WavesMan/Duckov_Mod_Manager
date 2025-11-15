# Duckov Mod 管理桥接技术文档

版本：v1.0.0  日期：2025-11-14

## 版本历史
- v0.1.0：初版架构解析与桥接协议草案
- v0.2.0：补充权限粒度、事件重放与性能建议
- v1.0.0：定稿，完善错误码与兼容策略

## 术语表
- Mod：位于 `Mods` 目录的扩展模块，包含 `info.ini` 与 `<name>.dll`
- ModInfo：Mod 元数据对象，含名称、描述、DLL 路径、预览图
- ModBehaviour：Mod 主类，须继承并命名为 `<name>.ModBehaviour`
- 激活/停用：加载 DLL 并挂载组件/销毁实例的过程
- 门禁：`AllowLoadingMod` 决定是否允许激活任何 Mod
- 优先级：用于排序的整型值，存于 ES3 存储 `priority_<name>`
- 事件：以 C# 委托的 `On*` 形式分布式发布订阅
- Hook：GoldMiner 领域内的钩子对象与其事件
- Trigger：物品效果系统的触发器链路

## 架构总览
- 目录结构：`Application.dataPath/Mods` 作为扫描根目录（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:170-176）
- 扫描解析：`Rescan()` 读取子目录与 `info.ini` 并构建 `ModInfo`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:209-230, 273-358）
- 激活流程：`ScanAndActivateMods()` → `ShouldActivateMod(info)` → `ActivateMod(info)`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:54-73）
- 反射加载：`Assembly.LoadFrom(info.dllPath)` 获取 `<name>.ModBehaviour` 并验证继承（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:433-453, 436-447）
- 生命周期：`OnAfterSetup()` 与 `OnBeforeDeactivate()`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModBehaviour.cs:20-25, 34-41；duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:379-414）
- 事件：`OnScan/OnModActivated/OnModWillBeDeactivated/OnModStatusChanged/OnModLoadingFailed`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:18, 191, 196, 201, 206, 522）
- 优先级：读写于 ES3（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:93-154），排序与重排（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:76-91, 246-270）
- 状态持久化：`ModActive_<name>` 与门禁 `AllowLoadingMod`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:23-37, 156-166）

## 核心模块详解
### Mod 加载流程
- 路径与发现：`DefaultModFolderPath` 返回 `Application.dataPath/Mods`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:170-176）
- 扫描：`Rescan()` 遍历子目录，`TryProcessModFolder` 解析 `info.ini` 与 `preview.png`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:209-230, 273-358, 343-356）
- 排序：按 `GetModPriority(name)` 比较（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:76-91）
- 激活：`ActivateMod(info)` 反射加载，挂载组件并调用 `Setup(master, info)`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:417-495）

### 核心事件处理机制
- 分布式 C# 事件，无统一 EventBus；订阅各模块的 `On*` 事件即可：
  - Mod 生命周期：`OnScan/OnModActivated/OnModWillBeDeactivated/OnModStatusChanged/OnModLoadingFailed`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:18, 191, 196, 201, 206, 522）
  - 生命事件：`Health.OnHurt/OnDead`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Health.cs:108-118）
  - 输入事件：`InputManager.OnSwitchWeaponInput/OnSwitchBulletTypeInput`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/InputManager.cs:83-88）
  - UI 事件：`UIInputManager.OnNavigate/OnConfirm`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/UIInputManager.cs:22-27）

### mod 间通信协议
- 现状：未提供通用 `ModMessage/MessageBus/SendMessage/Channel`（Modding 目录检索无匹配）
- 可用机制：
  - 共享管理器：`ModManager.activeMods` 字典访问与查询（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:361-376, 399-414, 531）
  - 静态入口：`GameManager.ModManager`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/GameManager.cs:170-176）
  - 事件广播：依赖分布式事件进行弱耦合协作

### Hook 系统实现
- GoldMiner 钩子：`Hook` 暴露一组事件供绑定（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/MiniGames/GoldMiner/Hook.cs:81, 86, 91, 96, 101）
- 物品效果触发链：统一经 `EffectTrigger.Trigger(...)` 驱动 `Effect.Trigger(...)` 的过滤与动作（duckovAPI/Decompilation/ItemStatsSystem/EffectTrigger.cs:33-36；duckovAPI/Decompilation/ItemStatsSystem/Effect.cs:117-135）
- 角色输入触发：统一入口 `CharacterMainControl.Trigger(...)` 与开火事件上报（duckovAPI/Decompilation/TeamSoda.Duckov.Core/CharacterMainControl.cs:1090-1102, 1153-1161）

## WebSocket 桥接接口规范
### 架构与连接
- 端点：`ws://127.0.0.1:8765/mods`
- 握手：
 1) 客户端 `HELLO`：`{ "type": "request", "action": "hello", "id": "...", "data": { "client_id": "...", "version": "1.0.0", "capabilities": ["read_mods","manage_activation","manage_priority","manage_settings"] } }`
 2) 服务器 `WELCOME`：`{ "type": "response", "action": "hello", "id": "...", "data": { "server_version": "1.0.0", "protocol_version": "1.0.0", "nonce": "..." } }`
 3) 客户端 `AUTH`：`{ "type": "request", "action": "auth", "id": "...", "data": { "client_id": "...", "nonce": "...", "timestamp": 1731540000, "hmac": "<HMAC-SHA256>" } }`
 4) 服务器 `AUTH_OK`：`{ "type": "response", "action": "auth", "id": "...", "data": { "ok": true } }`
- 心跳：`PING/PONG` 携带 `seq` 与时间戳

### 指令集（请求/响应）
- `scan_mods`
  - 请求：`{ "type":"request", "action":"scan_mods", "id":"..." }`
  - 响应：`{ "type":"response", "action":"scan_mods", "id":"...", "data": { "mods": [ { "name":"...", "displayName":"...", "description":"...", "dllPath":"...", "preview":"<base64?>", "publishedFileId":0, "folderPath":"..." } ], "count": 3 } }`
- `get_mods`
  - 响应包含状态与优先级：`active: bool, priority: int`
- `activate_mod`
  - 请求：`{ "type":"request", "action":"activate_mod", "id":"...", "data": { "name":"..." } }`
  - 响应：`{ "type":"response", "action":"activate_mod", "id":"...", "data": { "status":"ok" } }`
- `deactivate_mod`
- `set_priority`
- `set_allow_loading`
- `get_settings`

### 事件推送（服务器→客户端）
- `mods_scanned`：来源 `OnScan`
- `mod_activated`：来源 `OnModActivated`
- `mod_will_deactivate`：来源 `OnModWillBeDeactivated`
- `mod_status_changed`：来源 `OnModStatusChanged`
- `mod_loading_failed`：来源 `OnModLoadingFailed`
- `mods_reordered`：来源 `OnReorder`

### 错误码
- `OK=0`
- `ERR_INVALID=400`
- `ERR_FORBIDDEN=403`
- `ERR_NOT_FOUND=404`
- `ERR_INTERNAL=500`

### 数据模型
- `ModInfo`：`name, displayName, description, dllPath, preview, publishedFileId, folderPath`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModInfo.cs:21-44）
- `ModState`：`active, priority, allow_loading`（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:23-37, 93-154, 156-166）

## 安全与认证
- 令牌：仅本地保存与读取，避免写日志
- HMAC：`HMAC-SHA256(nonce + timestamp + client_id, token)`，服务器校验时间窗口 ±300s
- 权限粒度：`read_mods`、`manage_activation`、`manage_priority`、`manage_settings`
- 访问限制：仅回环地址或白名单；连接上限与速率限制；防重放

## 版本兼容策略
- `protocol_version` 协商，服务端提供支持范围与降级
- `capabilities` 特性开关，用于向后兼容新增字段
- 返回 `server_version` 与 `duckov_core_version` 供客户端决策

## 示例代码片段
### Unity 内部桥接（C#）
```csharp
using System;
using System.Collections.Generic;
using UnityEngine;

public class ModBridgeService : MonoBehaviour
{
    void Start()
    {
        TeamSoda.Duckov.Core.Duckov.Modding.ModManager.OnScan += OnScan;
        TeamSoda.Duckov.Core.Duckov.Modding.ModManager.OnModActivated += OnModActivated;
        TeamSoda.Duckov.Core.Duckov.Modding.ModManager.OnModWillBeDeactivated += OnModWillDeactivate;
        TeamSoda.Duckov.Core.Duckov.Modding.ModManager.OnModStatusChanged += OnModStatusChanged;
        TeamSoda.Duckov.Core.Duckov.Modding.ModManager.OnReorder += OnReorder;
    }

    void OnScan(List<TeamSoda.Duckov.Core.Duckov.Modding.ModInfo> mods) { }
    void OnModActivated(TeamSoda.Duckov.Core.Duckov.Modding.ModInfo info, TeamSoda.Duckov.Core.Duckov.Modding.ModBehaviour behaviour) { }
    void OnModWillDeactivate(TeamSoda.Duckov.Core.Duckov.Modding.ModInfo info, TeamSoda.Duckov.Core.Duckov.Modding.ModBehaviour behaviour) { }
    void OnModStatusChanged() { }
    void OnReorder() { }
}
```

### 外部客户端（Node.js）
```javascript
const WebSocket = require('ws');
const ws = new WebSocket('ws://127.0.0.1:8765/mods');
ws.on('open', () => {
  ws.send(JSON.stringify({type:'request',action:'hello',id:'1',data:{client_id:'cli',version:'1.0.0',capabilities:['read_mods']}}));
});
ws.on('message', msg => {
  const m = JSON.parse(msg);
  if (m.action === 'hello') {
    ws.send(JSON.stringify({type:'request',action:'auth',id:'2',data:{client_id:'cli',nonce:m.data.nonce,timestamp:Date.now(),hmac:'<calc>'}}));
  }
});
```

## 已知限制与边界条件
- 无通用 EventBus；跨模交互需走管理器或事件广播
- DLL 类型命名必须 `<name>.ModBehaviour`，否则加载失败（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:449-453）
- 设置项依赖 `SavesSystem` 与 ES3，外部写入需谨慎
- 预览图与大字段应启用分片或压缩，避免阻塞与高 GC 压力

## 性能优化建议
- 扫描缓存与校验和，避免重复 IO
- 事件批次合并与节流，降低风暴
- WebSocket 压缩与背压处理，控制消息大小与频率
- 反射加载前置校验类型存在与继承，失败快速返回

## 参考索引
- ModManager：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:18, 54-73, 76-91, 93-154, 156-166, 170-176, 191-208, 209-230, 246-270, 273-358, 343-356, 379-414, 417-495, 522, 531
- ModBehaviour：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModBehaviour.cs:20-25, 34-41
- ModInfo：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModInfo.cs:21-44
- Effect/Trigger：duckovAPI/Decompilation/ItemStatsSystem/EffectTrigger.cs:33-36；duckovAPI/Decompilation/ItemStatsSystem/Effect.cs:117-135
- CharacterMainControl：duckovAPI/Decompilation/TeamSoda.Duckov.Core/CharacterMainControl.cs:1090-1102, 1153-1161
- 生命事件：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Health.cs:108-118
- 输入事件：duckovAPI/Decompilation/TeamSoda.Duckov.Core/InputManager.cs:83-88
- UI 事件：duckovAPI/Decompilation/TeamSoda.Duckov.Core/UIInputManager.cs:22-27

## 握手协议（RFC6455）
- HTTP 升级请求（客户端→服务器）
  - 必需头字段：`Host`、`Upgrade: websocket`、`Connection: Upgrade`、`Sec-WebSocket-Key`、`Sec-WebSocket-Version: 13`
  - 子协议：`Sec-WebSocket-Protocol: duckov-mods-v1`
  - 可选认证：`Authorization: Bearer <token>`（若采用预鉴权；若采用会话内 `HELLO/AUTH`，此头可省略）
  - 示例：
    ```http
    GET /mods HTTP/1.1
    Host: 127.0.0.1:8765
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==
    Sec-WebSocket-Version: 13
    Sec-WebSocket-Protocol: duckov-mods-v1
    Authorization: Bearer <optional-token>
    ```
- HTTP 升级响应（服务器→客户端）
  - 成功：`101 Switching Protocols`
  - 必需头字段：`Upgrade: websocket`、`Connection: Upgrade`、`Sec-WebSocket-Accept`（按 RFC6455 基于请求 `Sec-WebSocket-Key` 计算）
  - 子协议回显：`Sec-WebSocket-Protocol: duckov-mods-v1`
  - 示例：
    ```http
    HTTP/1.1 101 Switching Protocols
    Upgrade: websocket
    Connection: Upgrade
    Sec-WebSocket-Accept: HSmrc0sMlYUkAGmm5OPpG2HaGWk=
    Sec-WebSocket-Protocol: duckov-mods-v1
    ```
- 握手失败错误码与处理
  - `400 Bad Request`：缺失或非法头；客户端修正头后重试。
  - `401 Unauthorized`：令牌无效/过期；刷新令牌或改用会话内 `AUTH`。
  - `403 Forbidden`：不在白名单或权限不足；联系管理员或降级能力。
  - `404 Not Found`：路径错误（非 `/mods`）；修正 URL。
  - `426 Upgrade Required`：未包含升级头；按规范重发带 `Upgrade: websocket` 请求。
  - `429 Too Many Requests`：超速；依据退避策略延迟重试。
  - `500/503`：服务器错误/不可用；退避后重试，记录日志并上报。
  - 客户端均须记录：`action=handshake`、`code`、`retry_in`、`client_id`、不含敏感信息。

## 连接断开机制
- 正常关闭流程（RFC6455）
  - 任一方发送关闭帧（`Close`，状态码默认 `1000` 正常关闭，含可选 `reason`）。
  - 对端收到后回发关闭帧，随后双方完成 TCP 断开（FIN/ACK）。
  - 建议：客户端在收到服务器关闭后再断开套接字，确保完整关闭握手。
- 常见关闭/异常场景与处理
  - `1000 Normal Closure`：任务完成；清理资源并可立即重连（如需）。
  - `1001 Going Away`：服务器重启/维护；记录并退避重连。
  - `1002 Protocol Error`：协议违例；修正消息格式或降级能力。
  - `1003 Unsupported Data`：不支持的数据类型；改用文本/约定的二进制帧。
  - `1006 Abnormal Closure`：无关闭帧的异常断开；视为网络中断，进入重连流程。
  - `1007 Inconsistent Data`、`1008 Policy Violation`、`1009 Message Too Big`、`1010 Mandatory Extension`、`1011 Internal Error`、`1012 Service Restart`、`1013 Try Again Later`、`1015 TLS Failure`：按语义记录并采取相应修复或重试策略。
- 重连策略与退避算法
  - 指数退避：`base_delay=500ms`，因子 `×2`，最大 `30s`，随机抖动 `±20%`。
  - 伪代码：
    ```text
    attempt=0
    while (!connected) {
      delay = min(30s, 0.5s * 2^attempt) * (1 ± 0.2)
      sleep(delay)
      try_connect()
      attempt++
    }
    ```

## 超时与失联处理
- 心跳检测（Ping/Pong）
  - 间隔：`15s` 发送 `PING`；超时：`5s` 未收到 `PONG` 视为一次心跳失败。
  - 连续失败阈值：`3` 次；达到阈值后主动关闭并进入重连。
- 读写超时阈值
  - 读超时：`60s` 无入站数据则触发心跳；心跳失败按上节处理。
  - 写超时：发送队列 `10s` 未 flush 视为拥塞，记录并降速或断开重连。
- 失联检测与状态恢复
  - 维护 `last_event_id`；重连后在 `HELLO` 或 `resume` 请求中携带该值以请求事件重放窗口（默认 `1000` 条）。
  - 状态流：`Active → HeartbeatMiss(n) → Closing → Reconnecting → Handshaking → Authenticated → Active`。
- 客户端示例（Node.js，`ws`）
  ```javascript
  const WebSocket = require('ws');
  let attempt = 0, timer, pingTimer, lastEventId = 0;
  function connect(){
    const ws = new WebSocket('ws://127.0.0.1:8765/mods', 'duckov-mods-v1');
    ws.on('open', () => {
      attempt = 0;
      ws.send(JSON.stringify({type:'request',action:'hello',id:'1',data:{client_id:'cli',version:'1.0.0',capabilities:['read_mods'], last_event_id:lastEventId}}));
      pingTimer = setInterval(() => { try { ws.ping(); } catch {} }, 15000);
    });
    ws.on('pong', () => {/* reset timers */});
    ws.on('message', (msg) => { /* handle data & update lastEventId */ });
    ws.on('close', () => { cleanup(); retry(); });
    ws.on('error', () => { cleanup(); retry(); });
    function cleanup(){ clearInterval(pingTimer); }
    function retry(){
      const jitter = 1 + (Math.random()*0.4 - 0.2);
      const delay = Math.min(30000, 500 * Math.pow(2, attempt++)) * jitter;
      clearTimeout(timer); timer = setTimeout(connect, delay);
    }
  }
  connect();
  ```

## 错误处理（RFC6455 一致性）
- 异常分类
  - 超时：心跳失败、读超时、写拥塞。
  - 协议错误：握手缺失头、子协议不匹配、非法消息格式。
  - 网络错误：连接拒绝、网络中断、DNS 解析失败。
  - 认证错误：令牌无效、权限不足、会话过期。
  - 速率与负载：超限、消息过大、压缩失败。
- 错误码与恢复建议
  - HTTP：`400/401/403/404/426/429/500/503` → 修正参数/退避重试。
  - WS 关闭码：`1000/1001/1002/1003/1006/1009/1011/1012/1013` → 按语义记录并重连或修复。
  - 应用层：`OK=0, ERR_INVALID=400, ERR_FORBIDDEN=403, ERR_NOT_FOUND=404, ERR_INTERNAL=500`。
  - 建议：指数退避、限流、开启压缩、按需分片、校验消息体。
- 日志记录要求
  - 字段：`ts`、`event_id`、`conn_id`、`client_id`、`action`（hello/auth/scan/activate/...）、`dir`（in/out）、`code`、`duration_ms`、`size_bytes`、`error`。
  - 敏感信息禁止：令牌/密钥/完整栈；仅记录摘要与可定位信息。
  - 示例：
    ```text
    2025-11-14T12:00:00Z conn=abc123 client=cli action=handshake dir=out code=101 duration_ms=12
    2025-11-14T12:00:15Z conn=abc123 client=cli action=ping dir=out code=0 size_bytes=0
    2025-11-14T12:00:20Z conn=abc123 client=cli action=pong dir=in code=0 size_bytes=0
    2025-11-14T12:01:00Z conn=abc123 client=cli action=activate_mod dir=out code=0 size_bytes=64
    ```

## 状态转换图（概念示意）
```text
Disconnected → Connecting → [HTTP 101] → Handshaking → [AUTH_OK] → Active
Active → Closing → Closed
Active → [HeartbeatMiss ×3] → Closing → Reconnecting → Connecting → Handshaking → Active
Active → [ProtocolError] → Closing(code=1002) → Closed
```