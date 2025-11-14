using System;
using System.Collections.Generic;
using System.Net;using System.Threading.Tasks;
using UnityEngine;
using WebSocketSharp;
using WebSocketSharp.Server;

namespace ModManagerBridge
{
    /// <summary>
    /// WebSocket服务器管理器，负责WebSocket连接的建立和管理
    /// </summary>
    public class WebSocketServerManager
    {
        private WebSocketServer? webSocketServer;
        private List<ModManagerWebSocketBehavior> connectedClients = new List<ModManagerWebSocketBehavior>();
        private const int DEFAULT_PORT = 38274;
        private int port;
        private bool isRunning = false;
        
        // 事件定义
        public event Action<ModManagerWebSocketBehavior> OnClientConnected;
        public event Action<ModManagerWebSocketBehavior> OnClientDisconnected;
        public event Action<string, ModManagerWebSocketBehavior> OnMessageReceived;
        
        public int Port => port;
        public bool IsRunning => isRunning;
        public int ClientCount => connectedClients.Count;
        
        /// <summary>
        /// 构造函数
        /// </summary>
        /// <param name="customPort">自定义端口，默认为38274</param>
        public WebSocketServerManager(int customPort = DEFAULT_PORT)
        {
            this.port = customPort;
        }
        
        /// <summary>
        /// 初始化WebSocket服务器
        /// </summary>
        public bool Initialize()
        {            try
            {                webSocketServer = new WebSocketServer(IPAddress.Loopback, port);
                
                // 注册WebSocket行为
                webSocketServer.AddWebSocketService<ModManagerWebSocketBehavior>("/modmanager", behavior => 
                {                    behavior.OnClientConnected += HandleClientConnected;
                    behavior.OnClientDisconnected += HandleClientDisconnected;
                    behavior.OnMessageReceived += HandleMessageReceived;
                });
                
                isRunning = true;
                webSocketServer.Start();
                
                Debug.Log($"ModManagerBridge WebSocket server started on ws://localhost:{port}/modmanager");
                return true;
            }
            catch (Exception ex)
            {                Debug.LogError($"Failed to start WebSocket server: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// 停止WebSocket服务器
        /// </summary>
        public void Stop()
        {            isRunning = false;
            
            // 停止WebSocket服务器
            if (webSocketServer != null)
            {                webSocketServer.Stop();
            }
            
            // 清空客户端列表
            lock (connectedClients)
            {                connectedClients.Clear();
            }
            
            Debug.Log("WebSocket server stopped");
        }
        
        /// <summary>
        /// 处理客户端连接
        /// </summary>
        private void HandleClientConnected(ModManagerWebSocketBehavior client)
        {            lock (connectedClients)
            {                connectedClients.Add(client);
            }
            
            Debug.Log($"Client connected: {client.ClientId}");
            OnClientConnected?.Invoke(client);
        }
        
        /// <summary>
        /// 处理客户端断开连接
        /// </summary>
        private void HandleClientDisconnected(ModManagerWebSocketBehavior client)
        {            lock (connectedClients)
            {                connectedClients.Remove(client);
            }
            
            Debug.Log($"Client disconnected: {client.ClientId}");
            OnClientDisconnected?.Invoke(client);
        }
        
        /// <summary>
        /// 处理接收到的消息
        /// </summary>
        private void HandleMessageReceived(string message, ModManagerWebSocketBehavior client)
        {            Debug.Log($"Received message from client {client.ClientId}: {message}");
            OnMessageReceived?.Invoke(message, client);
        }
        
        /// <summary>
        /// 广播消息给所有连接的客户端
        /// </summary>
        public void BroadcastMessage(string message)
        {            lock (connectedClients)
            {                foreach (var client in connectedClients)
                {                    try
                    {                        client.SendResponse(message);
                    }
                    catch (Exception ex)
                    {                        Debug.LogError($"Error broadcasting message to client {client.ClientId}: {ex.Message}");
                    }
                }
            }
        }
        
        /// <summary>
        /// 向指定客户端发送消息
        /// </summary>
        public bool SendToClient(string clientId, string message)
        {            lock (connectedClients)
            {                var client = connectedClients.Find(c => c.ClientId == clientId);
                if (client != null)
                {                    client.SendResponse(message);
                    return true;
                }
            }
            
            Debug.LogWarning($"Client with ID {clientId} not found");
            return false;
        }
        
        /// <summary>
        /// 获取所有连接的客户端ID列表
        /// </summary>
        public List<string> GetConnectedClientIds()
        {            List<string> ids = new List<string>();
            lock (connectedClients)
            {                foreach (var client in connectedClients)
                {                    ids.Add(client.ClientId);
                }
            }
            return ids;
        }
    }
    
    /// <summary>
    /// WebSocket行为类，处理单个WebSocket连接
    /// </summary>
    public class ModManagerWebSocketBehavior : WebSocketBehavior
    {
        // 连接状态
        private bool isConnected = false;
        private string clientId = Guid.NewGuid().ToString();
        
        // 事件定义
        public event Action<ModManagerWebSocketBehavior> OnClientConnected;
        public event Action<ModManagerWebSocketBehavior> OnClientDisconnected;
        public event Action<string, ModManagerWebSocketBehavior> OnMessageReceived;
        
        // 连接建立时调用
        protected override void OnOpen()
        {            base.OnOpen();
            isConnected = true;
            Debug.Log($"WebSocket connection opened for client {clientId}");
            
            // 触发连接事件
            OnClientConnected?.Invoke(this);
        }
        
        // 连接关闭时调用
        protected override void OnClose(CloseEventArgs e)
        {            base.OnClose(e);
            isConnected = false;
            Debug.Log($"WebSocket connection closed for client {clientId}: {e.Reason}");
            
            // 触发断开连接事件
            OnClientDisconnected?.Invoke(this);
        }
        
        // 收到消息时调用
        protected override void OnMessage(MessageEventArgs e)
        {            base.OnMessage(e);
            
            if (e.IsText && !string.IsNullOrEmpty(e.Data))
            {                Debug.Log($"Received message from client {clientId}: {e.Data}");
                
                // 触发消息接收事件
                OnMessageReceived?.Invoke(e.Data, this);
            }
        }
        
        // 发生错误时调用
        protected override void OnError(ErrorEventArgs e)
        {            base.OnError(e);
            Debug.LogError($"WebSocket error for client {clientId}: {e.Message}");
            if (e.Exception != null)
            {
                Debug.LogError($"Error exception: {e.Exception}");
            }
        }
        
        // 发送响应给客户端
        public void SendResponse(string response)
        {            try
            {                if (isConnected && State == WebSocketState.Open)
                {                    Send(response);
                    Debug.Log($"Sent response to client {clientId}: {response}");
                }
                else
                {                    Debug.LogWarning($"Cannot send response to disconnected client {clientId}");
                }
            }
            catch (Exception ex)
            {                Debug.LogError($"Error sending response to client {clientId}: {ex.Message}");
            }
        }
        
        // 获取客户端ID
        public string ClientId => clientId;
        
        // 获取连接状态
        public bool IsConnected => isConnected;
    }
}