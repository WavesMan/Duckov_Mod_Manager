# Steam创意工坊爬虫

这个项目提供了一个用于爬取Steam创意工坊物品信息的Python脚本，支持多种排序方式。

## 功能特点

1. **多种排序方式**：
   - 最多订阅 (most_popular)
   - 最高评分 (top_rated)
   - 最新 (newest)
   - 最近更新 (last_updated)

2. **分页支持**：
   - 支持指定页码爬取
   - 自动获取总页数信息

3. **信息提取**：
   - 物品ID和URL
   - 物品名称
   - 预览图像URL
   - 作者信息
   - 评分信息
   - 订阅数和收藏数

## 使用方法

```python
from workshop_scraper import SteamWorkshopScraper

# 创建爬虫实例
scraper = SteamWorkshopScraper()

# 获取指定游戏的创意工坊物品
result = scraper.get_workshop_items(
    app_id="3167020",    # 游戏ID
    sort_by="most_popular",  # 排序方式
    page=1               # 页码
)

# 显示结果
scraper.display_items(result)
```

## 返回数据结构

函数返回一个字典，包含以下键：

- `items`: 物品信息列表
- `current_page`: 当前页码
- `total_pages`: 总页数

每个物品包含以下信息：

```python
{
    'id': '物品ID',
    'name': '物品名称',
    'url': '物品链接',
    'preview_url': '预览图像链接',
    'author': '作者名称',
    'author_link': '作者链接',
    'rating': 0.0,        # 评分
    'rating_count': 0,    # 评分人数
    'subscriptions': 0,   # 订阅数
    'favorites': 0        # 收藏数
}
```

## URL参数说明

不同排序方式使用不同的URL参数：

- 最多订阅: `browsesort=totaluniquesubscribers&actualsort=totaluniquesubscribers`
- 最高评分: `browsesort=rating&actualsort=rating`
- 最新: `browsesort=mostrecent&actualsort=mostrecent`
- 最近更新: `browsesort=lastupdated&actualsort=lastupdated`

每页默认显示30个物品。

## 依赖库

- requests
- beautifulsoup4

安装依赖：

```bash
pip install requests beautifulsoup4
```