# pages/home_page.py
import flet as ft
from BaseComponents import *


def home_page_view(page: ft.Page):
    """主页视图"""
    colors = get_theme_colors()
    
    # 创建主页内容
    content = [
        heading("欢迎使用Duckov 模组管理器", level=1),
        body("这是一个现代化的模组管理工具，可以帮助您轻松管理游戏模组。"),
        
        ft.Divider(height=20),
        
        heading("功能特点", level=2),
        ft.ResponsiveRow(
            controls=[
                ft.Column(
                    controls=[
                        ft.Icon(ft.Icons.FOLDER_OPEN, size=40, color=colors["primary"]),
                        body("模组浏览", size=18),
                        caption("浏览和查看已安装的模组")
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    col={"xs": 12, "sm": 6, "md": 4}
                ),
                ft.Column(
                    controls=[
                        ft.Icon(ft.Icons.DOWNLOAD, size=40, color=colors["primary"]),
                        body("一键下载", size=18),
                        caption("从Steam创意工坊下载模组")
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    col={"xs": 12, "sm": 6, "md": 4}
                ),
                ft.Column(
                    controls=[
                        ft.Icon(ft.Icons.SETTINGS, size=40, color=colors["primary"]),
                        body("配置管理", size=18),
                        caption("管理模组配置和设置")
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    col={"xs": 12, "sm": 6, "md": 4}
                )
            ],
            spacing=20,
            run_spacing=20
        ),
        
        ft.Divider(height=20),
        
        heading("开始使用", level=2),
        body("点击左侧导航栏中的选项来开始使用不同的功能。"),
        
        ft.Divider(height=20),
        
        caption("版本 0.1.0")
    ]
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    return scrollable_content