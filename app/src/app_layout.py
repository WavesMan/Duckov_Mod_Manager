# app_layout.py
import flet as ft
from theme_manager import get_theme_colors


class AppLayout:
    """应用程序主布局组件，包含顶部导航栏、可折叠侧边栏和主内容区"""

    def __init__(self, page: ft.Page, title: str = "Application"):
        self.page = page
        self.title = title
        self.colors = get_theme_colors()
        
        # 侧边栏状态
        self.sidebar_expanded = True
        self.sidebar_width = 250
        self.sidebar_collapsed_width = 60
        
        # 创建布局组件
        self.setup_layout()

    def setup_layout(self):
        """设置主布局结构"""
        # 创建顶部应用栏
        self.appbar = self.create_appbar()
        
        # 创建侧边栏
        self.sidebar_items = []  # 存储导航项数据
        self.sidebar = self.create_sidebar()
        
        # 创建主内容区，使用Stack来支持动画效果
        self.main_content = ft.Stack(
            controls=[],
            expand=True
        )
        
        # 创建可折叠的侧边栏容器
        self.sidebar_container = ft.Container(
            content=self.sidebar,
            width=self.sidebar_width,
            animate=ft.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
            border_radius=ft.border_radius.only(top_right=10, bottom_right=10, top_left=10, bottom_left=10)  # 为侧边栏添加圆角
        )
        
        # 创建整体布局
        self.layout = ft.Row(
            controls=[
                self.sidebar_container,
                ft.Container(
                    content=self.main_content,
                    padding=ft.padding.all(20),
                    expand=True
                )
            ],
            expand=True
        )
        
        # 设置页面
        self.page.appbar = self.appbar
        self.page.controls = [self.layout]

    def create_appbar(self):
        """创建顶部应用栏"""
        return ft.AppBar(
            title=ft.Text(self.title),
            bgcolor=self.colors["primary"],
            color=self.colors["on_primary"],
            actions=[
                # ft.IconButton(
                #     icon=ft.Icons.MENU,
                #     icon_color=self.colors["on_primary"],
                #     on_click=self.toggle_sidebar
                # )
            ]
        )

    def create_sidebar(self):
        """创建侧边栏"""
        # 创建两个列，一个用于展开状态，一个用于收缩状态
        self.expanded_sidebar = ft.Column(
            controls=[
                ft.Text("侧边栏", size=20, weight=ft.FontWeight.BOLD,
                       color=self.colors["text_primary"]),
            ],
            spacing=10,
            expand=True
        )
        
        self.collapsed_sidebar = ft.Column(
            controls=[
                ft.Text("N", size=20, weight=ft.FontWeight.BOLD, 
                       color=self.colors["text_primary"], text_align=ft.TextAlign.CENTER),
            ],
            spacing=10,
            expand=True,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER
        )
        
        # 主侧边栏容器
        self.sidebar_content = ft.Container(
            content=self.expanded_sidebar,
            padding=ft.padding.all(20),
            bgcolor=self.colors["surface"],
            border=ft.border.only(right=ft.BorderSide(1, self.colors["text_secondary"])),
            expand=True,
            border_radius=ft.border_radius.only(top_right=10, bottom_right=10, top_left=10, bottom_left=10)  # 为侧边栏内容添加圆角
        )
        
        return self.sidebar_content

    def toggle_sidebar(self, e):
        """切换侧边栏展开/收缩状态"""
        self.sidebar_expanded = not self.sidebar_expanded
        
        if self.sidebar_expanded:
            # 展开侧边栏
            self.sidebar_container.width = self.sidebar_width
            self.sidebar_content.content = self.expanded_sidebar
        else:
            # 收缩侧边栏
            self.sidebar_container.width = self.sidebar_collapsed_width
            self.sidebar_content.content = self.collapsed_sidebar
            
        self.page.update()

    def set_content(self, content):
        """设置主内容区域的内容，带动画效果"""
        # 创建旧内容淡出动画
        old_content_controls = list(self.main_content.controls)
        
        # 如果有旧内容，先执行淡出动画
        if old_content_controls:
            for old_content in old_content_controls:
                old_content.opacity = 0
                
            # 更新界面触发动画
            self.page.update()
            
            # 等待淡出动画完成
            import time
            time.sleep(0.3)  # 等待300ms动画完成
        
        # 清空当前内容
        self.main_content.controls.clear()
        
        # 检查内容是否已经是Stack（如创意工坊页面），如果是，则直接使用其内容
        if isinstance(content, ft.Stack):
            # 提取Stack中的内容
            stack_content = content.controls
            # 创建新的容器包含这些内容
            content_container = ft.Container(
                content=ft.Stack(controls=stack_content),
                expand=True
            )
        else:
            content_container = ft.Container(content=content)
        
        # 创建新的内容容器，带有淡入动画（300毫秒）
        new_content = ft.Container(
            content=content_container,
            opacity=0,
            animate_opacity=ft.Animation(300, ft.AnimationCurve.EASE_IN_OUT),
            expand=True
        )
        
        # 添加新内容
        self.main_content.controls.append(new_content)
        
        # 更新界面
        self.page.update()
        
        # 触发动画
        new_content.opacity = 1
        self.page.update()

    def add_sidebar_item(self, item_data):
        """向侧边栏添加项目"""
        # 存储导航项数据
        self.sidebar_items.append(item_data)
        
        # 创建展开和收缩状态的控件，添加圆角效果
        expanded_item = ft.ListTile(
            title=ft.Text(item_data["text"], color=self.colors["text_primary"]),
            leading=ft.Icon(item_data["icon"], color=self.colors["text_secondary"]) if item_data["icon"] else None,
            on_click=item_data["on_click"],
            data=item_data["route"],
            shape=ft.RoundedRectangleBorder(radius=5)  # 为列表项添加圆角
        )
        
        # 修复Tooltip使用方式，添加圆角效果
        collapsed_item = ft.IconButton(
            icon=item_data["icon"],
            on_click=item_data["on_click"],
            icon_color=self.colors["text_secondary"],
            tooltip=item_data["text"],
            style=ft.ButtonStyle(
                shape=ft.RoundedRectangleBorder(radius=5)  # 为图标按钮添加圆角
            )
        )
        
        # 添加到对应的列中
        self.expanded_sidebar.controls.append(expanded_item)
        self.collapsed_sidebar.controls.append(collapsed_item)
        
        self.page.update()


class NavigationItem:
    """侧边栏导航项数据类"""
    
    def __init__(self, text, icon=None, on_click=None, route=None):
        self.text = text
        self.icon = icon
        self.on_click = on_click
        self.route = route


def create_app_layout(page: ft.Page, title: str = "Application"):
    """
    创建应用程序布局的便捷函数
    
    Args:
        page (ft.Page): Flet页面对象
        title (str): 应用程序标题
        
    Returns:
        AppLayout: 应用程序布局实例
    """
    return AppLayout(page, title)