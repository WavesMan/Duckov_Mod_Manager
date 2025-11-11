# pages/settings_page.py
import flet as ft
import sys
import os
import logging
import threading

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.theme_manager import get_theme_colors
from services.config_manager import config_manager
from services.version_manager import version_manager
from components.update_dialog import UpdateDialog

# 配置日志
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


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


def scrollable_page(
        content,
        scroll=ft.ScrollMode.AUTO,
        alignment=ft.MainAxisAlignment.START,
        horizontal_alignment=ft.CrossAxisAlignment.START,
        spacing=10,
        padding=20,
        auto_scroll=False,
        **kwargs
):
    """
    创建一个可滚动的页面布局的便捷函数

    Args:
        content: 页面内容（可以是控件列表或单个控件）
        scroll: 滚动模式
        alignment: 主轴对齐方式
        horizontal_alignment: 交叉轴对齐方式
        spacing: 控件间距
        padding: 页面内边距
        auto_scroll: 是否自动滚动到底部
        **kwargs: 其他参数

    Returns:
        ft.Column: 配置好的可滚动列布局
    """
    # 如果内容不是列表，转换为列表
    if not isinstance(content, list):
        content = [content]

    # 创建可滚动的列布局
    scrollable_column = ft.Column(
        controls=content,
        scroll=scroll,
        alignment=alignment,
        horizontal_alignment=horizontal_alignment,
        spacing=spacing,
        auto_scroll=auto_scroll,
        **kwargs
    )

    # 如果指定了padding，则将其包装在一个容器中
    if padding:
        return ft.Container(
            content=scrollable_column,
            padding=padding
        )

    return scrollable_column


def settings_page_view(page: ft.Page):
    """设置页面视图"""
    
    colors = get_theme_colors()

    # 从配置管理器获取目录路径
    game_directory_path = config_manager.get("game_directory")
    cache_directory_path = config_manager.get("cache_directory")
    temp_directory_path = config_manager.get("temp_directory")

    # 游戏目录路径显示文本框
    game_directory_field = ft.TextField(
        label="游戏目录",
        value=game_directory_path,
        width=400,
        read_only=True,
        color=colors["text_primary"],
        label_style=ft.TextStyle(color=get_theme_colors()["text_primary"]),
        border_color="#999999"
    )

    # 存储文件选择器实例，确保在页面切换后仍然可用
    file_pickers = {}

    def show_error_dialog(message):
        """显示错误对话框"""
        logger.debug(f"显示错误对话框: {message}")

        def close_dialog(e):
            logger.debug("关闭错误对话框")
            dialog.open = False
            page.update()

        # 创建对话框
        dialog = ft.AlertDialog(
            modal=True,
            title=ft.Text("错误"),
            content=ft.Text(message),
            actions=[
                ft.TextButton("确定", on_click=close_dialog),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )

        # 显示对话框
        page.open(dialog)
        logger.debug("错误对话框已显示")

    def select_game_directory(e):
        """选择游戏目录"""
        logger.debug("开始选择游戏目录")

        def pick_game_dir_result(e: ft.FilePickerResultEvent):
            logger.debug(f"游戏目录选择结果: path={e.path}")
            if e.path:
                logger.debug(f"用户选择了路径: {e.path}")
                # 检查路径是否包含"Escape from Duckov"文件夹
                if "Escape from Duckov" in e.path:
                    logger.debug("路径验证通过")
                    # 保存到配置管理器
                    config_manager.set("game_directory", e.path)
                    # 更新显示
                    game_directory_field.value = e.path
                    page.update()
                    logger.debug("游戏目录已更新")
                else:
                    logger.debug("路径验证失败，不包含'Escape from Duckov'")
                    # 保存当前有效路径用于回退
                    previous_path = game_directory_field.value
                    logger.debug(f"回退到之前的路径: {previous_path}")
                    # 显示错误弹窗
                    show_error_dialog("请选择包含'Escape from Duckov'的路径")
                    # 回退到之前的有效路径
                    game_directory_field.value = previous_path
                    page.update()
                    logger.debug("已回退到之前的路径并更新界面")
            elif e.path is None:
                # 用户取消选择，保持原路径不变
                logger.debug("用户取消了目录选择")
            else:
                logger.debug(f"未知的路径选择结果: {e.path}")

        # 创建或重用文件选择器
        if "game" not in file_pickers:
            logger.debug("创建新的游戏目录文件选择器")
            file_picker = ft.FilePicker(on_result=pick_game_dir_result)
            file_pickers["game"] = file_picker
            page.overlay.append(file_picker)
            page.update()
        else:
            logger.debug("使用现有的游戏目录文件选择器")
        file_pickers["game"].get_directory_path(dialog_title="选择包含'Escape from Duckov'的目录")
        logger.debug("已触发游戏目录选择对话框")


    def save_settings(e):
        """
        保存设置
        """
        logger.debug("正在保存设置")

        # 保存常规设置
        config_manager.set("auto_update", auto_update_checkbox.value)
        # config_manager.set("minimize_to_tray", minimize_to_tray_checkbox.value)
        # config_manager.set("language", language_dropdown.value)
        # config_manager.set("enable_animations", enable_animations_checkbox.value)

        # 保存目录设置
        config_manager.set("game_directory", game_directory_field.value)

        # 更新页面以反映更改
        page.update()
        logger.debug("设置已保存并更新界面")

        # 显示保存成功的消息
        page.snack_bar = ft.SnackBar(
            content=ft.Text("设置已保存"),
            bgcolor=ft.Colors.GREEN,
        )
        page.snack_bar.open = True
        page.update()

    def reset_settings(e):
        """恢复默认设置"""
        logger.debug("开始恢复默认设置")
        # 重置配置管理器到默认值
        config_manager.reset_to_default()

        # 更新UI控件的值
        game_directory_field.value = config_manager.get("game_directory")
        # language_dropdown.value = config_manager.get("language")
        auto_update_checkbox.value = config_manager.get("auto_update")
        # minimize_to_tray_checkbox.value = config_manager.get("minimize_to_tray")
        # enable_animations_checkbox.value = config_manager.get("enable_animations")

        page.update()
        logger.debug("默认设置已恢复并更新界面")

        # 显示恢复默认值的消息
        page.snack_bar = ft.SnackBar(
            content=ft.Text("设置已恢复为默认值"),
            bgcolor=ft.Colors.BLUE,
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

    # 创建设置表单控件
    auto_update_checkbox = ft.Checkbox(
        label="启动时自动检查更新",
        value=config_manager.get("auto_update"),
        label_style=ft.TextStyle(color=get_theme_colors()["text_primary"])
    )

    # minimize_to_tray_checkbox = ft.Checkbox(
    #     label="最小化到系统托盘",
    #     value=config_manager.get("minimize_to_tray")
    # )

    # language_dropdown = ft.Dropdown(
    #     label="语言",
    #     options=[
    #         ft.dropdown.Option("简体中文"),
    #         ft.dropdown.Option("English"),
    #         ft.dropdown.Option("日本語")
    #     ],
    #     value=config_manager.get("language"),
    #     width=400
    # )

    # 检查更新相关变量
    update_dialog = UpdateDialog(page)
    check_update_button = ft.ElevatedButton(
        content=ft.Row(
            [
                ft.Icon(name=ft.Icons.UPDATE, color=get_theme_colors()["on_primary"]),
                ft.Text("检查更新", font_family="MiSans", color=ft.Colors.BLACK, size=14)
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=5,
        ),
        style=ft.ButtonStyle(
            bgcolor=get_theme_colors()["primary"],
            padding=ft.Padding(20, 15, 20, 15)
        ),
        width=120,
    )

    # 版本信息显示
    version_info_text = caption(f"当前版本: v{config_manager.get('current_version', '0.1.1')}")

    def check_for_updates(e):
        """检查更新功能"""
        logger.info("开始检查更新")

        # 禁用按钮并显示加载状态
        check_update_button.disabled = True
        check_update_button.content.controls[1].value = "检查中..."
        page.update()

        def update_check_thread():
            """在后台线程中检查更新"""
            try:
                # 检查更新
                update_result = version_manager.check_for_updates()

                # 更新最后检查时间
                from datetime import datetime
                config_manager.set("last_update_check", datetime.now().isoformat())

                # 直接在主线程中执行UI更新操作
                # 恢复按钮状态
                check_update_button.disabled = False
                check_update_button.content.controls[1].value = "检查更新"

                # 将更新信息存储到会话中并跳转到更新页面
                page.session.set("update_info", update_result)
                page.go("/update")
                page.update()

            except Exception as e:
                logger.error(f"检查更新过程中发生错误: {e}")

                # 直接在主线程中执行错误处理
                check_update_button.disabled = False
                check_update_button.content.controls[1].value = "检查更新"
                page.snack_bar = ft.SnackBar(
                    content=ft.Text(f"检查更新失败: {str(e)}"),
                    bgcolor=ft.Colors.RED,
                )
                page.snack_bar.open = True
                page.update()

        # 在后台线程中执行检查
        thread = threading.Thread(target=update_check_thread)
        thread.daemon = True
        thread.start()

    # 绑定检查更新事件
    check_update_button.on_click = check_for_updates

    # 创建设置表单（不含操作按钮）
    settings_form = ft.Column(
        controls=[
            heading("常规设置", level=2),
            
            auto_update_checkbox,
            
            # minimize_to_tray_checkbox,

            ft.Row(
                controls=[
                    game_directory_field,
                    primary_button("浏览...", on_click=select_game_directory, width=100)
                ],
                alignment=ft.MainAxisAlignment.START,
                spacing=10
            ),

            # ft.Divider(height=20),
            #
            # heading("界面设置", level=2),
            #
            # language_dropdown,

            ft.Divider(height=20),

            heading("版本检查", level=2),
            
            version_info_text,
            
            ft.Row(
                controls=[
                    check_update_button,
                    caption("点击检查最新版本", size=12)
                ],
                alignment=ft.MainAxisAlignment.START,
                spacing=10
            ),

        ]
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

    logger.debug("设置页面初始化完成")
    return main_layout