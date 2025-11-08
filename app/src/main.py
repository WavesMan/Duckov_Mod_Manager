# src/main.py
import flet as ft

from BaseComponents import *
import sys
import os

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 导入页面模块
from pages import home_page, mods_page, downloads_page, settings_page
from pages.steam_workshop_page import steam_workshop_view
from app_routes import AppRoutes, NAVIGATION_ITEMS


def main(page: ft.Page):
    # 设置页面标题
    page.title = "Duckov 模组管理器"
    
    # 设置窗口大小
    page.window_width = 1000
    page.window_height = 700
    page.window_resizable = True
    
    # 应用主题设置
    theme_colors = get_theme_colors()
    page.bgcolor = theme_colors["background"]
    
    # 初始化应用布局
    app_layout = create_app_layout(page, "Duckov 模组管理器")
    
    # 存储当前路由
    current_route = AppRoutes.HOME

    # 路由处理函数
    def route_change(e):
        nonlocal current_route
        current_route = e.route if e.route else AppRoutes.HOME
        
        # 根据路由显示对应页面
        if current_route == AppRoutes.HOME:
            content = home_page.home_page_view(page)
        elif current_route == AppRoutes.MODS:
            content = mods_page.mods_page_view(page)
        elif current_route == AppRoutes.DOWNLOADS:
            content = downloads_page.downloads_page_view(page)
        elif current_route == AppRoutes.STEAM_WORKSHOP:
            content = steam_workshop_view(page)
        elif current_route == AppRoutes.SETTINGS:
            content = settings_page.settings_page_view(page)
        else:
            content = ft.Column([
                heading("页面未找到", level=1),
                body("抱歉，您访问的页面不存在。")
            ])
        
        app_layout.set_content(content)
    
    # 导航处理函数
    def navigate_to(route):
        page.go(route)
    
    # 为侧边栏添加导航项
    for item_data in NAVIGATION_ITEMS:
        # 修复图标引用问题
        icon_name = item_data["icon"].upper()
        icon = getattr(ft.Icons, icon_name, None)
        nav_item = {
            "text": item_data["text"],
            "icon": icon,
            "route": item_data["route"],
            "on_click": lambda e, route=item_data["route"]: navigate_to(route)
        }
        app_layout.add_sidebar_item(nav_item)
    
    # 设置路由变化监听器
    page.on_route_change = route_change
    
    # 初始化导航到主页
    page.go(AppRoutes.HOME)


ft.app(main)