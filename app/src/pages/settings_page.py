# pages/settings_page.py
import flet as ft
from BaseComponents import *


def settings_page_view(page: ft.Page):
    """设置页面视图"""
    
    def save_settings(e):
        # 处理设置保存
        # 由于我们只支持深色主题，这里可以添加其他设置的保存逻辑
        
        # 显示保存成功的消息
        page.snack_bar = ft.SnackBar(
            content=ft.Text("设置已保存"),
            bgcolor=ft.colors.GREEN
        )
        page.snack_bar.open = True
        page.update()
    
    def reset_settings(e):
        # 恢复默认设置
        page.snack_bar = ft.SnackBar(
            content=ft.Text("设置已恢复为默认值"),
            bgcolor=ft.colors.BLUE
        )
        page.snack_bar.open = True
        page.update()
    
    # 创建操作按钮
    action_buttons = ft.Container(
        content=ft.Row(
            controls=[
                primary_button("保存设置", on_click=save_settings),
                secondary_button("恢复默认", on_click=reset_settings)
            ]
        ),
        padding=ft.padding.only(top=20, bottom=20)
    )
    
    # 创建设置表单（不含操作按钮）
    settings_form = ft.Column(
        controls=[
            heading("常规设置", level=2),
            
            ft.Checkbox(
                label="启动时自动检查更新",
                value=True
            ),
            
            ft.Checkbox(
                label="最小化到系统托盘",
                value=False
            ),
            
            ft.TextField(
                label="下载目录",
                value="C:/Games/MyGame/Mods",
                width=400
            ),
            
            ft.Divider(height=20),
            
            heading("高级设置", level=2),
            
            ft.Checkbox(
                label="启用调试日志",
                value=False
            ),
            
            ft.TextField(
                label="代理服务器",
                hint_text="例如: http://proxy.company.com:8080",
                width=400
            ),
            
            ft.TextField(
                label="并发下载数",
                value="3",
                width=400,
                keyboard_type=ft.KeyboardType.NUMBER
            ),
            
            ft.Divider(height=20),
            
            # 添加更多设置项以测试滚动
            heading("网络设置", level=2),
            
            ft.TextField(
                label="连接超时(秒)",
                value="30",
                width=400,
                keyboard_type=ft.KeyboardType.NUMBER
            ),
            
            ft.TextField(
                label="重试次数",
                value="3",
                width=400,
                keyboard_type=ft.KeyboardType.NUMBER
            ),
            
            ft.Divider(height=20),
            
            heading("存储设置", level=2),
            
            ft.TextField(
                label="缓存目录",
                value="C:/Games/MyGame/Cache",
                width=400
            ),
            
            ft.TextField(
                label="临时文件目录",
                value="C:/Temp/MyGame",
                width=400
            ),
            
            ft.Divider(height=20),
            
            heading("界面设置", level=2),
            
            ft.Dropdown(
                label="语言",
                options=[
                    ft.dropdown.Option("简体中文"),
                    ft.dropdown.Option("English"),
                    ft.dropdown.Option("日本語")
                ],
                value="简体中文",
                width=400
            ),
            
            ft.Checkbox(
                label="启用动画效果",
                value=True
            ),
            
            ft.Divider(height=20),
            
            heading("备份设置", level=2),
            
            ft.Checkbox(
                label="自动备份模组",
                value=True
            ),
            
            ft.TextField(
                label="备份保留天数",
                value="30",
                width=400,
                keyboard_type=ft.KeyboardType.NUMBER
            ),
            
            ft.Divider(height=20),
        ],
        spacing=15
    )
    
    # 创建页面内容，将操作按钮放在表单外部
    content = [
        heading("设置", level=1),
        body("在此页面您可以配置应用程序的各种设置。"),
        
        ft.Divider(height=20),
    ]
    
    # 创建一个可滚动的区域，仅包含设置表单
    scrollable_area = scrollable_page(
        content=settings_form,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    # 创建主布局：标题+描述在顶部，滚动区域在中间，按钮在底部
    main_layout = ft.Column(
        controls=[
            # 标题和描述部分（固定）
            ft.Column(
                controls=content,
                spacing=10
            ),
            
            # 滚动区域（占据剩余空间）
            ft.Container(
                content=scrollable_area,
                expand=True
            ),
            
            # 操作按钮（固定在底部）
            action_buttons
        ],
        expand=True,
        spacing=0
    )
    
    return main_layout