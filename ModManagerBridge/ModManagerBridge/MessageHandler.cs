using System;
using System.Collections.Generic;
using UnityEngine;

namespace ModManagerBridge
{
    /// <summary>
    /// 消息处理器，负责处理WebSocket消息和命令
    /// </summary>
    public class MessageHandler
    {
        // 命令处理器字典
        private Dictionary<string, Func<CommandRequest, string>> commandHandlers = new Dictionary<string, Func<CommandRequest, string>>();
        
        /// <summary>
        /// 构造函数
        /// </summary>
        public MessageHandler()
        {            // 注册默认命令处理器
            RegisterDefaultCommandHandlers();
        }
        
        /// <summary>
        /// 处理接收到的消息
        /// </summary>
        public string ProcessMessage(string message, ModManagerWebSocketBehavior client)
        {            try
            {                Debug.Log($"Processing message: {message}");
                
                // 检查是否是握手消息
                if (IsHandshakeMessage(message))
                {                    return HandleHandshakeMessage(client);
                }
                
                // 检查是否是断开连接消息
                if (IsDisconnectMessage(message))
                {                    return HandleDisconnectMessage(client);
                }
                
                // 解析命令请求
                CommandRequest commandRequest = ParseCommandRequest(message);
                
                // 处理命令
                return ExecuteCommand(commandRequest);
            }
            catch (Exception ex)
            {                Debug.LogError($"Error processing message: {ex.Message}");
                return CreateErrorResponse($"Message processing error: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 注册命令处理器
        /// </summary>
        public void RegisterCommandHandler(string command, Func<CommandRequest, string> handler)
        {            if (string.IsNullOrEmpty(command))
            {                throw new ArgumentException("Command name cannot be null or empty", nameof(command));
            }
            
            if (handler == null)
            {                throw new ArgumentNullException(nameof(handler), "Command handler cannot be null");
            }
            
            commandHandlers[command.ToLower()] = handler;
            Debug.Log($"Command handler registered for: {command}");
        }
        
        /// <summary>
        /// 注册默认命令处理器
        /// </summary>
        private void RegisterDefaultCommandHandlers()
        {            // 默认处理器可以在这里注册
            // 实际的命令处理逻辑会在ModBehaviour中设置
        }
        
        /// <summary>
        /// 解析命令请求
        /// </summary>
        private CommandRequest ParseCommandRequest(string json)
        {            return ManualJsonParse(json);
        }
        
        /// <summary>
        /// 简单的JSON手动解析
        /// </summary>
        private CommandRequest ManualJsonParse(string json)
        {            var request = new CommandRequest();
            
            try
            {                // 简单的JSON解析逻辑
                json = json.Trim();
                
                // 提取command字段
                int commandLabelStart = json.IndexOf("\"command\"");
                if (commandLabelStart >= 0)
                {                    int colonIndex = json.IndexOf(":", commandLabelStart);
                    int commandValueStart = json.IndexOf("\"", colonIndex + 1) + 1;
                    int commandValueEnd = json.IndexOf("\"", commandValueStart);
                    if (commandValueStart > 0 && commandValueEnd > commandValueStart)
                    {                        request.command = json.Substring(commandValueStart, commandValueEnd - commandValueStart);
                    }
                }
                
                // 提取parameters字段
                int parametersLabelStart = json.IndexOf("\"parameters\"");
                if (parametersLabelStart >= 0)
                {                    request.parameters = new CommandParameters();
                    
                    // 提取ModName
                    int modNameLabelStart = json.IndexOf("\"ModName\"");
                    if (modNameLabelStart >= 0)
                    {                        int colonIndex = json.IndexOf(":", modNameLabelStart);
                        int modNameValueStart = json.IndexOf("\"", colonIndex + 1) + 1;
                        int modNameValueEnd = json.IndexOf("\"", modNameValueStart);
                        if (modNameValueStart > 0 && modNameValueEnd > modNameValueStart)
                        {                            request.parameters.ModName = json.Substring(modNameValueStart, modNameValueEnd - modNameValueStart);
                        }
                    }
                    
                    // 提取Enabled
                    int enabledLabelStart = json.IndexOf("\"Enabled\"");
                    if (enabledLabelStart >= 0)
                    {                        int colonIndex = json.IndexOf(":", enabledLabelStart);
                        int trueIndex = json.IndexOf("true", colonIndex + 1);
                        int falseIndex = json.IndexOf("false", colonIndex + 1);
                        
                        if (trueIndex > 0 && (falseIndex == -1 || trueIndex < falseIndex))
                        {                            request.parameters.Enabled = true;
                        }
                        else if (falseIndex > 0)
                        {                            request.parameters.Enabled = false;
                        }
                    }
                    
                    // 提取ModNames数组（简化处理）
                    int modNamesLabelStart = json.IndexOf("\"ModNames\"");
                    if (modNamesLabelStart >= 0)
                    {                        // 这里可以添加更复杂的数组解析逻辑
                        // 目前暂时留空
                    }
                }
                
                Debug.Log($"Manual parse result: command='{request.command}', ModName='{request.parameters?.ModName}'");
            }
            catch (Exception ex)
            {                Debug.LogError($"Manual JSON parsing failed: {ex.Message}");
            }
            
            return request;
        }
        
        /// <summary>
        /// 执行命令
        /// </summary>
        private string ExecuteCommand(CommandRequest request)
        {            if (string.IsNullOrEmpty(request.command))
            {                return CreateErrorResponse("Command not specified");
            }
            
            string commandKey = request.command.ToLower();
            if (commandHandlers.TryGetValue(commandKey, out var handler))
            {                try
                {                    return handler(request);
                }
                catch (Exception ex)
                {                    Debug.LogError($"Error executing command {commandKey}: {ex.Message}");
                    return CreateErrorResponse($"Command execution error: {ex.Message}");
                }
            }
            else
            {                Debug.LogWarning($"Unknown command: {commandKey}");
                return CreateErrorResponse($"Unknown command: {commandKey}");
            }
        }
        
        /// <summary>
        /// 检查是否是握手消息
        /// </summary>
        private bool IsHandshakeMessage(string message)
        {            return message.Trim().Equals("{\"command\":\"hellow\"}", StringComparison.OrdinalIgnoreCase);
        }
        
        /// <summary>
        /// 处理握手消息
        /// </summary>
        private string HandleHandshakeMessage(ModManagerWebSocketBehavior client)
        {            Debug.Log($"Handshake received from client {client.ClientId}");
            return CreateSuccessResponse("Connection established", null);
        }
        
        /// <summary>
        /// 检查是否是断开连接消息
        /// </summary>
        private bool IsDisconnectMessage(string message)
        {            return message.Trim().Equals("{\"command\":\"bye\"}", StringComparison.OrdinalIgnoreCase);
        }
        
        /// <summary>
        /// 处理断开连接消息
        /// </summary>
        private string HandleDisconnectMessage(ModManagerWebSocketBehavior client)
        {            Debug.Log($"Disconnect request received from client {client.ClientId}");
            // 关闭连接
            client.Close();
            return CreateSuccessResponse("Connection closed gracefully", null);
        }
        
        /// <summary>
        /// 创建成功响应
        /// </summary>
        public static string CreateSuccessResponse(string message, string dataJson = null)
        {            var response = new System.Text.StringBuilder();
            response.Append("{");
            response.Append($"\"status\":\"success\",");
            response.Append($"\"message\":\"{EscapeJsonString(message)}\",");
            
            if (!string.IsNullOrEmpty(dataJson))
            {                response.Append($"\"data\":{dataJson}");
            }
            else
            {                // 删除最后的逗号
                response.Remove(response.Length - 1, 1);
            }
            
            response.Append("}");
            return response.ToString();
        }
        
        /// <summary>
        /// 创建错误响应
        /// </summary>
        public static string CreateErrorResponse(string message)
        {            return $"{{\"status\":\"error\",\"message\":\"{EscapeJsonString(message)}\"}}";
        }
        
        /// <summary>
        /// 转义JSON字符串
        /// </summary>
        public static string EscapeJsonString(string str)
        {            if (string.IsNullOrEmpty(str))
            {                return string.Empty;
            }
            
            return str.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r").Replace("\t", "\\t");
        }
        
        /// <summary>
        /// 格式化ModInfo数组为JSON
        /// </summary>
        public static string FormatModInfoArrayToJson(ModInfo[] array)
        {            if (array == null || array.Length == 0)
            {                return "[]";
            }
            
            var result = new System.Text.StringBuilder();
            result.Append("[");
            
            for (int i = 0; i < array.Length; i++)
            {                if (i > 0)
                {                    result.Append(",");
                }
                
                result.Append("{");
                result.Append($"\"name\":\"{EscapeJsonString(array[i].name)}\",");
                result.Append($"\"mod_id\":\"{EscapeJsonString(array[i].mod_id)}\",");
                result.Append($"\"enabled\":{array[i].enabled.ToString().ToLower()},");
                result.Append($"\"version\":\"{EscapeJsonString(array[i].version)}\",");
                result.Append($"\"author\":\"{EscapeJsonString(array[i].author)}\",");
                // 确保符合游戏core mod规范
                result.Append($"\"enabled\":{array[i].enabled.ToString().ToLower()}");
                result.Append("}");
            }
            
            result.Append("]");
            return result.ToString();
        }
    }
    
    /// <summary>
    /// 命令请求类
    /// </summary>
    public class CommandRequest
    {
        public string command = string.Empty;
        public CommandParameters parameters = new CommandParameters();
    }
    
    /// <summary>
    /// 命令参数类
    /// </summary>
    public class CommandParameters
    {
        public string ModName = string.Empty;
        public string[] ModNames = Array.Empty<string>();
        public bool Enabled = false;
    }
    
    /// <summary>
    /// Mod信息类
    /// </summary>
    public class ModInfo
    {
        public string name = string.Empty;
        public string mod_id = string.Empty;
        public bool enabled = false;
        public string version = string.Empty;
        public string author = string.Empty;
        
        /// <summary>
        /// 转换为JSON字符串
        /// </summary>
        public string ToJson()
        {            return $"{{\"name\":\"{MessageHandler.EscapeJsonString(name)}\",\"mod_id\":\"{MessageHandler.EscapeJsonString(mod_id)}\",\"enabled\":{enabled.ToString().ToLower()},\"version\":\"{MessageHandler.EscapeJsonString(version)}\",\"author\":\"{MessageHandler.EscapeJsonString(author)}\"}}";
        }
    }
}