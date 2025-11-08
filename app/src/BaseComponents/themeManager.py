# BaseComponents/themeManager.py

# 定义深色主题颜色方案
DARK_THEME = {
    # 主要颜色
    "primary": "#BB86FC",          # 主色调 - 紫色
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
}

# 当前主题（默认为深色主题）
CURRENT_THEME = DARK_THEME


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
    if theme_name.lower() == 'dark':
        CURRENT_THEME = DARK_THEME
    elif theme_name.lower() == 'light':
        CURRENT_THEME = LIGHT_THEME
    else:
        raise ValueError("不支持的主题名称。请使用 'dark' 或 'light'。")
