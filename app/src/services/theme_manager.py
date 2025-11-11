# theme_manager.py
import flet as ft

# 定义深色主题颜色方案
DARK_THEME = {
    # 主要颜色
    "primary": "#1E90FF",          # 主色调 - 蓝色
    "secondary": "#03DAC6",        # 次要颜色 - 青色
    "background": "#121212",       # 背景颜色 - 深灰
    "surface": "#1E1E1E",          # 表面颜色 - 稍浅的灰
    "error": "#CF6679",            # 错误颜色 - 红色
    
    # 文本颜色
    "on_primary": "#000000",       # 主色调上的文字 - 黑色
    "on_secondary": "#000000",     # 次要颜色上的文字 - 黑色
    "on_background": "#FFFFFF",    # 背景上的文字 - 白色
    "on_surface": "#FFFFFF",       # 表面颜色上的文字 - 白色
    "on_error": "#000000",         # 错误颜色上的文字 - 黑色
    
    # 文本颜色变体
    "text_primary": "#FFFFFF",     # 主要文字颜色 - 白色
    "text_secondary": "#B3B3B3",   # 次要文字颜色 - 浅灰
    
    # 其他颜色
    "divider": "#333333",          # 分割线颜色 - 深灰
    
    # 新增：控件颜色
    "button_background": "#1E90FF",        # 按钮背景色
    "button_text": "#000000",               # 按钮文字色
    "button_hover": "#1C86EE",              # 按钮悬停色
    "button_disabled": "#666666",           # 按钮禁用色
    "input_background": "#2A2A2A",          # 输入框背景色
    "input_border": "#404040",              # 输入框边框色
    "input_text": "#FFFFFF",                # 输入框文字色
    "card_background": "#1E1E1E",           # 卡片背景色
    "card_border": "#333333",               # 卡片边框色
    "snackbar_background": "#323232",       # 提示框背景色
    "snackbar_text": "#FFFFFF",             # 提示框文字色

    # 自定义颜色
    "White": "#FFFFFF",
}

# 定义浅色主题颜色方案
LIGHT_THEME = {
    # 主要颜色
    "primary": "#6200EE",          # 主色调 - 紫色
    "secondary": "#03DAC6",        # 次要颜色 - 青色
    "background": "#FFFFFF",       # 背景颜色 - 白色
    "surface": "#F5F5F5",          # 表面颜色 - 浅灰
    "error": "#B00020",            # 错误颜色 - 深红
    
    # 文本颜色
    "on_primary": "#FFFFFF",       # 主色调上的文字 - 白色
    "on_secondary": "#000000",     # 次要颜色上的文字 - 黑色
    "on_background": "#000000",    # 背景上的文字 - 黑色
    "on_surface": "#000000",       # 表面颜色上的文字 - 黑色
    "on_error": "#FFFFFF",         # 错误颜色上的文字 - 白色
    
    # 文本颜色变体
    "text_primary": "#000000",     # 主要文字颜色 - 黑色
    "text_secondary": "#666666",   # 次要文字颜色 - 深灰
    
    # 其他颜色
    "divider": "#E0E0E0",          # 分割线颜色 - 浅灰
    
    # 新增：控件颜色
    "button_background": "#6200EE",        # 按钮背景色
    "button_text": "#FFFFFF",               # 按钮文字色
    "button_hover": "#5A00D6",              # 按钮悬停色
    "button_disabled": "#CCCCCC",           # 按钮禁用色
    "input_background": "#FAFAFA",          # 输入框背景色
    "input_border": "#E0E0E0",              # 输入框边框色
    "input_text": "#000000",                # 输入框文字色
    "card_background": "#F5F5F5",           # 卡片背景色
    "card_border": "#E0E0E0",               # 卡片边框色
    "snackbar_background": "#323232",       # 提示框背景色
    "snackbar_text": "#FFFFFF",             # 提示框文字色
}

# 当前主题（默认为深色主题）
CURRENT_THEME = DARK_THEME

# 主题变化监听器列表
THEME_LISTENERS = []


def get_theme_colors():
    """
    获取当前主题颜色方案
    
    Returns:
        dict: 当前主题的颜色字典
    """
    return CURRENT_THEME


def set_theme(theme_name):
    """
    设置主题
    
    Args:
        theme_name (str): 主题名称 ('dark' 或 'light')
    """
    global CURRENT_THEME
    old_theme = get_theme_name()
    
    if theme_name.lower() == 'dark':
        CURRENT_THEME = DARK_THEME
    elif theme_name.lower() == 'light':
        CURRENT_THEME = LIGHT_THEME
    else:
        raise ValueError("不支持的主题名称。请使用 'dark' 或 'light'。")
    
    # 触发主题变化事件
    new_theme = get_theme_name()
    if old_theme != new_theme:
        _notify_theme_changed()


def add_theme_listener(listener):
    """
    添加主题变化监听器
    
    Args:
        listener (callable): 监听器函数，当主题变化时会被调用
    """
    if listener not in THEME_LISTENERS:
        THEME_LISTENERS.append(listener)


def remove_theme_listener(listener):
    """
    移除主题变化监听器
    
    Args:
        listener (callable): 要移除的监听器函数
    """
    if listener in THEME_LISTENERS:
        THEME_LISTENERS.remove(listener)


def _notify_theme_changed():
    """通知所有监听器主题已变化"""
    for listener in THEME_LISTENERS:
        try:
            listener()
        except Exception as e:
            print(f"主题监听器执行错误: {e}")


def get_theme_name():
    """
    获取当前主题名称
    
    Returns:
        str: 'dark' 或 'light'
    """
    if CURRENT_THEME == DARK_THEME:
        return "dark"
    else:
        return "light"


def create_card(content, padding=20, margin=10):
    """
    创建主题化卡片
    
    Args:
        content: 卡片内容
        padding (int): 内边距
        margin (int): 外边距
        
    Returns:
        ft.Container: 配置好的卡片容器
    """
    colors = get_theme_colors()
    return ft.Container(
        content=content,
        padding=padding,
        margin=margin,
        bgcolor=colors["card_background"],
        border=ft.border.all(1, colors["card_border"]),
        border_radius=10,
    )


def create_snackbar(content, bgcolor=None):
    """
    创建主题化提示框
    
    Args:
        content: 提示内容
        bgcolor (str, optional): 背景颜色，如未提供则使用主题颜色
        
    Returns:
        ft.SnackBar: 配置好的提示框
    """
    colors = get_theme_colors()
    if bgcolor is None:
        bgcolor = colors["snackbar_background"]
    
    return ft.SnackBar(
        content=ft.Text(content, color=colors["snackbar_text"]),
        bgcolor=bgcolor,
    )