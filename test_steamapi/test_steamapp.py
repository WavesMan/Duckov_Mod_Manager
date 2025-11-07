import requests
from bs4 import BeautifulSoup

def analyze_workshop_page_structure(item_url):
    print(f"Analyzing workshop page structure for: {item_url}")
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    response = requests.get(item_url, headers=headers)
    
    if response.status_code != 200:
        print(f"Failed to retrieve the page. Status code: {response.status_code}")
        return
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # 分析页面的基本结构
    print("\n=== Page Structure Analysis ===")
    
    # 查找所有带ID的div
    divs_with_id = soup.find_all('div', id=True)
    print(f"Total divs with IDs: {len(divs_with_id)}")
    for div in divs_with_id:
        print(f"  ID: {div.get('id')} - Classes: {div.get('class')}")
    
    # 查找所有带class的div
    divs_with_class = soup.find_all('div', class_=True)
    print(f"\nTotal divs with classes: {len(divs_with_class)}")
    
    # 查找特定关键词
    relevant_elements = []
    for div in divs_with_class:
        class_list = div.get('class') if isinstance(div.get('class'), list) else [div.get('class')]
        if any(keyword in str(class_list).lower() for keyword in ['require', 'depend', 'item']):
            relevant_elements.append((div.get('id'), class_list))
    
    print(f"Relevant elements (containing 'require', 'depend', 'item' in class names): {len(relevant_elements)}")
    for elem_id, classes in relevant_elements:
        print(f"  ID: {elem_id}, Classes: {classes}")
    
    # 查找所有的script标签，看看是否有相关的JavaScript数据
    script_tags = soup.find_all('script')
    print(f"\nTotal script tags: {len(script_tags)}")
    
    # 查找包含工作坊相关数据的脚本
    workshop_scripts = []
    for i, script in enumerate(script_tags):
        script_text = script.string or ''
        if any(keyword in script_text.lower() for keyword in ['workshop', 'required', 'depend']):
            workshop_scripts.append(i)
            print(f"  Script {i} contains workshop-related keywords")
            if len(script_text) < 500:  # 只打印较短的脚本内容
                print(f"    Content preview: {script_text[:200]}...")
    
    # 查看整个页面中是否包含依赖相关的词汇
    page_text = response.text.lower()
    keywords = ['require', 'depend', 'subscription']
    for keyword in keywords:
        count = page_text.count(keyword)
        print(f"Keyword '{keyword}' appears {count} times in page")

# 测试几个不同的创意工坊链接
test_urls = [
    "https://steamcommunity.com/sharedfiles/filedetails/?id=111111111",  # 替换为真实的有依赖项的项目
    "https://steamcommunity.com/sharedfiles/filedetails/?id=222222222"   # 替换为另一个项目
]

# 用一个已知有依赖项的例子
example_url = "https://steamcommunity.com/sharedfiles/filedetails/?id=3591341282"  # 这是一个有依赖项的模组示例

analyze_workshop_page_structure(example_url)
