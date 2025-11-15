using Duckov.Modding;
using ModManagerBridge.Core;
using ModManagerBridge.WebSocket;

namespace ModManagerBridge
{
    public class ModBehaviour : Duckov.Modding.ModBehaviour
    {
        private WebSocketServer webSocketServer;
        private ModManagerBridgeCore core;

        void Start()
        {
            // 初始化核心
            core = new ModManagerBridgeCore();
            core.Initialize();
            
            // 初始化WebSocket服务器用于mod管理
            webSocketServer = new WebSocketServer(core, core.GetPort());
            webSocketServer.InitializeWebSocketServer();
        }

        void OnDestroy()
        {
            // 清理核心
            if (core != null)
            {
                core.Cleanup();
            }
            
            // 停止WebSocket服务器
            if (webSocketServer != null)
            {
                webSocketServer.StopServer();
            }
        }
    }
}