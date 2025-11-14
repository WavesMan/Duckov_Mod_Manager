using System;
using System.Net.Sockets;
using System.Net;
using System.Threading;
using System.Text;
using System.Collections.Generic;
using System.Collections.Concurrent;
using System.Threading.Tasks;
using UnityEngine;

namespace ModManagerBridge
{
    public class ModBehaviour : Duckov.Modding.ModBehaviour
    {
        private TcpListener? tcpListener;
        private Thread? listenerThread;
        private List<TcpClient> clients = new List<TcpClient>();
        private const int PORT = 38274;
        private bool isRunning = false;
        
        // 主线程任务队列
        private static readonly ConcurrentQueue<Action> mainThreadActions = new ConcurrentQueue<Action>();

        void Start()
        {
            Debug.Log("ModManagerBridge Loading!!!");
            InitializeTCPServer();
        }
        
        void OnDestroy()
        {
            Debug.Log("ModManagerBridge Unloading!!!");
            StopTCPServer();
        }
        
        void Update()
        {
            // 处理主线程任务队列
            while (mainThreadActions.TryDequeue(out var action))
            {
                try 
                { 
                    action(); 
                }
                catch (Exception ex) 
                { 
                    Debug.LogError($"MainThreadAction error: {ex}"); 
                }
            }
        }

        private void InitializeTCPServer()
        {
            try
            {
                tcpListener = new TcpListener(IPAddress.Loopback, PORT);
                tcpListener.Start();
                isRunning = true;
                
                listenerThread = new Thread(ListenForClients);
                listenerThread.Start();
                
                Debug.Log($"ModManagerBridge API server started on port {PORT}");
            }
            catch (Exception ex)
            {
                Debug.LogError($"Failed to start TCP server: {ex.Message}");
            }
        }

        private void ListenForClients()
        {
            while (isRunning)
            {
                try
                {
                    if (tcpListener!.Pending())
                    {
                        TcpClient client = tcpListener.AcceptTcpClient();
                        clients.Add(client);
                        
                        Thread clientThread = new Thread(() => HandleClient(client));
                        clientThread.Start();
                    }
                    else
                    {
                        Thread.Sleep(100);
                    }
                }
                catch (Exception ex)
                {
                    if (isRunning)
                        Debug.LogError($"Error accepting client: {ex.Message}");
                }
            }
        }

        private void HandleClient(TcpClient client)
        {
            NetworkStream stream = client.GetStream();
            byte[] buffer = new byte[1024];
            
            while (isRunning && client.Connected)
            {
                try
                {
                    if (stream.DataAvailable)
                    {
                        int bytesRead = stream.Read(buffer, 0, buffer.Length);
                        if (bytesRead > 0)
                        {
                            string data = Encoding.UTF8.GetString(buffer, 0, bytesRead);
                            Debug.Log($"Received command: {data}");
                            ProcessCommand(data, stream);
                        }
                    }
                    else
                    {
                        Thread.Sleep(50);
                    }
                }
                catch (Exception ex)
                {
                    Debug.LogError($"Error handling client: {ex.Message}");
                    break;
                }
            }
            
            clients.Remove(client);
            client.Close();
        }

        private void ProcessCommand(string command, NetworkStream responseStream)
        {
            try
            {
                Debug.Log($"Raw command received: {command}");
                
                // 手动解析JSON命令
                CommandRequest commandObj = ManualJsonParse(command);
                Debug.Log($"Manually parsed command: {commandObj.command}, parameters.ModName: '{commandObj.parameters?.ModName}'");
                
                // 添加更详细的调试信息
                if (commandObj.parameters != null)
                {
                    Debug.Log($"Parameters object created: ModName = '{commandObj.parameters.ModName}'");
                }
                else
                {
                    Debug.Log("Parameters object is null");
                }
                
                string response = ExecuteCommand(commandObj);
                Debug.Log($"Sending response: {response}");
                
                // 发送响应
                byte[] responseBytes = Encoding.UTF8.GetBytes(response);
                responseStream.Write(responseBytes, 0, responseBytes.Length);
                responseStream.Flush();
            }
            catch (Exception ex)
            {
                Debug.LogError($"Command processing error: {ex.Message}");
                Debug.LogError($"Full exception: {ex}");
                // 使用自定义JSON格式而不是CommandResponse类
                string errorResponse = "{\"status\":\"error\",\"message\":\"Command processing error: " + ex.Message + "\"}";
                
                byte[] responseBytes = Encoding.UTF8.GetBytes(errorResponse);
                responseStream.Write(responseBytes, 0, responseBytes.Length);
                responseStream.Flush();
            }
        }

        private CommandRequest ManualJsonParse(string json)
        {
            var request = new CommandRequest();
            
            try
            {
                // 简单的JSON解析逻辑
                json = json.Trim();
                
                // 提取command字段 - 修复解析逻辑
                int commandLabelStart = json.IndexOf("\"command\"");
                if (commandLabelStart >= 0)
                {
                    int commandValueStart = json.IndexOf("\"", commandLabelStart + 9) + 1; // 跳过 "command":
                    int commandValueEnd = json.IndexOf("\"", commandValueStart);
                    if (commandValueStart > 0 && commandValueEnd > commandValueStart)
                    {
                        request.command = json.Substring(commandValueStart, commandValueEnd - commandValueStart);
                    }
                }
                
                // 提取ModName字段
                int modNameLabelStart = json.IndexOf("\"ModName\"");
                if (modNameLabelStart >= 0)
                {
                    int modNameValueStart = json.IndexOf("\"", modNameLabelStart + 9) + 1; // 跳过 "ModName":
                    int modNameValueEnd = json.IndexOf("\"", modNameValueStart);
                    if (modNameValueStart > 0 && modNameValueEnd > modNameValueStart)
                    {
                        request.parameters.ModName = json.Substring(modNameValueStart, modNameValueEnd - modNameValueStart);
                    }
                }
                
                Debug.Log($"Manual parse result: command='{request.command}', ModName='{request.parameters.ModName}'");
            }
            catch (Exception ex)
            {
                Debug.LogError($"Manual JSON parsing failed: {ex.Message}");
            }
            
            return request;
        }

        private string ExecuteCommand(CommandRequest request)
        {
            // 使用自定义JSON格式化方法来确保data字段正确序列化
            var response = new System.Text.StringBuilder();
            response.Append("{");
            
            switch (request.command?.ToLower())
            {
                case "enable_mod":
                    Debug.Log($"Executing enable_mod command for: {request.parameters?.ModName}");
                    bool enableResult = EnableMod(request.parameters?.ModName ?? "");
                    response.Append("\"status\":\"" + (enableResult ? "success" : "failed") + "\",");
                    response.Append("\"message\":\"" + (enableResult ? "Mod enabled successfully" : "Failed to enable mod") + "\"");
                    break;
                    
                case "disable_mod":
                    Debug.Log($"Executing disable_mod command for: {request.parameters?.ModName}");
                    bool disableResult = DisableMod(request.parameters?.ModName ?? "");
                    response.Append("\"status\":\"" + (disableResult ? "success" : "failed") + "\",");
                    response.Append("\"message\":\"" + (disableResult ? "Mod disabled successfully" : "Failed to disable mod") + "\"");
                    break;
                    
                case "get_mod_list":
                    Debug.Log("Executing get_mod_list command");
                    var modList = GetModList();
                    response.Append("\"status\":\"success\",");
                    response.Append("\"data\":" + FormatModInfoArrayToJson(modList));
                    Debug.Log($"Mod list data: {string.Join(", ", Array.ConvertAll(modList, item => item.name))}");
                    break;
                    
                case "get_mod_info":
                    Debug.Log($"Executing get_mod_info command for: {request.parameters?.ModName}");
                    var modInfo = GetModInfo(request.parameters?.ModName ?? "");
                    response.Append("\"status\":\"success\",");
                    response.Append("\"data\":{");
                    response.Append("\"name\":\"" + EscapeJsonString(modInfo.name) + "\",");
                    response.Append("\"enabled\":" + modInfo.enabled.ToString().ToLower() + ",");
                    response.Append("\"version\":\"" + EscapeJsonString(modInfo.version) + "\",");
                    response.Append("\"author\":\"" + EscapeJsonString(modInfo.author) + "\"");
                    response.Append("}");
                    Debug.Log($"Mod info data: {modInfo.name}, {modInfo.version}");
                    break;
                    
                default:
                    Debug.Log($"Unknown command: {request.command}");
                    response.Append("\"status\":\"error\",");
                    response.Append("\"message\":\"Unknown command\"");
                    break;
            }
            
            response.Append("}");
            string responseString = response.ToString();
            Debug.Log($"Response JSON: {responseString}");
            return responseString;
        }

        // 格式化ModInfo数组为JSON数组
        private string FormatModInfoArrayToJson(ModInfo[] array)
        {
            if (array == null || array.Length == 0)
                return "[]";
                
            var result = new System.Text.StringBuilder();
            result.Append("[");
            
            for (int i = 0; i < array.Length; i++)
            {
                if (i > 0)
                    result.Append(",");
                result.Append("{");
                result.Append("\"name\":\"" + EscapeJsonString(array[i].name) + "\",");
                result.Append("\"enabled\":" + array[i].enabled.ToString().ToLower() + ",");
                result.Append("\"version\":\"" + EscapeJsonString(array[i].version) + "\",");
                result.Append("\"author\":\"" + EscapeJsonString(array[i].author) + "\"");
                result.Append("}");
            }
            
            result.Append("]");
            return result.ToString();
        }

        // 转义JSON字符串
        private string EscapeJsonString(string str)
        {
            if (string.IsNullOrEmpty(str))
                return string.Empty;
            
            return str.Replace("\\", "\\\\").Replace("\"", "\\\"").Replace("\n", "\\n").Replace("\r", "\\r").Replace("\t", "\\t");
        }

        public ModInfo GetModInfo(string ModName)
        {
            // 获取指定mod的详细信息
            if (GameManager.ModManager != null && !string.IsNullOrEmpty(ModName))
            {
                Debug.Log($"Searching for mod: {ModName}");
                foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                {
                    Debug.Log($"Checking mod: {modInfo.name}");
                    if (modInfo.name == ModName)
                    {
                        Duckov.Modding.ModBehaviour modBehaviour;
                        bool isEnabled = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                        
                        Debug.Log($"Found mod: {modInfo.name}, enabled: {isEnabled}");
                        
                        return new ModInfo
                        {
                            name = modInfo.name,
                            enabled = isEnabled,
                            version = "1.0.0",
                            author = "Unknown"
                        };
                    }
                }
                Debug.Log($"Mod not found: {ModName}");
            }
            
            // 如果找不到mod，则返回默认信息
            Debug.Log($"Returning default info for mod: {ModName}");
            return new ModInfo
            {
                name = string.IsNullOrEmpty(ModName) ? "" : ModName,
                enabled = false,
                version = "1.0.0",
                author = "Unknown"
            };
        }

        public bool EnableMod(string ModName)
        {
            if (string.IsNullOrEmpty(ModName)) return false;

            var tcs = new TaskCompletionSource<bool>();
            mainThreadActions.Enqueue(() =>
            {
                try
                {
                    bool result = EnableMod_Internal(ModName);
                    tcs.SetResult(result);
                }
                catch (Exception ex)
                {
                    Debug.LogError($"EnableMod_Internal failed: {ex}");
                    tcs.SetResult(false);
                }
            });

            // 同步等待结果（子线程阻塞直到主线程完成）
            return tcs.Task.Result;
        }

        private bool EnableMod_Internal(string ModName)
        {
            // 实现启用mod的逻辑
            // 需要根据游戏API具体实现
            if (GameManager.ModManager != null && !string.IsNullOrEmpty(ModName))
            {
                Debug.Log($"Trying to enable mod: {ModName}");
                // 查找对应的ModInfo
                foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                {
                    Debug.Log($"Checking mod for enable: {modInfo.name}");
                    if (modInfo.name == ModName)
                    {
                        // 如果mod尚未激活，则激活它
                        Duckov.Modding.ModBehaviour modBehaviour;
                        bool isActive = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                        Debug.Log($"Mod {ModName} is currently {(isActive ? "active" : "inactive")}");
                        
                        if (!isActive)
                        {
                            var result = GameManager.ModManager.ActivateMod(modInfo);
                            Debug.Log($"ActivateMod result: {result != null}");
                            return result != null;
                        }
                        else
                        {
                            Debug.Log($"Mod {ModName} is already active");
                            return true;
                        }
                    }
                }
                Debug.Log($"Mod not found for enable: {ModName}");
                return false; // 添加明确的返回值
            }
            
            Debug.Log($"Failed to enable mod: {ModName}");
            return false;
        }

        public bool DisableMod(string ModName)
        {
            if (string.IsNullOrEmpty(ModName)) return false;

            var tcs = new TaskCompletionSource<bool>();
            mainThreadActions.Enqueue(() =>
            {
                try
                {
                    bool result = DisableMod_Internal(ModName);
                    tcs.SetResult(result);
                }
                catch (Exception ex)
                {
                    Debug.LogError($"DisableMod_Internal failed: {ex}");
                    tcs.SetResult(false);
                }
            });

            // 同步等待结果（子线程阻塞直到主线程完成）
            return tcs.Task.Result;
        }

        private bool DisableMod_Internal(string ModName)
        {
            // 实现禁用mod的逻辑
            // 需要根据游戏API具体实现
            if (GameManager.ModManager != null && !string.IsNullOrEmpty(ModName))
            {
                Debug.Log($"Trying to disable mod: {ModName}");
                // 查找对应的ModInfo
                foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                {
                    Debug.Log($"Checking mod for disable: {modInfo.name}");
                    if (modInfo.name == ModName)
                    {
                        // 如果mod当前是激活状态，则停用它
                        Duckov.Modding.ModBehaviour modBehaviour;
                        bool isActive = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                        Debug.Log($"Mod {ModName} is currently {(isActive ? "active" : "inactive")}");
                        
                        if (isActive && modBehaviour != null)
                        {
                            GameManager.ModManager.DeactivateMod(modInfo);
                            Debug.Log($"Deactivated mod: {ModName}");
                            return true;
                        }
                        else if (!isActive)
                        {
                            Debug.Log($"Mod {ModName} is already inactive");
                            return true;
                        }
                    }
                }
                Debug.Log($"Mod not found for disable: {ModName}");
                return false; // 添加明确的返回值
            }
            
            Debug.Log($"Failed to disable mod: {ModName}");
            return false;
        }

        public ModInfo[] GetModList()
        {
            // 获取当前所有已加载的mod列表及其启用状态
            if (GameManager.ModManager != null)
            {
                List<ModInfo> modInfos = new List<ModInfo>();
                foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                {
                    Duckov.Modding.ModBehaviour modBehaviour;
                    bool isEnabled = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                    
                    modInfos.Add(new ModInfo
                    {
                        name = modInfo.name,
                        enabled = isEnabled,
                        version = "1.0.0",
                        author = "Unknown"
                    });
                }
                return modInfos.ToArray();
            }
            
            // 如果无法获取实际列表，则返回示例数据
            return new ModInfo[] { 
                new ModInfo { name = "ModManagerBridge", enabled = true, version = "1.0.0", author = "Unknown" },
                new ModInfo { name = "ExampleMod", enabled = false, version = "1.0.0", author = "Unknown" },
                new ModInfo { name = "AnotherMod", enabled = false, version = "1.0.0", author = "Unknown" }
            };
        }

        private void StopTCPServer()
        {
            isRunning = false;
            
            // 关闭所有客户端连接
            foreach (var client in clients)
            {
                try { client.Close(); } catch { }
            }
            clients.Clear();
            
            // 停止监听器
            if (tcpListener != null)
            {
                tcpListener.Stop();
            }
            
            // 等待线程结束
            if (listenerThread != null && listenerThread.IsAlive)
            {
                listenerThread.Join(1000);
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
    }

    [Serializable]
    public class ModInfo
    {
        public string name = "";
        public bool enabled = false;
        public string version = "";
        public string author = "";
    }
}
