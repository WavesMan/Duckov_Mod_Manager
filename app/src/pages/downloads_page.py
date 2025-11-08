# pages/downloads_page.py
import flet as ft
from BaseComponents import *


def downloads_page_view(page: ft.Page):
    """下载页面视图"""
    # 获取主题颜色
    colors = get_theme_colors()
    
    # 创建下载进度条示例
    download_progress = ft.Column(
        controls=[
            heading("模组下载示例", level=4),
            ft.ProgressBar(value=0.7, width=400, color=colors["primary"], bgcolor=colors["surface"]),
            body("正在下载: 模组名称.zip (70%)")
        ],
        spacing=5
    )
    
    # 创建下载历史列表
    download_history = ft.DataTable(
        columns=[
            ft.DataColumn(heading("文件名", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("大小", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("状态", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("完成时间", level=4, color=colors["text_primary"])),
        ],
        rows=[
            ft.DataRow(
                cells=[
                    ft.DataCell(body("模组1.zip")),
                    ft.DataCell(body("25 MB")),
                    ft.DataCell(body("已完成")),
                    ft.DataCell(body("2023-05-15 14:30")),
                ]
            ),
            ft.DataRow(
                cells=[
                    ft.DataCell(body("模组2.zip")),
                    ft.DataCell(body("120 MB")),
                    ft.DataCell(body("已完成")),
                    ft.DataCell(body("2023-05-14 09:15")),
                ]
            ),
        ] + [
            ft.DataRow(
                cells=[
                    ft.DataCell(body(f"模组{i}.zip")),
                    ft.DataCell(body(f"{i*10} MB")),
                    ft.DataCell(body("已完成")),
                    ft.DataCell(body(f"2023-05-{10+i} 1{i}:2{i}")),
                ]
            ) for i in range(3, 20)  # 添加更多行以测试滚动
        ],
        border=ft.border.all(2, colors["text_secondary"]),
        border_radius=10,
        vertical_lines=ft.border.BorderSide(1, colors["text_secondary"]),
        horizontal_lines=ft.border.BorderSide(1, colors["text_secondary"]),
        heading_row_color=colors["surface"],
    )
    
    # 创建页面内容
    content = [
        heading("下载管理", level=1),
        body("在此页面您可以查看和管理模组下载。"),
        
        ft.Divider(height=20),
        
        ft.TextField(
            label="输入模组ID或URL",
            hint_text="例如: https://steamcommunity.com/sharedfiles/filedetails/?id=123456789",
            width=500
        ),
        
        ft.Row(
            controls=[
                primary_button("开始下载"),
                secondary_button("从文件安装")
            ]
        ),
        
        ft.Divider(height=20),
        
        heading("正在进行的下载", level=3),
        download_progress,
        
        ft.Divider(height=20),
        
        heading("下载历史", level=3),
        download_history,
        
        ft.Divider(height=20),
        
        caption("总共 {} 个已完成的下载".format(19))
    ]
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    return scrollable_content