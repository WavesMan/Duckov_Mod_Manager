# pages/mods_page.py
import flet as ft
from BaseComponents import *


def mods_page_view(page: ft.Page):
    """模组管理页面视图"""
    # 获取主题颜色
    colors = get_theme_colors()
    
    # 创建模组表格
    mods_table = ft.DataTable(
        columns=[
            ft.DataColumn(heading("名称", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("版本", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("状态", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("操作", level=4, color=colors["text_primary"])),
        ],
        rows=[
            ft.DataRow(
                cells=[
                    ft.DataCell(body("模组1")),
                    ft.DataCell(body("1.0.0")),
                    ft.DataCell(body("已启用")),
                    ft.DataCell(
                        ft.Row([
                            primary_button("禁用", width=80, height=30),
                            secondary_button("删除", width=80, height=30)
                        ])
                    ),
                ]
            ),
            ft.DataRow(
                cells=[
                    ft.DataCell(body("模组2")),
                    ft.DataCell(body("2.1.0")),
                    ft.DataCell(body("已禁用")),
                    ft.DataCell(
                        ft.Row([
                            primary_button("启用", width=80, height=30),
                            secondary_button("删除", width=80, height=30)
                        ])
                    ),
                ]
            ),
        ] + [
            ft.DataRow(
                cells=[
                    ft.DataCell(body(f"模组{i}")),
                    ft.DataCell(body(f"{i}.{i//2}.{i%3}")),
                    ft.DataCell(body("已启用" if i % 2 == 0 else "已禁用")),
                    ft.DataCell(
                        ft.Row([
                            primary_button("禁用" if i % 2 == 0 else "启用", width=80, height=30),
                            secondary_button("删除", width=80, height=30)
                        ])
                    ),
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
        heading("模组管理", level=1),
        body("在此页面您可以管理您的游戏模组。"),
        
        ft.Divider(height=20),
        
        ft.Row(
            controls=[
                primary_button("添加模组"),
                secondary_button("刷新列表")
            ]
        ),
        
        ft.Divider(height=20),
        
        mods_table,
        
        ft.Divider(height=20),
        
        caption("总共 {} 个模组".format(19))
    ]
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    return scrollable_content