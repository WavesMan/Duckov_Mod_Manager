using Duckov.Modding;
using UnityEngine;

namespace ModManagerBridge.Core
{
    public class ModManagerBridgeCore
    {
        private readonly int port = 9001;
        
        public ModManagerBridgeCore()
        {
            // 构造函数
        }

        public void Initialize()
        {
            Debug.Log("ModManagerBridge已加载！");
        }

        public void Cleanup()
        {
            // 清理资源
        }
        
        public int GetPort()
        {
            return port;
        }
    }
}