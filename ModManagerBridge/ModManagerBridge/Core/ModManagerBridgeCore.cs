using Duckov.Modding;
using UnityEngine;
using System.Text;
using System.Collections.Generic;
using ModManagerBridge.WebSocket;
using System;

namespace ModManagerBridge.Core
{
    public class ModManagerBridgeCore
    {
        private readonly int port = 9001;
        private WebSocketServer server;
        private int requestsPerSecond = 20;
        private int itemsPerSecond = 50;
        
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
            Unsubscribe();
            server = null;
        }
        
        public int GetPort()
        {
            return port;
        }

        public int GetRequestsPerSecond()
        {
            return requestsPerSecond;
        }

        public int GetItemsPerSecond()
        {
            return itemsPerSecond;
        }

        private readonly object queueLock = new object();
        private readonly Queue<Action> mainThreadQueue = new Queue<Action>();

        public void RunOnMainThread(Action action)
        {
            if (action == null) return;
            lock (queueLock)
            {
                mainThreadQueue.Enqueue(action);
            }
        }

        public void PumpPendingTasks()
        {
            while (true)
            {
                Action a = null;
                lock (queueLock)
                {
                    if (mainThreadQueue.Count == 0) break;
                    a = mainThreadQueue.Dequeue();
                }
                try
                {
                    a?.Invoke();
                }
                catch (Exception ex)
                {
                    Debug.LogError("主线程任务执行错误: " + ex.Message);
                }
            }
        }

        public void SetServer(WebSocketServer s)
        {
            server = s;
            Subscribe();
        }

        private void Subscribe()
        {
            ModManager.OnScan += OnScan;
            ModManager.OnReorder += OnReorder;
            ModManager.OnModActivated += OnModActivatedHandler;
            ModManager.OnModWillBeDeactivated += OnModDeactivatedHandler;
            ModManager.OnModStatusChanged += OnStatusChanged;
        }

        private void Unsubscribe()
        {
            ModManager.OnScan -= OnScan;
            ModManager.OnReorder -= OnReorder;
            ModManager.OnModActivated -= OnModActivatedHandler;
            ModManager.OnModWillBeDeactivated -= OnModDeactivatedHandler;
            ModManager.OnModStatusChanged -= OnStatusChanged;
        }

        private void Broadcast(string type, string dataJson)
        {
            if (server == null) return;
            var sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"type\":\"").Append(type).Append("\",");
            sb.Append("\"data\":").Append(dataJson);
            sb.Append("}");
            server.Broadcast(sb.ToString());
        }

        private string GetOrderJson()
        {
            var names = new List<string>();
            var priorities = new StringBuilder();
            priorities.Append("{");
            bool first = true;
            foreach (var info in ModManager.modInfos)
            {
                names.Add(info.name);
                int p = ModManager.GetModPriority(info.name);
                if (!first) priorities.Append(",");
                priorities.Append("\"").Append(info.name).Append("\":").Append(p);
                first = false;
            }
            priorities.Append("}");
            var sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"names\":[");
            for (int i = 0; i < names.Count; i++)
            {
                if (i > 0) sb.Append(",");
                sb.Append("\"").Append(names[i]).Append("\"");
            }
            sb.Append("],\"priorities\":").Append(priorities.ToString());
            sb.Append("}");
            return sb.ToString();
        }

        private void OnScan(List<ModInfo> list)
        {
            var sb = new StringBuilder();
            sb.Append("{");
            sb.Append("\"mods\":[");
            for (int i = 0; i < list.Count; i++)
            {
                var info = list[i];
                if (i > 0) sb.Append(",");
                sb.Append("{");
                sb.Append("\"name\":\"").Append(info.name).Append("\",");
                sb.Append("\"priority\":").Append(ModManager.GetModPriority(info.name));
                sb.Append("}");
            }
            sb.Append("]");
            sb.Append("}");
            Broadcast("scan", sb.ToString());
        }

        private void OnReorder()
        {
            Broadcast("reorder", GetOrderJson());
        }

        private void OnModActivatedHandler(Duckov.Modding.ModInfo info, Duckov.Modding.ModBehaviour behaviour)
        {
            Broadcast("mod_activated", "{\"name\":\"" + info.name + "\"}");
        }

        private void OnModDeactivatedHandler(Duckov.Modding.ModInfo info, Duckov.Modding.ModBehaviour behaviour)
        {
            Broadcast("mod_deactivated", "{\"name\":\"" + info.name + "\"}");
        }

        private void OnStatusChanged()
        {
            int active = 0;
            foreach (var info in ModManager.modInfos)
            {
                Duckov.Modding.ModBehaviour inst;
                if (ModManager.IsModActive(info, out inst) && inst != null) active++;
            }
            Broadcast("status_changed", "{\"active\":" + active + "}");
        }
    }
}