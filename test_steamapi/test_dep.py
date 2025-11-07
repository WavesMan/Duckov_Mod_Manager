import requests
from bs4 import BeautifulSoup
import re

def get_steam_workshop_dependencies_final(item_id):
    """
    最终版本的Steam创意工坊依赖项获取函数
    """
    url = f"https://steamcommunity.com/sharedfiles/filedetails/?id={item_id}"
    print(f"正在获取创意工坊物品 {item_id} 的依赖项...")
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    
    try:
        response = requests.get(url, headers=headers, timeout=15)
        response.raise_for_status()
    except requests.RequestException as e:
        print(f"获取页面时出错: {e}")
        return None
    
    soup = BeautifulSoup(response.text, 'html.parser')
    dependencies = []
    
    # 根据你的分析，依赖项应该在id为"RequiredItems"的div中
    required_items_container = soup.find('div', id='RequiredItems')
    
    if required_items_container:
        print("找到依赖项容器")
        
        # 直接查找所有包含依赖项的<a>标签
        dependency_links = required_items_container.find_all('a', href=re.compile(r'/workshop/filedetails/\?id=\d+'))
        
        print(f"找到 {len(dependency_links)} 个依赖项链接")
        
        # 处理每个依赖项链接
        for i, link in enumerate(dependency_links):
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
                    else:
                        print(f"  ⚠ 跳过重复依赖项: {name}")
                else:
                    print(f"  ⚠ 无效或自引用链接: {href}")
            else:
                print(f"  ⚠ 链接缺少href或名称: {link}")
    else:
        print("未在HTML中找到依赖项容器")
        print("这可能意味着:")
        print("1. 该物品没有依赖项")
        print("2. 依赖项通过AJAX动态加载")
        print("3. 需要登录才能查看依赖项")
        
        # 尝试查找任何工作坊链接作为备选
        all_links = soup.find_all('a', href=re.compile(r'/sharedfiles/filedetails/\?id=\d+'))
        print(f"找到 {len(all_links)} 个工作坊链接作为备选")
        
        for link in all_links:
            href = link.get('href')
            name = link.get_text(strip=True)
            if href and name and str(item_id) not in href:  # 排除自己
                id_match = re.search(r'id=(\d+)', href)
                if id_match:
                    dep_id = id_match.group(1)
                    dependencies.append({
                        'name': name,
                        'url': f"https://steamcommunity.com{href}" if href.startswith('/') else href,
                        'id': dep_id,
                        'subscribed': 'unknown'
                    })
    
    return dependencies

# 测试最终版本
print("=== Steam 创意工坊依赖项提取器 ===")
dependencies = get_steam_workshop_dependencies_final("3591341282")

if dependencies is not None:
    if dependencies:
        print(f"\n需要订阅的必选物品 | [{len(dependencies)} 个]")
        for i, dep in enumerate(dependencies, 1):
            print(f"{i}. {dep['name']}")
            print(f"   ID: {dep['id']}")
            print(f"   URL: {dep['url']}")
            print(f"   Subscribed: {dep['subscribed']}")
            print()
    else:
        print("该物品没有找到依赖项。")
        print("对于没有依赖项的物品，这是正常情况。")
else:
    print("由于错误，无法获取依赖项。")
