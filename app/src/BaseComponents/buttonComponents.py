# BaseComponents/buttonComponents.py
import flet as ft
from .themeManager import get_theme_colors


def primary_button(text, on_click=None, width=None, height=None):
    """
    创建一个主要按钮

    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        width (int, optional): 按钮宽度
        height (int, optional): 按钮高度

    Returns:
        ft.ElevatedButton: 配置好的按钮组件
    """
    colors = get_theme_colors()
    return ft.ElevatedButton(
        text=text,
        on_click=on_click,
        width=width,
        height=height,
        color=colors["on_primary"],
        bgcolor=colors["primary"],
    )


def secondary_button(text, on_click=None, width=None, height=None):
    """
    创建一个次要按钮

    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        width (int, optional): 按钮宽度
        height (int, optional): 按钮高度

    Returns:
        ft.ElevatedButton: 配置好的按钮组件
    """
    colors = get_theme_colors()
    return ft.ElevatedButton(
        text=text,
        on_click=on_click,
        width=width,
        height=height,
        color=colors["on_secondary"],
        bgcolor=colors["secondary"],
    )


def icon_button(icon, on_click=None, tooltip=None):
    """
    创建一个图标按钮

    Args:
        icon (ft.Icons): 图标
        on_click (callable): 点击事件处理函数
        tooltip (str, optional): 提示文本

    Returns:
        ft.IconButton: 配置好的图标按钮组件
    """
    return ft.IconButton(
        icon=icon,
        on_click=on_click,
        tooltip=tooltip,
    )