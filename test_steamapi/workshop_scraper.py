import requests
from bs4 import BeautifulSoup
import re
from typing import List, Dict, Optional


class SteamWorkshopScraper:
    """
    Steam创意工坊爬虫类，支持按不同方式排序爬取物品信息
    """

    def __init__(self):
        self.base_url = "https://steamcommunity.com/workshop/browse/"
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        # 排序参数映射
        self.sort_params = {
            'most_popular': 'totaluniquesubscribers',  # 最多订阅
            'top_rated': 'rating',                     # 最高评分
            'newest': 'mostrecent',                    # 最新
            'last_updated': 'lastupdated'              # 最近更新
        }

    def get_workshop_items(self, app_id: str, sort_by: str = 'most_popular', 
                          search_term: str = '', page: int = 1) -> Optional[Dict]:
        """
        获取Steam创意工坊物品信息
        
        Args:
            app_id: 游戏ID (例如: 730 for CS:GO, 440 for TF2等)
            sort_by: 排序方式 ('most_popular', 'top_rated', 'newest', 'last_updated')
            search_term: 搜索关键词
            page: 页码
            
        Returns:
            包含物品信息列表和分页信息的字典
        """
        if sort_by not in self.sort_params:
            raise ValueError(f"不支持的排序方式: {sort_by}. 支持的方式: {list(self.sort_params.keys())}")

        # 构建URL
        params = {
            'appid': app_id,
            'section': 'readytouseitems',
            'actualsort': self.sort_params[sort_by],
            'p': page,
            'browsesort': self.sort_params[sort_by]
        }
        
        if search_term:
            params['searchtext'] = search_term

        # 构建完整的URL
        url = self.base_url + '?' + '&'.join([f'{k}={v}' for k, v in params.items()])

        print(f"正在获取创意工坊物品信息...")
        print(f"URL: {url}")
        print(f"排序方式: {sort_by}")

        try:
            response = requests.get(url, headers=self.headers, timeout=15)
            response.raise_for_status()
        except requests.RequestException as e:
            print(f"获取页面时出错: {e}")
            return None

        soup = BeautifulSoup(response.text, 'html.parser')
        items = []

        # 查找物品容器
        item_elements = soup.find_all('div', class_='workshopItem')
        
        print(f"找到 {len(item_elements)} 个物品")

        for item_element in item_elements:
            try:
                # 提取物品信息
                item_info = self._extract_item_info(item_element)
                if item_info:
                    items.append(item_info)
            except Exception as e:
                print(f"解析物品时出错: {e}")
                continue

        # 获取分页信息
        total_pages = self._extract_pagination_info(soup)
        
        return {
            'items': items,
            'current_page': page,
            'total_pages': total_pages
        }

    def _extract_item_info(self, item_element) -> Optional[Dict]:
        """
        从HTML元素中提取单个物品信息
        """
        try:
            # 提取物品ID和URL
            link_element = item_element.find('a', class_='ugc')
            if not link_element:
                return None

            url = link_element.get('href', '')
            item_id = link_element.get('data-publishedfileid', '')
            
            # 提取物品名称
            title_element = item_element.find('div', class_='workshopItemTitle')
            name = title_element.get_text(strip=True) if title_element else '未知名称'

            # 提取预览图像
            image_element = item_element.find('img', class_='workshopItemPreviewImage')
            preview_url = image_element.get('src', '') if image_element else ''

            # 提取作者信息
            author_element = item_element.find('div', class_='workshopItemAuthorName')
            author = ''
            author_link = ''
            if author_element:
                author_link_element = author_element.find('a')
                if author_link_element:
                    author = author_link_element.get_text(strip=True)
                    author_link = author_link_element.get('href', '')

            # 提取评分信息 (简化处理，实际评分信息可能需要从其他地方获取)
            rating = 0.0
            rating_count = 0
            # 由于页面结构复杂，这里简化处理评分信息

            # 提取订阅数和收藏数（这些信息在浏览页面可能不直接可见）
            subscriptions = 0
            favorites = 0

            item_info = {
                'id': item_id,
                'name': name,
                'url': url,
                'preview_url': preview_url,
                'author': author,
                'author_link': author_link,
                'rating': rating,
                'rating_count': rating_count,
                'subscriptions': subscriptions,
                'favorites': favorites
            }

            return item_info
        except Exception as e:
            print(f"提取物品信息时出错: {e}")
            return None

    def _extract_pagination_info(self, soup) -> int:
        """
        从HTML中提取分页信息
        """
        try:
            pagination_controls = soup.find('div', class_='workshopBrowsePagingControls')
            if not pagination_controls:
                return 1
                
            # 查找所有页码链接
            page_links = pagination_controls.find_all('a', class_='pagelink')
            if not page_links:
                return 1
                
            # 提取最大的页码数
            max_page = 1
            for link in page_links:
                href = link.get('href', '')
                page_match = re.search(r'&p=(\d+)', href)
                if page_match:
                    page_num = int(page_match.group(1))
                    max_page = max(max_page, page_num)
                    
            return max_page
        except Exception as e:
            print(f"提取分页信息时出错: {e}")
            return 1

    def display_items(self, result: Dict, sort_by: str = 'most_popular'):
        """
        显示物品信息
        """
        items = result.get('items', [])
        current_page = result.get('current_page', 1)
        total_pages = result.get('total_pages', 1)
        
        if not items:
            print("未找到任何物品。")
            return

        print(f"\n=== 按'{sort_by}'排序的物品信息 ===")
        print(f"共找到 {len(items)} 个物品 (第 {current_page} 页，共 {total_pages} 页)\n")

        for i, item in enumerate(items, 1):
            print(f"{i}. {item['name']}")
            print(f"   ID: {item['id']}")
            print(f"   URL: {item['url']}")
            print(f"   作者: {item['author']}")
            if item['rating'] > 0:
                print(f"   评分: {item['rating']} ({item['rating_count']} 评价)")
            if item['subscriptions'] > 0:
                print(f"   订阅数: {item['subscriptions']:,}")
            if item['favorites'] > 0:
                print(f"   收藏数: {item['favorites']:,}")
            print()


def main():
    """
    主函数 - 示例用法
    """
    scraper = SteamWorkshopScraper()
    
    # 示例：获取Duckov Game的创意工坊物品，按不同方式排序
    app_id = "3167020"  # Duckov Game的App ID
    
    # 按最热门排序
    print("=" * 50)
    print("测试Steam创意工坊爬虫")
    print("=" * 50)
    
    sort_methods = ['most_popular', 'top_rated', 'newest', 'last_updated']
    
    for sort_method in sort_methods:
        print(f"\n{'-' * 30}")
        print(f"按 {sort_method} 排序")
        print(f"{'-' * 30}")
        
        result = scraper.get_workshop_items(app_id=app_id, sort_by=sort_method, page=1)
        if result is not None:
            scraper.display_items(result, sort_method)
        else:
            print("获取物品失败")


if __name__ == "__main__":
    main()