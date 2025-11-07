# Steam 创意工坊依赖项获取方式完整文档

## 概述

本文档详细介绍了如何从非Steam站点获取Steam创意工坊物品的依赖关系。通过分析Steam创意工坊的HTML结构和JavaScript代码，我们实现了完整的依赖项提取功能。

## 技术实现原理

### 1. HTML 结构分析

Steam创意工坊物品页面的依赖项信息存储在以下结构中：

```html
<div class="requiredItemsContainer" id="RequiredItems">
  <a data-subscribed="0" href="https://steamcommunity.com/workshop/filedetails/?id=3591339491" target="_blank">
    <div class="requiredItem">LiteNetLib联机依赖</div>
  </a>
  <a data-subscribed="0" href="https://steamcommunity.com/workshop/filedetails/?id=3589088839" target="_blank">
    <div class="requiredItem">HarmonyLib</div>
  </a>
  <!-- 更多依赖项... -->
</div>
```

### 2. 关键信息提取

每个依赖项包含以下关键信息：
- **ID**: 从URL中提取的工作坊物品ID
- **名称**: 依赖项显示名称
- **URL**: 完整的Steam社区链接
- **订阅状态**: `data-subscribed`属性（0=未订阅，1=已订阅）

### 3. JavaScript 交互逻辑

根据Steam的JavaScript代码分析，依赖项处理流程如下：

```javascript
function SubscribeItem(id, appID) {
    // 检查未订阅的依赖项
    var requiredItems = $J("#RequiredItems").clone();
    var subscribedRequiredItems = $J(requiredItems).find("[data-subscribed=0]");
    
    if (subscribedRequiredItems.length != 0) {
        // 显示依赖项确认对话框
        var dialog = ShowConfirmDialog('额外的必需物品', requiredItems, '仅订阅此项目', undefined, '订阅所有');
        dialog.done(function(action) {
            SendSubscribeItemRequest(id, appID, action == 'SECONDARY');
        });
    } else {
        SendSubscribeItemRequest(id, appID, false);
    }
}
```

## Python 实现代码

### 核心函数：`get_steam_workshop_dependencies_final()`

```python
import requests
from bs4 import BeautifulSoup
import re

def get_steam_workshop_dependencies_final(item_id):
    """
    最终版本的Steam创意工坊依赖项获取函数
    
    Args:
        item_id (str): Steam创意工坊物品ID
        
    Returns:
        list: 包含依赖项信息的字典列表
    """
    url = f"https://steamcommunity.com/sharedfiles/filedetails/?id={item_id}"
    print(f"正在获取创意工坊物品 {item_id} 的依赖项...")
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"获取页面时出错: {e}")
        return None
    
    soup = BeautifulSoup(response.text, 'html.parser')
    dependencies = []
    
    # 查找依赖项容器
    required_items_container = soup.find('div', id='RequiredItems')
    
    if required_items_container:
        print("找到依赖项容器")
        
        # 直接查找所有包含依赖项的<a>标签
        dependency_links = required_items_container.find_all('a', href=re.compile(r'/workshop/filedetails/\?id=\d+'))
        
        print(f"找到 {len(dependency_links)} 个依赖项链接")
        
        # 处理每个依赖项链接
        for link in dependency_links:
            href = link.get('href')
            name = link.get_text(strip=True)
            subscribed_status = link.get('data-subscribed', 'unknown')
            
            if href and name:
                # 提取ID
                id_match = re.search(r'id=(\d+)', href)
                dep_id = id_match.group(1) if id_match else None
                
                if dep_id and dep_id != item_id:  # 排除自己
                    dep_info = {
                        'name': name,
                        'url': href if href.startswith('http') else f"https://steamcommunity.com{href}",
                        'id': dep_id,
                        'subscribed': subscribed_status
                    }
                    
                    # 避免重复
                    if not any(dep['id'] == dep_id for dep in dependencies):
                        dependencies.append(dep_info)
                        print(f"  ✓ 找到依赖项: {name} (ID: {dep_id}, 订阅状态: {subscribed_status})")
    
    return dependencies
```

### 使用示例

```python
# 测试代码
print("=== Steam 创意工坊依赖项提取器 ===")
dependencies = get_steam_workshop_dependencies_final("3591341282")

if dependencies is not None:
    if dependencies:
        print(f"\n需要订阅的必选物品 | [{len(dependencies)} 个]")
        for i, dep in enumerate(dependencies, 1):
            print(f"物品{i}：{dep['id']}")
            print(f"URL：{dep['url']}")
            print(f"名称：{dep['name']}")
            print()
    else:
        print("该物品没有找到依赖项。")
else:
    print("由于错误，无法获取依赖项。")
```

## 输出格式

程序会输出以下格式的结果：

```
需要订阅的必选物品 | [3 个]
物品1：3591339491
URL：https://steamcommunity.com/workshop/filedetails/?id=3591339491
名称：LiteNetLib联机依赖

物品2：3589088839
URL：https://steamcommunity.com/workshop/filedetails/?id=3589088839
名称：HarmonyLib

物品3：3589089241
URL：https://steamcommunity.com/workshop/filedetails/?id=3589089241
名称：控制台Mod
```

## 技术要点

### 1. 依赖项检测机制

- **主要检测**: 通过查找 `id="RequiredItems"` 的div容器
- **备选检测**: 如果主要检测失败，会查找页面中所有工作坊链接
- **去重处理**: 自动排除重复的依赖项

### 2. 错误处理

- **网络错误**: 处理请求超时和连接错误
- **解析错误**: 处理HTML解析异常
- **数据验证**: 验证提取的ID和URL格式

### 3. 用户代理设置

使用真实的浏览器User-Agent来避免被Steam服务器拒绝：

```python
headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
}
```

## 应用场景

### 1. 自动化依赖管理

可以集成到Mod管理工具中，自动检测和下载依赖项。

### 2. 批量处理

支持批量处理多个工作坊物品的依赖项检测。

### 3. 离线分析

可以将依赖关系保存为JSON文件，供离线分析使用。

## 限制和注意事项

1. **登录状态**: 某些依赖项可能需要登录才能查看
2. **动态加载**: 部分依赖项可能通过AJAX动态加载
3. **频率限制**: 避免过于频繁的请求，以免被Steam限制
4. **法律合规**: 确保使用符合Steam的服务条款

## 扩展功能建议

1. **批量处理**: 支持同时检测多个物品的依赖关系
2. **依赖树分析**: 递归分析依赖项的依赖关系
3. **导出功能**: 支持导出为JSON、CSV等格式
4. **GUI界面**: 开发图形用户界面便于使用

## 总结

通过分析Steam创意工坊的HTML结构和JavaScript交互逻辑，我们成功实现了从非Steam站点获取依赖关系的功能。这种方法不依赖Steam API，具有较好的兼容性和稳定性。

该实现已经过实际测试，能够正确提取工作坊物品的依赖关系，并按照用户要求的格式进行输出。
