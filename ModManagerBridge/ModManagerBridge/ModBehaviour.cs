using System;
using System.Collections.Generic;
using UnityEngine;
using WebSocketSharp;

namespace ModManagerBridge
{
    /// <summary>
    /// Mod管理器桥接类，作为整个Mod的入口点
    /// </summary>
    public class ModBehaviour : Duckov.Modding.ModBehaviour
    {
        // 核心组件
        private WebSocketServerManager webSocketServer;
        private MessageHandler messageHandler;
        private ModManager modManager;
        
        private const int DEFAULT_PORT = 38274;
        
        void Start()
        {            Debug.Log("ModManagerBridge Loading!!!");
            InitializeComponents();
            SetupCommandHandlers();
            StartWebSocketServer();
        }
        
        void OnDestroy()
        {            Debug.Log("ModManagerBridge Unloading!!!");
            StopWebSocketServer();
        }
        
        void Update()
        {            // 处理主线程任务队列
            ModManager.ProcessMainThreadActions();
        }
        
        /// <summary>
        /// 初始化所有组件
        /// </summary>
        private void InitializeComponents()
        {            try
            {                // 创建核心组件实例
                webSocketServer = new WebSocketServerManager(DEFAULT_PORT);
                messageHandler = new MessageHandler();
                modManager = new ModManager();
                
                // 配置开发者模式（可以从配置中读取）
                modManager.IsDeveloperMode = false;
                
                Debug.Log("Components initialized successfully");
            }
            catch (Exception ex)
            {                Debug.LogError($"Failed to initialize components: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 设置命令处理器
        /// </summary>
        private void SetupCommandHandlers()
        {            try
            {                // 注册命令处理器
                messageHandler.RegisterCommandHandler("get_mod_list", HandleGetModList);
                messageHandler.RegisterCommandHandler("get_mod_info", HandleGetModInfo);
                messageHandler.RegisterCommandHandler("enable_mod", HandleEnableMod);
                messageHandler.RegisterCommandHandler("disable_mod", HandleDisableMod);
                messageHandler.RegisterCommandHandler("batch_update_mods", HandleBatchUpdateMods);
                messageHandler.RegisterCommandHandler("set_developer_mode", HandleSetDeveloperMode);
                
                Debug.Log("Command handlers registered successfully");
            }
            catch (Exception ex)
            {                Debug.LogError($"Failed to register command handlers: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 启动WebSocket服务器
        /// </summary>
        private void StartWebSocketServer()
        {            try
            {                // 订阅WebSocket事件
                webSocketServer.OnMessageReceived += HandleWebSocketMessage;
                webSocketServer.OnClientConnected += HandleClientConnected;
                webSocketServer.OnClientDisconnected += HandleClientDisconnected;
                
                // 初始化并启动服务器
                bool success = webSocketServer.Initialize();
                if (!success)
                {                    Debug.LogError("Failed to start WebSocket server");
                }
            }
            catch (Exception ex)
            {                Debug.LogError($"Failed to start WebSocket server: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 停止WebSocket服务器
        /// </summary>
        private void StopWebSocketServer()
        {            try
            {                if (webSocketServer != null)
                {                    webSocketServer.Stop();
                }
            }
            catch (Exception ex)
            {                Debug.LogError($"Error stopping WebSocket server: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 处理WebSocket消息
        /// </summary>
        private void HandleWebSocketMessage(string message, ModManagerWebSocketBehavior client)
        {            try
            {                // 使用消息处理器处理消息
                string response = messageHandler.ProcessMessage(message, client);
                
                // 发送响应
                client.SendResponse(response);
            }
            catch (Exception ex)
            {                Debug.LogError($"Error processing WebSocket message: {ex.Message}");
                string errorResponse = MessageHandler.CreateErrorResponse($"Message processing error: {ex.Message}");
                client.SendResponse(errorResponse);
            }
        }
        
        /// <summary>
        /// 处理客户端连接
        /// </summary>
        private void HandleClientConnected(ModManagerWebSocketBehavior client)
        {            Debug.Log($"Client connected: {client.ClientId}");
            // 可以在这里添加连接后的处理逻辑
        }
        
        /// <summary>
        /// 处理客户端断开连接
        /// </summary>
        private void HandleClientDisconnected(ModManagerWebSocketBehavior client)
        {            Debug.Log($"Client disconnected: {client.ClientId}");
            // 可以在这里添加断开连接后的清理逻辑
        }
        
        // 命令处理方法
        
        private string HandleGetModList(CommandRequest request)
        {            try
            {                Debug.Log("Handling get_mod_list command");
                ModInfo[] modList = modManager.GetModList();
                string dataJson = MessageHandler.FormatModInfoArrayToJson(modList);
                return MessageHandler.CreateSuccessResponse("Mod list retrieved successfully", dataJson);
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in HandleGetModList: {ex.Message}");
                return MessageHandler.CreateErrorResponse($"Failed to retrieve mod list: {ex.Message}");
            }
        }
        
        private string HandleGetModInfo(CommandRequest request)
        {            try
            {                string modName = request.parameters.ModName;
                Debug.Log($"Handling get_mod_info command for: {modName}");
                
                if (string.IsNullOrEmpty(modName))
                {                    return MessageHandler.CreateErrorResponse("Mod name is required");
                }
                
                ModInfo modInfo = modManager.GetModInfo(modName);
                return MessageHandler.CreateSuccessResponse("Mod info retrieved successfully", modInfo.ToJson());
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in HandleGetModInfo: {ex.Message}");
                return MessageHandler.CreateErrorResponse($"Failed to retrieve mod info: {ex.Message}");
            }
        }
        
        private string HandleEnableMod(CommandRequest request)
        {            try
            {                string modName = request.parameters.ModName;
                Debug.Log($"Handling enable_mod command for: {modName}");
                
                if (string.IsNullOrEmpty(modName))
                {                    return MessageHandler.CreateErrorResponse("Mod name is required");
                }
                
                bool success = modManager.EnableMod(modName);
                if (success)
                {                    return MessageHandler.CreateSuccessResponse($"Mod '{modName}' enabled successfully");
                }
                else
                {                    return MessageHandler.CreateErrorResponse($"Failed to enable mod '{modName}'");
                }
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in HandleEnableMod: {ex.Message}");
                return MessageHandler.CreateErrorResponse($"Failed to enable mod: {ex.Message}");
            }
        }
        
        private string HandleDisableMod(CommandRequest request)
        {            try
            {                string modName = request.parameters.ModName;
                Debug.Log($"Handling disable_mod command for: {modName}");
                
                if (string.IsNullOrEmpty(modName))
                {                    return MessageHandler.CreateErrorResponse("Mod name is required");
                }
                
                bool success = modManager.DisableMod(modName);
                if (success)
                {                    return MessageHandler.CreateSuccessResponse($"Mod '{modName}' disabled successfully");
                }
                else
                {                    return MessageHandler.CreateErrorResponse($"Failed to disable mod '{modName}'");
                }
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in HandleDisableMod: {ex.Message}");
                return MessageHandler.CreateErrorResponse($"Failed to disable mod: {ex.Message}");
            }
        }
        
        private string HandleBatchUpdateMods(CommandRequest request)
        {            try
            {                string[] modNames = request.parameters.ModNames;
                bool enabled = request.parameters.Enabled;
                Debug.Log($"Handling batch_update_mods command for {modNames.Length} mods, enabled: {enabled}");
                
                if (modNames == null || modNames.Length == 0)
                {                    return MessageHandler.CreateErrorResponse("Mod names array is required");
                }
                
                BatchOperationResult result = modManager.BatchUpdateMods(modNames, enabled);
                
                string operation = enabled ? "enabled" : "disabled";
                string message = $"Batch operation completed: {result.SuccessCount} mods {operation}, {result.FailedCount} failed";
                
                return MessageHandler.CreateSuccessResponse(message, result.ToJson());
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in HandleBatchUpdateMods: {ex.Message}");
                return MessageHandler.CreateErrorResponse($"Failed to perform batch operation: {ex.Message}");
            }
        }
        
        private string HandleSetDeveloperMode(CommandRequest request)
        {            try
            {                bool enabled = request.parameters.Enabled;
                Debug.Log($"Handling set_developer_mode command: {enabled}");
                
                modManager.IsDeveloperMode = enabled;
                
                string message = enabled ? "Developer mode enabled" : "Developer mode disabled";
                return MessageHandler.CreateSuccessResponse(message);
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in HandleSetDeveloperMode: {ex.Message}");
                return MessageHandler.CreateErrorResponse($"Failed to set developer mode: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 广播消息给所有连接的客户端
        /// </summary>
        public void BroadcastMessage(string message)
        {            if (webSocketServer != null)
            {                webSocketServer.BroadcastMessage(message);
            }
        }
    }
    
    // 数据结构定义
    [Serializable]
    public class CommandRequest
    {
        public string command = "";
        public CommandParameters parameters = new CommandParameters();
    }
    
    [Serializable]
    public class CommandParameters
    {
        public string ModName = "";
        public string[] ModNames = new string[0];
        public bool Enabled = false;
    }
    
    [Serializable]
    public class ModInfo
    {
        public string name = "";
        public string mod_id = "";
        public bool enabled = false;
        public string version = "";
        public string author = "";
        
        // 转换为JSON字符串
        public string ToJson()
        {
            var sb = new System.Text.StringBuilder();
            sb.Append("{");
            sb.Append($"\"name\":\"{MessageHandler.EscapeJsonString(name)}\",");
            sb.Append($"\"mod_id\":\"{MessageHandler.EscapeJsonString(mod_id)}\",");
            sb.Append($"\"enabled\":{enabled.ToString().ToLower()},");
            sb.Append($"\"version\":\"{MessageHandler.EscapeJsonString(version)}\",");
            sb.Append($"\"author\":\"{MessageHandler.EscapeJsonString(author)}\");
            sb.Append("}");
            return sb.ToString();
        }
    }
}
