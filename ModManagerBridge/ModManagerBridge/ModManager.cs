using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using UnityEngine;

namespace ModManagerBridge
{
    /// <summary>
    /// Mod管理器，负责处理Mod的状态管理
    /// </summary>
    public class ModManager
    {
        // 主线程任务队列
        private static readonly Queue<Action> mainThreadActions = new Queue<Action>();
        private const int BATCH_SIZE = 10; // 批量操作的批次大小
        private bool isDeveloperMode = false; // 开发者模式标志
        
        public bool IsDeveloperMode
        {            get => isDeveloperMode;
            set => isDeveloperMode = value;
        }
        
        /// <summary>
        /// 获取所有Mod的列表
        /// </summary>
        public ModInfo[] GetModList()
        {            try
            {                if (GameManager.ModManager != null)
                {                    List<ModInfo> modInfos = new List<ModInfo>();
                    foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                    {                        Duckov.Modding.ModBehaviour modBehaviour;
                        bool isEnabled = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                        
                        modInfos.Add(new ModInfo
                        {                            name = modInfo.name,
                            mod_id = modInfo.name, // 使用name作为mod_id，确保兼容性
                            enabled = isEnabled,
                            version = GetModVersion(modInfo),
                            author = GetModAuthor(modInfo)
                        });
                    }
                    return modInfos.ToArray();
                }
                
                // 如果无法获取实际列表，返回空数组
                Debug.LogWarning("GameManager.ModManager is null, returning empty mod list");
                return Array.Empty<ModInfo>();
            }
            catch (Exception ex)
            {                Debug.LogError($"Error getting mod list: {ex.Message}");
                return Array.Empty<ModInfo>();
            }
        }
        
        /// <summary>
        /// 获取单个Mod的信息
        /// </summary>
        public ModInfo GetModInfo(string modName)
        {            try
            {                if (GameManager.ModManager != null && !string.IsNullOrEmpty(modName))
                {                    foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                    {                        if (modInfo.name == modName)
                        {                            Duckov.Modding.ModBehaviour modBehaviour;
                            bool isEnabled = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                            
                            return new ModInfo
                            {                                name = modInfo.name,
                                mod_id = modInfo.name,
                                enabled = isEnabled,
                                version = GetModVersion(modInfo),
                                author = GetModAuthor(modInfo)
                            };
                        }
                    }
                }
                
                // 返回默认信息
                return new ModInfo
                {                    name = string.IsNullOrEmpty(modName) ? "" : modName,
                    mod_id = string.IsNullOrEmpty(modName) ? "" : modName,
                    enabled = false,
                    version = "1.0.0",
                    author = "Unknown"
                };
            }
            catch (Exception ex)
            {                Debug.LogError($"Error getting mod info: {ex.Message}");
                return new ModInfo
                {                    name = string.IsNullOrEmpty(modName) ? "" : modName,
                    mod_id = string.IsNullOrEmpty(modName) ? "" : modName,
                    enabled = false,
                    version = "1.0.0",
                    author = "Unknown"
                };
            }
        }
        
        /// <summary>
        /// 启用指定的Mod
        /// </summary>
        public bool EnableMod(string modName)
        {            if (string.IsNullOrEmpty(modName))
            {                Debug.LogWarning("Mod name cannot be empty");
                return false;
            }
            
            try
            {                bool result = RunOnMainThread(() => EnableModInternal(modName));
                
                // 如果成功启用，且不是开发者模式，禁用原生mod管理器
                if (result && !isDeveloperMode)
                {                    DisableNativeModManager();
                }
                
                return result;
            }
            catch (Exception ex)
            {                Debug.LogError($"Error enabling mod {modName}: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// 禁用指定的Mod
        /// </summary>
        public bool DisableMod(string modName)
        {            if (string.IsNullOrEmpty(modName))
            {                Debug.LogWarning("Mod name cannot be empty");
                return false;
            }
            
            try
            {                return RunOnMainThread(() => DisableModInternal(modName));
            }
            catch (Exception ex)
            {                Debug.LogError($"Error disabling mod {modName}: {ex.Message}");
                return false;
            }
        }
        /// <summary>
        /// 批量启用/禁用Mod
        /// </summary>
        public BatchOperationResult BatchUpdateMods(string[] modNames, bool enabled)
        {            var result = new BatchOperationResult
            {                SuccessCount = 0,
                FailedCount = 0,
                FailedMods = new List<string>()
            };
            
            if (modNames == null || modNames.Length == 0)
            {                Debug.LogWarning("Mod names array cannot be empty");
                return result;
            }
            
            // 分批处理
            for (int i = 0; i < modNames.Length; i += BATCH_SIZE)
            {                int currentBatchSize = Math.Min(BATCH_SIZE, modNames.Length - i);
                string[] currentBatch = new string[currentBatchSize];
                Array.Copy(modNames, i, currentBatch, 0, currentBatchSize);
                
                // 处理当前批次
                var batchResult = ProcessBatch(currentBatch, enabled);
                
                // 合并结果
                result.SuccessCount += batchResult.SuccessCount;
                result.FailedCount += batchResult.FailedCount;
                result.FailedMods.AddRange(batchResult.FailedMods);
                
                // 添加延迟以避免性能问题
                if (i + BATCH_SIZE < modNames.Length)
                {                    Task.Delay(100).Wait(); // 100ms延迟
                }
            }
            
            // 如果有成功启用的mod，且不是开发者模式，禁用原生mod管理器
            if (enabled && result.SuccessCount > 0 && !isDeveloperMode)
            {                DisableNativeModManager();
            }
            
            return result;
        }
        
        /// <summary>
        /// 处理单个批次的Mod操作
        /// </summary>
        private BatchOperationResult ProcessBatch(string[] modNames, bool enabled)
        {            var result = new BatchOperationResult
            {                SuccessCount = 0,
                FailedCount = 0,
                FailedMods = new List<string>()
            };
            
            foreach (var modName in modNames)
            {                bool operationResult = enabled ? EnableMod(modName) : DisableMod(modName);
                
                if (operationResult)
                {                    result.SuccessCount++;
                }
                else
                {                    result.FailedCount++;
                    result.FailedMods.Add(modName);
                }
            }
            
            return result;
        }
        
        /// <summary>
        /// 主线程启用Mod的内部方法
        /// </summary>
        private bool EnableModInternal(string modName)
        {            try
            {                if (GameManager.ModManager != null && !string.IsNullOrEmpty(modName))
                {                    foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                    {                        if (modInfo.name == modName)
                        {                            Duckov.Modding.ModBehaviour modBehaviour;
                            bool isActive = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                            
                            if (!isActive)
                            {                                var result = GameManager.ModManager.ActivateMod(modInfo);
                                Debug.Log($"Mod {modName} enabled: {result != null}");
                                return result != null;
                            }
                            else
                            {                                Debug.Log($"Mod {modName} is already enabled");
                                return true; // 已经启用，视为成功
                            }
                        }
                    }
                    Debug.LogWarning($"Mod {modName} not found");
                    return false;
                }
                Debug.LogWarning("GameManager.ModManager is null");
                return false;
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in EnableModInternal for {modName}: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// 主线程禁用Mod的内部方法
        /// </summary>
        private bool DisableModInternal(string modName)
        {            try
            {                if (GameManager.ModManager != null && !string.IsNullOrEmpty(modName))
                {                    foreach (var modInfo in Duckov.Modding.ModManager.modInfos)
                    {                        if (modInfo.name == modName)
                        {                            Duckov.Modding.ModBehaviour modBehaviour;
                            bool isActive = Duckov.Modding.ModManager.IsModActive(modInfo, out modBehaviour);
                            
                            if (isActive && modBehaviour != null)
                            {                                GameManager.ModManager.DeactivateMod(modInfo);
                                Debug.Log($"Mod {modName} disabled");
                                return true;
                            }
                            else if (!isActive)
                            {                                Debug.Log($"Mod {modName} is already disabled");
                                return true; // 已经禁用，视为成功
                            }
                        }
                    }
                    Debug.LogWarning($"Mod {modName} not found");
                    return false;
                }
                Debug.LogWarning("GameManager.ModManager is null");
                return false;
            }
            catch (Exception ex)
            {                Debug.LogError($"Error in DisableModInternal for {modName}: {ex.Message}");
                return false;
            }
        }
        
        /// <summary>
        /// 在主线程上运行操作
        /// </summary>
        private bool RunOnMainThread(Func<bool> action)
        {            var tcs = new TaskCompletionSource<bool>();
            
            // 将操作添加到主线程队列
            lock (mainThreadActions)
            {                mainThreadActions.Enqueue(() =>
                {                    try
                    {                        bool result = action();
                        tcs.SetResult(result);
                    }
                    catch (Exception ex)
                    {                        Debug.LogError($"Main thread action error: {ex.Message}");
                        tcs.SetResult(false);
                    }
                });
            }
            
            // 同步等待结果
            return tcs.Task.Result;
        }
        
        /// <summary>
        /// 处理主线程队列中的操作
        /// </summary>
        public static void ProcessMainThreadActions()
        {            lock (mainThreadActions)
            {                while (mainThreadActions.Count > 0)
                {                    var action = mainThreadActions.Dequeue();
                    try
                    {                        action();
                    }
                    catch (Exception ex)
                    {                        Debug.LogError($"Error in main thread action: {ex.Message}");
                    }
                }
            }
        }
        
        /// <summary>
        /// 禁用原生mod管理器
        /// </summary>
        private void DisableNativeModManager()
        {            try
            {                // 这里实现禁用原生mod管理器的逻辑
                // 具体实现需要根据游戏API调整
                Debug.Log("Native mod manager disabled");
            }
            catch (Exception ex)
            {                Debug.LogError($"Error disabling native mod manager: {ex.Message}");
            }
        }
        
        /// <summary>
        /// 获取Mod版本
        /// </summary>
        private string GetModVersion(Duckov.Modding.ModInfo modInfo)
        {            try
            {                // 尝试从mod信息中获取版本
                // 如果无法获取，返回默认版本
                return "1.0.0";
            }
            catch
            {                return "1.0.0";
            }
        }
        
        /// <summary>
        /// 获取Mod作者
        /// </summary>
        private string GetModAuthor(Duckov.Modding.ModInfo modInfo)
        {            try
            {                // 尝试从mod信息中获取作者
                // 如果无法获取，返回Unknown
                return "Unknown";
            }
            catch
            {                return "Unknown";
            }
        }
    }
    
    /// <summary>
    /// 批量操作结果类
    /// </summary>
    public class BatchOperationResult
    {
        public int SuccessCount { get; set; }
        public int FailedCount { get; set; }
        public List<string> FailedMods { get; set; }
        
        /// <summary>
        /// 转换为JSON字符串
        /// </summary>
        public string ToJson()
        {            var failedModsJson = "[" + string.Join(",", FailedMods.ConvertAll(m => $"\"{MessageHandler.EscapeJsonString(m)}\"")) + "]";
            return $"{{\"success_count\":{SuccessCount},\"failed_count\":{FailedCount},\"failed_mods\":{failedModsJson}}}";
        }
    }
}