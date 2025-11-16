using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using UnityEngine;
using ModManagerBridge.Core;

namespace ModManagerBridge.WebSocket
{
    public class WebSocketServer
    {
        private TcpListener tcpListener;
        private Thread listenerThread;
        private List<WebSocketConnection> connections = new List<WebSocketConnection>();
        private bool isServerRunning = false;
        private readonly int port;
        private ModManagerBridgeCore modCore;

        public WebSocketServer(ModManagerBridgeCore modCore, int port)
        {
            this.modCore = modCore;
            this.port = port;
        }

        /// <summary>
        /// 初始化WebSocket服务器用于mod管理
        /// </summary>
        public void InitializeWebSocketServer()
        {
            try
            {
                tcpListener = new TcpListener(IPAddress.Any, port);
                listenerThread = new Thread(ListenForClients);
                listenerThread.IsBackground = true;
                listenerThread.Start();
                isServerRunning = true;
                
                Debug.Log($"WebSocket服务器启动，端口: {port}");
            }
            catch (Exception ex)
            {
                Debug.LogError($"无法启动WebSocket服务器: {ex.Message}");
            }
        }

        /// <summary>
        /// 监听客户端连接
        /// </summary>
        private void ListenForClients()
        {
            tcpListener.Start();
            Debug.Log($"WebSocket服务器开始监听，端口: {port}");
            
            while (isServerRunning)
            {
                try
                {
                    TcpClient client = tcpListener.AcceptTcpClient();
                    var remote = client?.Client?.RemoteEndPoint?.ToString() ?? "未知地址";
                    WebSocketConnection connection = new WebSocketConnection(client, modCore);
                    connections.Add(connection);
                    
                    Thread clientThread = new Thread(connection.HandleClient);
                    clientThread.IsBackground = true;
                    clientThread.Start();
                    
                    Debug.Log($"新的WebSocket客户端已连接，远端: {remote}，当前连接数: {connections.Count}");
                }
                catch (Exception ex)
                {
                    if (isServerRunning)
                    {
                        Debug.LogError($"接受客户端时出错: {ex.Message}");
                    }
                }
            }
            Debug.Log("WebSocket服务器停止监听");
        }

        public void StopServer()
        {
            isServerRunning = false;
            
            if (tcpListener != null)
            {
                tcpListener.Stop();
            }
            
            // 关闭所有连接
            Debug.Log($"WebSocket服务器停止中，关闭连接数: {connections.Count}");
            foreach (var connection in connections)
            {
                connection.Close();
            }
            
            connections.Clear();
            Debug.Log("WebSocket服务器已停止");
        }
    }
}