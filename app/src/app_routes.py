# app_routes.py
"""应用程序路由管理"""


class AppRoutes:
    """应用程序路由常量"""
    HOME = "/"
    MODS = "/mods"
    DOWNLOADS = "/downloads"
    SETTINGS = "/settings"


# 路由映射到页面函数
ROUTES = {
    AppRoutes.HOME: "home_page.home_page_view",
    AppRoutes.MODS: "mods_page.mods_page_view",
    AppRoutes.DOWNLOADS: "downloads_page.downloads_page_view",
    AppRoutes.SETTINGS: "settings_page.settings_page_view",
}


# 导航项定义
NAVIGATION_ITEMS = [
    {"text": "主页", "icon": "home", "route": AppRoutes.HOME},
    {"text": "模组管理", "icon": "folder_open", "route": AppRoutes.MODS},
    {"text": "下载", "icon": "download", "route": AppRoutes.DOWNLOADS},
    {"text": "设置", "icon": "settings", "route": AppRoutes.SETTINGS},
]