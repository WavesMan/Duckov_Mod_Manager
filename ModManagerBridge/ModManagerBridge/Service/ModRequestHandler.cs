using Duckov.Modding;
using System;
using System.Collections.Generic;
using UnityEngine;
using ModManagerBridge.Models;
using System.Text;
using System.Text.RegularExpressions;
using System.Linq;

namespace ModManagerBridge.Service
{
    public class ModRequestHandler
    {
        /// <summary>
        /// 处理WebSocket请求并返回响应
        /// </summary>
        public string ProcessRequest(WebSocketRequest request)
        {
            switch (request.action?.ToLower())
            {
                case "get_mod_list":
                    return HandleGetModList();
                    
                case "activate_mod":
                    return HandleActivateMod(request.data);
                    
                case "deactivate_mod":
                    return HandleDeactivateMod(request.data);
                    
                case "rescan_mods":
                    return HandleRescanMods();
                    
                case "activate_mods":
                    return HandleActivateMods(request.data);
                    
                case "deactivate_mods":
                    return HandleDeactivateMods(request.data);
                    
                default:
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = false, 
                        message = "未知操作: " + request.action 
                    });
            }
        }

        /// <summary>
        /// 处理获取mod列表
        /// </summary>
        private string HandleGetModList()
        {
            try
            {
                var modList = new List<ModInfoSerializable>();
                
                foreach (var modInfo in ModManager.modInfos)
                {
                    Duckov.Modding.ModBehaviour instance;
                    bool isActive = ModManager.IsModActive(modInfo, out instance);
                    
                    modList.Add(new ModInfoSerializable
                    {
                        name = modInfo.name,
                        displayName = modInfo.displayName,
                        description = modInfo.description,
                        path = modInfo.path,
                        isActive = isActive,
                        dllFound = modInfo.dllFound,
                        isSteamItem = modInfo.isSteamItem,
                        publishedFileId = modInfo.publishedFileId,
                        // 添加更多详细信息
                        dllPath = modInfo.dllPath,
                        hasPreview = modInfo.preview != null,
                        priority = ModManager.GetModPriority(modInfo.name)
                    });
                }
                
                // 手动构建JSON响应以避免Unity JsonUtility的限制
                var response = new WebSocketResponseWithData
                {
                    success = true,
                    message = "",
                    data = SerializeModList(modList)
                };
                
                return JsonUtility.ToJson(response);
            }
            catch (Exception ex)
            {
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "获取mod列表时出错: " + ex.Message 
                });
            }
        }

        /// <summary>
        /// 手动序列化mod列表为JSON字符串
        /// </summary>
        private string SerializeModList(List<ModInfoSerializable> modList)
        {
            var sb = new StringBuilder();
            sb.Append("[");
            
            for (int i = 0; i < modList.Count; i++)
            {
                if (i > 0) sb.Append(",");
                
                sb.Append("{");
                sb.Append("\"name\":\"").Append(EscapeJsonString(modList[i].name)).Append("\",");
                sb.Append("\"displayName\":\"").Append(EscapeJsonString(modList[i].displayName)).Append("\",");
                sb.Append("\"description\":\"").Append(EscapeJsonString(modList[i].description)).Append("\",");
                sb.Append("\"path\":\"").Append(EscapeJsonString(modList[i].path)).Append("\",");
                sb.Append("\"isActive\":").Append(modList[i].isActive ? "true" : "false").Append(",");
                sb.Append("\"dllFound\":").Append(modList[i].dllFound ? "true" : "false").Append(",");
                sb.Append("\"isSteamItem\":").Append(modList[i].isSteamItem ? "true" : "false").Append(",");
                sb.Append("\"publishedFileId\":").Append(modList[i].publishedFileId).Append(",");
                sb.Append("\"dllPath\":\"").Append(EscapeJsonString(modList[i].dllPath)).Append("\",");
                sb.Append("\"hasPreview\":").Append(modList[i].hasPreview ? "true" : "false").Append(",");
                sb.Append("\"priority\":").Append(modList[i].priority);
                sb.Append("}");
            }
            
            sb.Append("]");
            return sb.ToString();
        }

        /// <summary>
        /// 转义JSON字符串中的特殊字符
        /// </summary>
        private string EscapeJsonString(string str)
        {
            if (string.IsNullOrEmpty(str)) return "";
            
            return str.Replace("\\", "\\\\")
                     .Replace("\"", "\\\"")
                     .Replace("\n", "\\n")
                     .Replace("\r", "\\r")
                     .Replace("\t", "\\t")
                     .Replace("\b", "\\b")
                     .Replace("\f", "\\f");
        }

        /// <summary>
        /// 从带引号的字符串中提取mod名称
        /// </summary>
        private string ExtractModName(string quotedString)
        {
            if (string.IsNullOrEmpty(quotedString))
                return quotedString;

            // 使用正则表达式匹配带引号的字符串
            var match = Regex.Match(quotedString.Trim(), "^\"(.*)\"$");
            if (match.Success)
            {
                // 解码转义字符
                return match.Groups[1].Value.Replace("\\\"", "\"")
                                           .Replace("\\\\", "\\")
                                           .Replace("\\n", "\n")
                                           .Replace("\\r", "\r")
                                           .Replace("\\t", "\t");
            }
            
            // 如果没有引号，返回原始字符串
            return quotedString;
        }

        /// <summary>
        /// 处理激活mod
        /// </summary>
        private string HandleActivateMod(string modName)
        {
            try
            {
                // 提取mod名称（去除引号）
                string actualModName = ExtractModName(modName);
                
                // 查找mod
                ModInfo? targetMod = null;
                foreach (var modInfo in ModManager.modInfos)
                {
                    if (modInfo.name == actualModName)
                    {
                        targetMod = modInfo;
                        break;
                    }
                }
                
                if (!targetMod.HasValue)
                {
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = false, 
                        message = "未找到mod: " + actualModName 
                    });
                }
                
                // 激活mod
                var result = ModManager.Instance.ActivateMod(targetMod.Value);
                
                if (result != null)
                {
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = true, 
                        message = "Mod激活成功" 
                    });
                }
                else
                {
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = false, 
                        message = "无法激活mod" 
                    });
                }
            }
            catch (Exception ex)
            {
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "激活mod时出错: " + ex.Message 
                });
            }
        }

        /// <summary>
        /// 处理停用mod
        /// </summary>
        private string HandleDeactivateMod(string modName)
        {
            try
            {
                // 提取mod名称（去除引号）
                string actualModName = ExtractModName(modName);
                
                // 查找mod
                ModInfo? targetMod = null;
                foreach (var modInfo in ModManager.modInfos)
                {
                    if (modInfo.name == actualModName)
                    {
                        targetMod = modInfo;
                        break;
                    }
                }
                
                if (!targetMod.HasValue)
                {
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = false, 
                        message = "未找到mod: " + actualModName 
                    });
                }
                
                // 停用mod
                ModManager.Instance.DeactivateMod(targetMod.Value);
                
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = true, 
                    message = "Mod停用成功" 
                });
            }
            catch (Exception ex)
            {
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "停用mod时出错: " + ex.Message 
                });
            }
        }

        /// <summary>
        /// 处理批量激活mods
        /// </summary>
        private string HandleActivateMods(string modNamesJson)
        {
            try
            {
                // 解析JSON数组 - 使用更兼容的方法
                string[] modNames = ParseStringArray(modNamesJson);
                
                // 限制一次最多处理10个mods
                if (modNames.Length > 10)
                {
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = false, 
                        message = "一次最多只能激活10个mods" 
                    });
                }
                
                var successMods = new List<string>();
                var failedMods = new List<string>();
                
                foreach (string modName in modNames)
                {
                    // 提取mod名称（去除引号）
                    string actualModName = ExtractModName(modName);
                    
                    // 查找mod
                    ModInfo? targetMod = null;
                    foreach (var modInfo in ModManager.modInfos)
                    {
                        if (modInfo.name == actualModName)
                        {
                            targetMod = modInfo;
                            break;
                        }
                    }
                    
                    if (!targetMod.HasValue)
                    {
                        failedMods.Add(actualModName);
                        continue;
                    }
                    
                    // 激活mod
                    var result = ModManager.Instance.ActivateMod(targetMod.Value);
                    
                    if (result != null)
                    {
                        successMods.Add(actualModName);
                    }
                    else
                    {
                        failedMods.Add(actualModName);
                    }
                }
                
                string successList = string.Join("','", successMods);
                string failedList = string.Join("','", failedMods);
                
                string message = $"success: {successMods.Count}/{modNames.Length}.";
                if (successMods.Count > 0)
                    message += $" true: '{successList}'.";
                if (failedMods.Count > 0)
                    message += $" false: '{failedList}'.";
                
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = true, 
                    message = message
                });
            }
            catch (Exception ex)
            {
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "批量激活mods时出错: " + ex.Message 
                });
            }
        }

        /// <summary>
        /// 处理批量停用mods
        /// </summary>
        private string HandleDeactivateMods(string modNamesJson)
        {
            try
            {
                // 解析JSON数组 - 使用更兼容的方法
                string[] modNames = ParseStringArray(modNamesJson);
                
                // 限制一次最多处理10个mods
                if (modNames.Length > 10)
                {
                    return JsonUtility.ToJson(new WebSocketResponse { 
                        success = false, 
                        message = "一次最多只能停用10个mods" 
                    });
                }
                
                var successMods = new List<string>();
                var failedMods = new List<string>();
                
                foreach (string modName in modNames)
                {
                    // 提取mod名称（去除引号）
                    string actualModName = ExtractModName(modName);
                    
                    // 查找mod
                    ModInfo? targetMod = null;
                    foreach (var modInfo in ModManager.modInfos)
                    {
                        if (modInfo.name == actualModName)
                        {
                            targetMod = modInfo;
                            break;
                        }
                    }
                    
                    if (!targetMod.HasValue)
                    {
                        failedMods.Add(actualModName);
                        continue;
                    }
                    
                    // 停用mod
                    ModManager.Instance.DeactivateMod(targetMod.Value);
                    successMods.Add(actualModName);
                }
                
                string successList = string.Join("','", successMods);
                string failedList = string.Join("','", failedMods);
                
                string message = $"success: {successMods.Count}/{modNames.Length}.";
                if (successMods.Count > 0)
                    message += $" true: '{successList}'.";
                if (failedMods.Count > 0)
                    message += $" false: '{failedList}'.";
                
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = true, 
                    message = message
                });
            }
            catch (Exception ex)
            {
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "批量停用mods时出错: " + ex.Message 
                });
            }
        }

        /// <summary>
        /// 解析JSON字符串数组
        /// </summary>
        private string[] ParseStringArray(string jsonArray)
        {
            // 移除首尾的方括号
            string trimmed = jsonArray.Trim();
            if (trimmed.StartsWith("[") && trimmed.EndsWith("]"))
            {
                trimmed = trimmed.Substring(1, trimmed.Length - 2);
            }
            
            // 如果是空数组，直接返回空数组
            if (string.IsNullOrWhiteSpace(trimmed))
            {
                return new string[0];
            }
            
            // 分割字符串并去除引号
            var items = trimmed.Split(',');
            var result = new List<string>();
            
            foreach (var item in items)
            {
                string trimmedItem = item.Trim();
                // 去除引号
                if (trimmedItem.StartsWith("\"") && trimmedItem.EndsWith("\"") && trimmedItem.Length >= 2)
                {
                    trimmedItem = trimmedItem.Substring(1, trimmedItem.Length - 2);
                    // 处理转义字符
                    trimmedItem = trimmedItem.Replace("\\\"", "\"")
                                           .Replace("\\\\", "\\")
                                           .Replace("\\n", "\n")
                                           .Replace("\\r", "\r")
                                           .Replace("\\t", "\t");
                }
                result.Add(trimmedItem);
            }
            
            return result.ToArray();
        }

        /// <summary>
        /// 处理重新扫描mods
        /// </summary>
        private string HandleRescanMods()
        {
            try
            {
                ModManager.Rescan();
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = true, 
                    message = "Mods重新扫描成功" 
                });
            }
            catch (Exception ex)
            {
                return JsonUtility.ToJson(new WebSocketResponse { 
                    success = false, 
                    message = "重新扫描mods时出错: " + ex.Message 
                });
            }
        }
    }
}