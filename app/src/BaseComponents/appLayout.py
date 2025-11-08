# BaseComponents/appLayout.py
import flet as ft
from .themeManager import get_theme_colors


class AppLayout:
    """应用程序主布局组件，包含顶部导航栏、可折叠侧边栏和主内容区"""

    def __init__(self, page: ft.Page, title: str = "Application"):
        self.page = page
        self.title = title
        self.Clolors = get_theme_colors()
        
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
        
        # 创建主内容区
        self.main_content = ft.Container(
            expand=True,
            padding=ft.padding.all(20)
        )
        
        # 创建可折叠的侧边栏容器
        self.sidebar_container = ft.Container(
            content=self.sidebar,
            width=self.sidebar_width,
            animate=ft.Animation(300, ft.AnimationCurve.EASE_IN_OUT)
        )
        
        # 创建整体布局
        self.layout = ft.Row(
            controls=[
                self.sidebar_container,
                self.main_content
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
            bgcolor=self.Clolors["primary"],
            color=self.Clolors["on_primary"],
            actions=[
                # ft.IconButton(
                #     icon=ft.Icons.MENU,
                #     icon_color=self.Clolors["on_primary"],
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
                       color=self.Clolors["text_primary"]),
            ],
            spacing=10,
            expand=True
        )
        
        self.collapsed_sidebar = ft.Column(
            controls=[
                ft.Text("N", size=20, weight=ft.FontWeight.BOLD, 
                       color=self.Clolors["text_primary"], text_align=ft.TextAlign.CENTER),
            ],
            spacing=10,
            expand=True,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER
        )
        
        # 主侧边栏容器
        self.sidebar_content = ft.Container(
            content=self.expanded_sidebar,
            padding=ft.padding.all(20),
            bgcolor=self.Clolors["surface"],
            border=ft.border.only(right=ft.BorderSide(1, self.Clolors["text_secondary"])),
            expand=True
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
        """设置主内容区域的内容"""
        self.main_content.content = content
        self.page.update()

    def add_sidebar_item(self, item_data):
        """向侧边栏添加项目"""
        # 存储导航项数据
        self.sidebar_items.append(item_data)
        
        # 创建展开和收缩状态的控件
        expanded_item = ft.ListTile(
            title=ft.Text(item_data["text"], color=self.Clolors["text_primary"]),
            leading=ft.Icon(item_data["icon"], color=self.Clolors["text_secondary"]) if item_data["icon"] else None,
            on_click=item_data["on_click"],
            data=item_data["route"]
        )
        
        # 修复Tooltip使用方式
        collapsed_item = ft.IconButton(
            icon=item_data["icon"],
            on_click=item_data["on_click"],
            icon_color=self.Clolors["text_secondary"],
            tooltip=item_data["text"]
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