# BaseComponents/themeManager.py
import flet as ft

# 尝试导入 darkdetect，如果不可用则提供一个模拟实现
try:
    import darkdetect
except ImportError:
    # 模拟 darkdetect 以防未安装
    class darkdetect:
        @staticmethod
        def isDark():
            return False


class AppColors:
    """应用颜色常量类"""
    # 主要颜色
    PRIMARY = "#2196F3"  # 蓝色
    SECONDARY = "#FF9800"  # 橙色
    ACCENT = "#FF5722"  # 深橙色
    SUCCESS = "#4CAF50"  # 绿色
    WARNING = "#FFEB3B"  # 黄色
    ERROR = "#F44336"  # 红色
    INFO = "#2196F3"  # 蓝色
    
    # 中性色
    BLACK = "#000000"
    WHITE = "#FFFFFF"
    GRAY_50 = "#FAFAFA"
    GRAY_100 = "#F5F5F5"
    GRAY_200 = "#EEEEEE"
    GRAY_300 = "#E0E0E0"
    GRAY_400 = "#BDBDBD"
    GRAY_500 = "#9E9E9E"
    GRAY_600 = "#757575"
    GRAY_700 = "#616161"
    GRAY_800 = "#424242"
    GRAY_900 = "#212121"
    
    # 文本颜色
    TEXT_PRIMARY = "#212121"
    TEXT_SECONDARY = "#757575"
    TEXT_DISABLED = "#BDBDBD"
    
    # 背景色
    BACKGROUND = "#FFFFFF"
    SURFACE = "#FFFFFF"


class ThemeManager:
    """主题管理器类"""
    
    def __init__(self):
        self.colors = AppColors()
        # 默认使用系统主题，如果无法检测则使用浅色主题
        try:
            self.current_theme = "dark" if darkdetect.isDark() else "light"
        except:
            self.current_theme = "light"
        
    def get_color(self, color_name):
        """获取指定名称的颜色值"""
        return getattr(self.colors, color_name.upper(), self.colors.PRIMARY)
    
    def set_theme(self, theme):
        """设置主题"""
        self.current_theme = theme
        
    def get_theme_colors(self):
        """获取当前主题的颜色配置"""
        if self.current_theme == "dark":
            return {
                "background": self.colors.GRAY_900,
                "surface": self.colors.GRAY_800,
                "primary": self.colors.PRIMARY,
                "on_primary": self.colors.WHITE,
                "secondary": self.colors.SECONDARY,
                "on_secondary": self.colors.WHITE,
                "text_primary": self.colors.WHITE,
                "text_secondary": self.colors.GRAY_300,
            }
        else:  # light theme
            return {
                "background": self.colors.BACKGROUND,
                "surface": self.colors.SURFACE,
                "primary": self.colors.PRIMARY,
                "on_primary": self.colors.WHITE,
                "secondary": self.colors.SECONDARY,
                "on_secondary": self.colors.WHITE,
                "text_primary": self.colors.TEXT_PRIMARY,
                "text_secondary": self.colors.TEXT_SECONDARY,
            }


# 全局主题管理器实例
theme_manager = ThemeManager()


def get_theme_colors():
    """获取当前主题颜色配置"""
    return theme_manager.get_theme_colors()


def get_color(color_name):
    """获取指定颜色"""
    return theme_manager.get_color(color_name)


def switch_theme(theme):
    """切换主题"""
    theme_manager.set_theme(theme)


def auto_detect_theme():
    """自动检测系统主题"""
    try:
        theme = "dark" if darkdetect.isDark() else "light"
        theme_manager.set_theme(theme)
        return theme
    except:
        # 如果无法检测系统主题，默认使用浅色主题
        theme_manager.set_theme("light")
        return "light"


# 主题相关的便捷函数
def themed_button(text, on_click=None, button_type="primary", **kwargs):
    """创建主题化按钮
    
    Args:
        text: 按钮文本
        on_click: 点击事件
        button_type: 按钮类型 ("primary", "secondary", "success", "warning", "error")
        **kwargs: 其他参数
    """
    colors = get_theme_colors()
    
    button_configs = {
        "primary": {
            "color": colors["on_primary"],
            "bgcolor": colors["primary"]
        },
        "secondary": {
            "color": colors["on_secondary"],
            "bgcolor": colors["secondary"]
        },
        "success": {
            "color": "white",
            "bgcolor": AppColors.SUCCESS
        },
        "warning": {
            "color": "black",
            "bgcolor": AppColors.WARNING
        },
        "error": {
            "color": "white",
            "bgcolor": AppColors.ERROR
        }
    }
    
    config = button_configs.get(button_type, button_configs["primary"])
    
    return ft.ElevatedButton(
        text=text,
        on_click=on_click,
        color=config["color"],
        bgcolor=config["bgcolor"],
        **kwargs
    )


def themed_text(text, text_type="body", **kwargs):
    """创建主题化文本
    
    Args:
        text: 文本内容
        text_type: 文本类型 ("heading", "body", "caption", "link")
        **kwargs: 其他参数
    """
    colors = get_theme_colors()
    
    text_configs = {
        "heading": {
            "size": 24,
            "color": colors["text_primary"],
            "weight": ft.FontWeight.BOLD
        },
        "body": {
            "size": 16,
            "color": colors["text_primary"],
            "weight": ft.FontWeight.NORMAL
        },
        "caption": {
            "size": 12,
            "color": colors["text_secondary"],
            "weight": ft.FontWeight.NORMAL
        },
        "link": {
            "size": 16,
            "color": colors["primary"],
            "weight": ft.FontWeight.NORMAL
        }
    }
    
    config = text_configs.get(text_type, text_configs["body"])
    
    # 合并传入的参数
    for key, value in kwargs.items():
        config[key] = value
    
    return ft.Text(
        text,
        **config
    )


def themed_container(content, container_type="card", **kwargs):
    """创建主题化容器
    
    Args:
        content: 容器内容
        container_type: 容器类型 ("card", "surface", "outlined")
        **kwargs: 其他参数
    """
    colors = get_theme_colors()
    
    container_configs = {
        "card": {
            "bgcolor": colors["surface"],
            "border_radius": 8,
            "padding": 16,
            "elevation": 2
        },
        "surface": {
            "bgcolor": colors["surface"],
            "padding": 16
        },
        "outlined": {
            "bgcolor": colors["surface"],
            "border": ft.border.all(1, colors["text_secondary"]),
            "border_radius": 4,
            "padding": 16
        }
    }
    
    config = container_configs.get(container_type, container_configs["card"])
    
    # 合并传入的参数
    for key, value in kwargs.items():
        config[key] = value
    
    return ft.Container(
        content=content,
        **config
    )