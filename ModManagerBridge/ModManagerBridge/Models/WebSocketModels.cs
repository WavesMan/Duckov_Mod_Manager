using System;
using UnityEngine;

namespace ModManagerBridge.Models
{
    /// <summary>
    /// WebSocket请求模型
    /// </summary>
    [Serializable]
    public class WebSocketRequest
    {
        public string action;
        public string data;
    }

    /// <summary>
    /// WebSocket响应模型
    /// </summary>
    [Serializable]
    public class WebSocketResponse
    {
        public bool success;
        public string message;
    }

    /// <summary>
    /// 带数据的WebSocket响应模型
    /// </summary>
    [Serializable]
    public class WebSocketResponseWithData
    {
        public bool success;
        public string message;
        public string data; // 使用字符串存储JSON数据
    }

    /// <summary>
    /// 可序列化的ModInfo版本，用于JSON序列化
    /// </summary>
    [Serializable]
    public class ModInfoSerializable
    {
        public string name;
        public string displayName;
        public string description;
        public string path;
        public bool isActive;
        public bool dllFound;
        public bool isSteamItem;
        public ulong publishedFileId;
        // 添加更多详细信息
        public string dllPath;
        public bool hasPreview;
        public int priority;
    }
}