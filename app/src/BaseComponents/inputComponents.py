# BaseComponents/inputComponents.py
import flet as ft
from .themeManager import get_theme_colors


def text_field(label, hint_text=None, on_change=None, width=None):
    """
    创建一个文本输入框

    Args:
        label (str): 输入框标签
        hint_text (str, optional): 提示文本
        on_change (callable): 内容改变事件处理函数
        width (int, optional): 输入框宽度

    Returns:
        ft.TextField: 配置好的文本输入框组件
    """
    colors = get_theme_colors()
    return ft.TextField(
        label=label,
        hint_text=hint_text,
        on_change=on_change,
        width=width,
        color=colors["text_primary"],
        border_color=colors["primary"],
    )


def dropdown(label, options, on_change=None, width=None):
    """
    创建一个下拉选择框

    Args:
        label (str): 下拉框标签
        options (list): 选项列表
        on_change (callable): 选择改变事件处理函数
        width (int, optional): 下拉框宽度

    Returns:
        ft.Dropdown: 配置好的下拉选择框组件
    """
    colors = get_theme_colors()
    return ft.Dropdown(
        label=label,
        options=[ft.dropdown.Option(option) for option in options],
        on_change=on_change,
        width=width,
        color=colors["text_primary"],
        border_color=colors["primary"],
    )


def checkbox(label, value=False, on_change=None):
    """
    创建一个复选框

    Args:
        label (str): 复选框标签
        value (bool): 默认值
        on_change (callable): 状态改变事件处理函数

    Returns:
        ft.Checkbox: 配置好的复选框组件
    """
    colors = get_theme_colors()
    return ft.Checkbox(
        label=label,
        value=value,
        on_change=on_change,
        fill_color=colors["primary"],
    )