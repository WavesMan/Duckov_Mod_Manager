# pages/steam_workshop_page.py
import flet as ft
import sys
import os

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from theme_manager import get_theme_colors
from services.steam_workshop_service import SteamWorkshopService
import asyncio
from typing import Dict, List, Optional


def heading(text, level=1, color=None):
    """
    创建标题文本
    
    Args:
        text (str): 标题文本
        level (int): 标题级别 (1-6)
        color (str, optional): 文本颜色，默认使用主题颜色
        
    Returns:
        ft.Text: 配置好的标题文本控件
    """
    colors = get_theme_colors()
    if color is None:
        color = colors["text_primary"]
    
    # 根据标题级别设置大小和样式
    sizes = {1: 32, 2: 28, 3: 24, 4: 20, 5: 18, 6: 16}
    weights = {1: ft.FontWeight.BOLD, 2: ft.FontWeight.BOLD, 3: ft.FontWeight.BOLD,
               4: ft.FontWeight.NORMAL, 5: ft.FontWeight.NORMAL, 6: ft.FontWeight.NORMAL}
    
    return ft.Text(
        text,
        size=sizes.get(level, 16),
        weight=weights.get(level, ft.FontWeight.NORMAL),
        color=color,
        font_family="MiSans"
    )


def body(text, size=14, color=None, weight=ft.FontWeight.NORMAL):
    """
    创建正文文本
    
    Args:
        text (str): 正文文本
        size (int): 字体大小
        color (str, optional): 文本颜色，默认使用主题颜色
        weight (ft.FontWeight): 字体粗细
        
    Returns:
        ft.Text: 配置好的正文文本控件
    """
    colors = get_theme_colors()
    if color is None:
        color = colors["text_primary"]
        
    return ft.Text(
        text,
        size=size,
        color=color,
        weight=weight,
        font_family="MiSans"
    )


def caption(text, size=12, color=None):
    """
    创建说明文字
    
    Args:
        text (str): 说明文字
        size (int): 字体大小
        color (str, optional): 文本颜色，默认使用主题颜色
        
    Returns:
        ft.Text: 配置好的说明文字控件
    """
    colors = get_theme_colors()
    if color is None:
        color = colors["text_secondary"]
        
    return ft.Text(
        text,
        size=size,
        color=color,
        font_family="MiSans"
    )


def primary_button(text, on_click=None, width=None, height=None):
    """
    创建主要操作按钮
    
    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        width (int, optional): 按钮宽度
        height (int, optional): 按钮高度
        
    Returns:
        ft.ElevatedButton: 配置好的主要按钮
    """
    colors = get_theme_colors()
    return ft.ElevatedButton(
        text=text,
        on_click=on_click,
        width=width,
        height=height,
        style=ft.ButtonStyle(
            color=ft.Colors.WHITE,
            bgcolor=colors["primary"],
            text_style=ft.TextStyle(font_family="MiSans")
        ),
    )


def secondary_button(text, on_click=None, width=None, height=None):
    """
    创建次要操作按钮
    
    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        width (int, optional): 按钮宽度
        height (int, optional): 按钮高度
        
    Returns:
        ft.OutlinedButton: 配置好的次要按钮
    """
    colors = get_theme_colors()
    return ft.OutlinedButton(
        text=text,
        on_click=on_click,
        width=width,
        height=height,
        style=ft.ButtonStyle(
            color=colors["primary"],
            side=ft.BorderSide(1, colors["primary"]),
            text_style=ft.TextStyle(font_family="MiSans")
        ),
    )


class SteamWorkshopPage:
    """Steam创意工坊页面类"""
    
    def __init__(self, page: ft.Page):
        self.page = page
        self.service = SteamWorkshopService()
        self.app_id = "3167020"  # Duckov Game的App ID
        
        # 预加载数据存储
        self.preloaded_data = {
            'most_popular': {},
            'top_rated': {},
            'newest': {},
            'last_updated': {}
        }
        
        # 当前显示的数据
        self.current_data = {
            'items': [],
            'current_page': 1,
            'total_pages': 1,
            'sort_by': 'most_popular',
            'search_term': ''
        }
        
        # UI控件
        self.search_field = None
        self.sort_dropdown = None
        self.items_grid = None
        self.pagination_controls = None
        self.loading_indicator = None
        self.error_message = None
        self.top_button = None  # 回顶按钮
        self.scrollable_column = None  # 滚动列引用
        
        # 初始化预加载
        self._init_preloading()

    def _init_preloading(self):
        """初始化预加载数据"""
        # 预加载将在页面加载后通过其他方式触发
        pass

    def start_preloading(self):
        """开始预加载数据（使用多线程IO同步预载）"""
        import concurrent.futures
        import threading
        
        def preload_single_page(sort_method, page_num):
            """预加载单个页面"""
            try:
                # 使用线程安全的同步方式获取数据
                result = self.service.get_workshop_items(
                    self.app_id, sort_method, '', page_num
                )
                if result:
                    # 使用线程锁确保数据安全
                    with threading.Lock():
                        if sort_method not in self.preloaded_data:
                            self.preloaded_data[sort_method] = {}
                        self.preloaded_data[sort_method][page_num] = result
                    print(f"预加载完成: {sort_method} 第{page_num}页")
                    return True
            except Exception as e:
                print(f"预加载失败 {sort_method} 第{page_num}页: {e}")
            return False
        
        def preload_all_data():
            """多线程预加载所有数据"""
            sort_methods = ['most_popular', 'top_rated', 'newest', 'last_updated']
            
            # 使用线程池执行预加载任务
            with concurrent.futures.ThreadPoolExecutor(max_workers=8) as executor:
                # 创建所有预加载任务
                futures = []
                for sort_method in sort_methods:
                    for page_num in range(1, 4):  # 预加载1-3页
                        future = executor.submit(preload_single_page, sort_method, page_num)
                        futures.append(future)
                
                # 等待所有任务完成
                completed_count = 0
                for future in concurrent.futures.as_completed(futures):
                    try:
                        result = future.result()
                        if result:
                            completed_count += 1
                    except Exception as e:
                        print(f"预加载任务异常: {e}")
                
                print(f"预加载完成: {completed_count}/{len(futures)} 个页面")
        
        # 在新线程中执行预加载，避免阻塞UI
        preload_thread = threading.Thread(target=preload_all_data, daemon=True)
        preload_thread.start()

    async def start_preloading_async(self):
        """异步版本的预加载启动函数"""
        # 在执行器中运行同步的预加载函数
        await asyncio.get_event_loop().run_in_executor(None, self._start_preloading_blocking)

    def _start_preloading_blocking(self):
        """在阻塞模式下运行预加载"""
        self.start_preloading()

    def smart_preload(self, sort_by: str, current_page: int, total_pages: int):
        """
        智能预加载后续页面数据
        当用户切换到某一页时，预加载该页后面的页面
        """
        import concurrent.futures
        import threading
        
        def preload_single_page(sort_method, page_num):
            """预加载单个页面"""
            try:
                # 检查是否已经预加载过
                if (sort_method in self.preloaded_data and 
                    page_num in self.preloaded_data[sort_method]):
                    return True
                    
                # 使用线程安全的同步方式获取数据
                result = self.service.get_workshop_items(
                    self.app_id, sort_method, '', page_num
                )
                if result:
                    # 使用线程锁确保数据安全
                    with threading.Lock():
                        if sort_method not in self.preloaded_data:
                            self.preloaded_data[sort_method] = {}
                        self.preloaded_data[sort_method][page_num] = result
                    print(f"智能预加载完成: {sort_method} 第{page_num}页")
                    return True
            except Exception as e:
                print(f"智能预加载失败 {sort_method} 第{page_num}页: {e}")
            return False
        
        def preload_next_pages():
            """预加载后续页面"""
            # 预加载当前页之后的页面
            pages_to_preload = []
            for i in range(1, 4):  # 预加载后续3页
                next_page = current_page + i
                if next_page <= total_pages:
                    pages_to_preload.append(next_page)
            
            # 使用线程池执行预加载任务
            with concurrent.futures.ThreadPoolExecutor(max_workers=3) as executor:
                # 创建预加载任务
                futures = []
                for page_num in pages_to_preload:
                    future = executor.submit(preload_single_page, sort_by, page_num)
                    futures.append(future)
                
                # 等待所有任务完成
                completed_count = 0
                for future in concurrent.futures.as_completed(futures):
                    try:
                        result = future.result()
                        if result:
                            completed_count += 1
                    except Exception as e:
                        print(f"智能预加载任务异常: {e}")
                
                print(f"智能预加载完成: {completed_count}/{len(futures)} 个页面")
        
        # 在新线程中执行预加载，避免阻塞UI
        if current_page < total_pages:  # 只有当前页不是最后一页时才预加载
            preload_thread = threading.Thread(target=preload_next_pages, daemon=True)
            preload_thread.start()

    async def _fetch_workshop_items(self, sort_by: str, search_term: str, page: int) -> Optional[Dict]:
        """获取创意工坊物品信息"""
        try:
            # 检查预加载数据
            if (search_term == '' and 
                sort_by in self.preloaded_data and 
                page in self.preloaded_data[sort_by]):
                return self.preloaded_data[sort_by][page]
            
            # 如果没有预加载数据，则实时获取
            result = await asyncio.get_event_loop().run_in_executor(
                None, 
                self.service.get_workshop_items,
                self.app_id, sort_by, search_term, page
            )
            return result
        except Exception as e:
            print(f"获取创意工坊数据失败: {e}")
            return None

    def _create_search_controls(self):
        """创建搜索和排序控件"""
        colors = get_theme_colors()
        
        # 搜索框
        self.search_field = ft.TextField(
            label="搜索模组...",
            icon=ft.Icons.SEARCH,
            on_submit=self._on_search,
            expand=True,
            border_radius=8
        )
        
        # 排序下拉框
        self.sort_dropdown = ft.Dropdown(
            label="排序方式",
            options=[
                ft.dropdown.Option("most_popular", "最热门"),
                ft.dropdown.Option("top_rated", "最高评分"),
                ft.dropdown.Option("newest", "最新"),
                ft.dropdown.Option("last_updated", "最近更新")
            ],
            value="most_popular",
            on_change=self._on_sort_change,
            width=150,
            border_radius=8
        )
        
        # 搜索按钮
        search_button = ft.ElevatedButton(
            text="搜索",
            on_click=self._on_search,
            icon=ft.Icons.SEARCH,
            style=ft.ButtonStyle(
                color=ft.Colors.WHITE,
                bgcolor=colors["primary"],
                text_style=ft.TextStyle(font_family="MiSans")
            ),
            width=100
        )
        
        return ft.Row(
            controls=[
                self.search_field,
                self.sort_dropdown,
                search_button
            ],
            spacing=10,
            alignment=ft.MainAxisAlignment.START
        )

    def _create_mod_card(self, mod_info: Dict) -> ft.Control:
        """创建单个模组卡片"""
        colors = get_theme_colors()
        
        # 模组标题
        title = heading(mod_info.get('name', '未知模组'), level=4)
        
        # 作者信息
        author_text = body(f"作者: {mod_info.get('author', '未知')}")
        
        # 描述信息（不截断，完整显示）
        description = mod_info.get('description', '暂无描述')
        description_text = caption(description)
        
        # 评分信息
        rating = mod_info.get('rating', 0)
        rating_count = mod_info.get('rating_count', 0)
        rating_text = caption(f"评分: {rating} ({rating_count} 评价)") if rating > 0 else caption("暂无评分")
        
        # 订阅信息
        subscriptions = mod_info.get('subscriptions', 0)
        subscriptions_text = caption(f"订阅数: {subscriptions:,}") if subscriptions > 0 else caption("")
        
        # 左侧图片部分 - 1:1比例显示
        preview_url = mod_info.get('preview_url', '')
        image_container = ft.Container()
        if preview_url:
            image_container = ft.Container(
                content=ft.Image(
                    src=preview_url,
                    width=120,
                    height=120,
                    fit=ft.ImageFit.CONTAIN,
                ),
                width=120,
                height=120,
                alignment=ft.alignment.center,
                padding=5,
            )
        
        # 右侧详细信息部分
        details_column = ft.Column(
            controls=[
                title,
                author_text,
                description_text,
                rating_text,
                subscriptions_text
            ],
            spacing=4,
            expand=True,
        )
        
        # 操作按钮
        actions = [
            ft.ElevatedButton("查看详情", width=100, height=30, style=ft.ButtonStyle(
                color=ft.Colors.WHITE,
                bgcolor=colors["primary"],
                text_style=ft.TextStyle(font_family="MiSans")
            )),
            ft.OutlinedButton("下载", width=80, height=30, style=ft.ButtonStyle(
                color=colors["primary"],
                side=ft.BorderSide(1, colors["primary"]),
                text_style=ft.TextStyle(font_family="MiSans")
            ))
        ]
        
        # 按钮行
        buttons_row = ft.Row(
            controls=actions,
            spacing=5,
            alignment=ft.MainAxisAlignment.END,
        )
        
        # 组合左右两部分
        content_row = ft.Row(
            controls=[
                image_container,
                ft.Column(
                    controls=[
                        details_column,
                        buttons_row
                    ],
                    spacing=10,
                    expand=True,
                )
            ],
            spacing=10,
            expand=True,
        )
        
        # 创建卡片
        return ft.Card(
            content=ft.Container(
                content=content_row,
                padding=10,
                # 移除固定宽度，使卡片可以自适应布局
            ),
            margin=5,
        )

    def _create_items_grid(self, items: List[Dict]) -> ft.Control:
        """创建模组展示网格"""
        if not items:
            return ft.Column([
                ft.Icon(ft.Icons.SEARCH_OFF, size=64, color=get_theme_colors()["text_secondary"]),
                heading("未找到模组", level=3),
                body("请尝试调整搜索条件或排序方式")
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=20)
        
        # 创建模组卡片
        mod_cards = [self._create_mod_card(mod) for mod in items]
        
        # 使用ResponsiveRow实现双栏布局，并统一卡片高度
        responsive_controls = []
        for i, card in enumerate(mod_cards):
            responsive_controls.append(
                ft.Container(
                    content=card,
                    col={"xs": 12, "sm": 12, "md": 6},  # 在中等及以上屏幕上每行显示2个卡片
                    height=200,  # 统一卡片高度
                )
            )
        
        responsive_row = ft.ResponsiveRow(
            controls=responsive_controls,
            spacing=10,
            run_spacing=10
        )
        
        return responsive_row

    def _create_pagination_controls(self) -> ft.Control:
        """创建分页控件"""
        current_page = self.current_data['current_page']
        total_pages = self.current_data['total_pages']
        
        if total_pages <= 1:
            return ft.Container()  # 只有一页时不显示分页
        
        colors = get_theme_colors()
        
        # 页码显示
        page_info = body(f"第 {current_page} 页，共 {total_pages} 页")
        
        # 分页按钮 - 直接使用Flet原生按钮，因为primary_button不支持disabled参数
        prev_button = ft.ElevatedButton(
            text="上一页",
            on_click=lambda e: self._on_page_change(current_page - 1),
            style=ft.ButtonStyle(
                color=ft.Colors.WHITE,
                bgcolor=colors["primary"] if current_page > 1 else colors["text_secondary"],
                text_style=ft.TextStyle(font_family="MiSans")
            ),
            width=80,
            disabled=(current_page <= 1)
        )
        
        next_button = ft.ElevatedButton(
            text="下一页",
            on_click=lambda e: self._on_page_change(current_page + 1),
            style=ft.ButtonStyle(
                color=ft.Colors.WHITE,
                bgcolor=colors["primary"] if current_page < total_pages else colors["text_secondary"],
                text_style=ft.TextStyle(font_family="MiSans")
            ),
            width=80,
            disabled=(current_page >= total_pages)
        )
        
        return ft.Row(
            controls=[
                prev_button,
                page_info,
                next_button
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20
        )

    def _create_loading_indicator(self) -> ft.Control:
        """创建加载指示器"""
        return ft.Column(
            controls=[
                ft.ProgressRing(),
                body("正在加载模组数据...")
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=10
        )

    def _create_error_message(self, message: str) -> ft.Control:
        """创建错误消息"""
        return ft.Column(
            controls=[
                ft.Icon(ft.Icons.ERROR_OUTLINE, size=48, color="red"),
                heading("加载失败", level=3),
                body(message)
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=10
        )

    def _scroll_to_top(self, e):
        """滚动到顶部"""
        # 使用scrollable_column的滚动控制回到顶部
        if self.scrollable_column:
            self.scrollable_column.scroll_to(offset=0, duration=300)

    def _create_top_button(self):
        """创建回顶按钮"""
        colors = get_theme_colors()
        self.top_button = ft.Container(
            content=ft.ElevatedButton(
                text="TOP",
                on_click=self._scroll_to_top,
                style=ft.ButtonStyle(
                    color=ft.Colors.WHITE,
                    bgcolor=colors["primary"],
                    text_style=ft.TextStyle(font_family="MiSans")
                ),
                width=60,
                height=60,
            ),
            width=60,
            height=60,
            border_radius=30,
            alignment=ft.alignment.center,
            # 按钮初始隐藏
            visible=False,
        )
        return self.top_button

    async def _load_workshop_items(self, sort_by: str = None, search_term: str = None, page: int = None):
        """加载创意工坊物品"""
        # 更新加载状态
        self.loading_indicator.visible = True
        self.error_message.visible = False
        self.items_grid.visible = False
        self.pagination_controls.visible = False
        # 隐藏回顶按钮
        if self.top_button:
            self.top_button.visible = False
        self.page.update()
        
        # 更新参数
        if sort_by is not None:
            self.current_data['sort_by'] = sort_by
            self.sort_dropdown.value = sort_by
        if search_term is not None:
            self.current_data['search_term'] = search_term
            self.search_field.value = search_term
        if page is not None:
            self.current_data['current_page'] = page
        
        try:
            # 获取数据
            result = await self._fetch_workshop_items(
                self.current_data['sort_by'],
                self.current_data['search_term'],
                self.current_data['current_page']
            )
            
            if result:
                self.current_data.update(result)
                
                # 更新UI
                self.items_grid.content = self._create_items_grid(result['items'])
                self.pagination_controls.content = self._create_pagination_controls()
                
                self.loading_indicator.visible = False
                self.items_grid.visible = True
                self.pagination_controls.visible = True
                # 显示回顶按钮
                if self.top_button:
                    self.top_button.visible = True
                
                # 智能预加载后续页面
                self.smart_preload(
                    self.current_data['sort_by'],
                    self.current_data['current_page'],
                    self.current_data['total_pages']
                )
            else:
                self.loading_indicator.visible = False
                self.error_message.visible = True
                self.error_message.content = self._create_error_message("无法获取模组数据，请检查网络连接")
                
        except Exception as e:
            self.loading_indicator.visible = False
            self.error_message.visible = True
            self.error_message.content = self._create_error_message(f"加载失败: {str(e)}")
        
        self.page.update()

    def _on_search(self, e=None):
        """搜索事件处理"""
        search_term = self.search_field.value.strip()
        # 使用 page.run_task 来处理异步任务
        self.page.run_task(self._load_workshop_items, search_term=search_term, page=1)

    def _on_sort_change(self, e):
        """排序方式改变事件处理"""
        sort_by = self.sort_dropdown.value
        # 使用 page.run_task 来处理异步任务
        self.page.run_task(self._load_workshop_items, sort_by=sort_by, page=1)

    def _on_page_change(self, page: int):
        """页码改变事件处理"""
        # 使用 page.run_task 来处理异步任务
        self.page.run_task(self._load_workshop_items, page=page)

    def create_view(self) -> ft.Control:
        """创建页面视图"""
        colors = get_theme_colors()
        
        # 创建控件
        search_controls = self._create_search_controls()
        self.loading_indicator = ft.Container(
            content=self._create_loading_indicator(),
            visible=False
        )
        self.error_message = ft.Container(
            content=self._create_error_message(""),
            visible=False
        )
        self.items_grid = ft.Container(
            content=ft.Container(),  # 空容器，稍后填充
            visible=False
        )
        self.pagination_controls = ft.Container(
            content=ft.Container(),  # 空容器，稍后填充
            visible=False
        )
        
        # 页面内容
        content = [
            heading("Steam创意工坊", level=1),
            body("浏览和下载Duckov游戏的创意工坊模组"),
            
            ft.Divider(height=20),
            
            search_controls,
            
            ft.Divider(height=20),
            
            self.loading_indicator,
            self.error_message,
            self.items_grid,
            self.pagination_controls
        ]
        
        # 使用可滚动页面布局，直接保存对Column的引用
        self.scrollable_column = ft.Column(
            controls=content,
            scroll=ft.ScrollMode.AUTO,
            horizontal_alignment=ft.CrossAxisAlignment.START,
            spacing=10,
            auto_scroll=False,
        )
        
        scrollable_content = ft.Container(
            content=self.scrollable_column,
            padding=20
        )
        
        # 创建回顶按钮
        self.top_button = self._create_top_button()
        
        # 返回包含滚动内容和回顶按钮的栈
        return ft.Stack(
            controls=[
                scrollable_content,
                ft.Container(
                    content=self.top_button,
                    # 将按钮定位在右下角
                    right=20,
                    bottom=20,
                    alignment=ft.alignment.bottom_right,
                )
            ],
            expand=True
        )


def steam_workshop_view(page: ft.Page):
    """创意工坊页面视图"""
    workshop_page = SteamWorkshopPage(page)
    view = workshop_page.create_view()
    
    # 在页面创建后立即触发异步加载
    def on_view_created(e):
        # 使用Flet的异步处理方式
        page.run_task(workshop_page._load_workshop_items)
        # 开始预加载
        page.run_task(workshop_page.start_preloading_async)
    
    # 使用定时器延迟执行，确保页面已经完全渲染
    import threading
    def delayed_load():
        import time
        time.sleep(0.1)  # 延迟100ms确保页面渲染完成
        page.run_task(workshop_page._load_workshop_items)
        # 使用普通线程启动预加载
        workshop_page.start_preloading()
    
    threading.Thread(target=delayed_load).start()
    
    return view