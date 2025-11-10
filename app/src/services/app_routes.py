# app_routes.py
"""应用程序路由管理"""


class AppRoutes:
    """应用程序路由常量"""
    HOME = "/"
    MODS = "/mods"
    STEAM_WORKSHOP = "/steam-workshop"
    SETTINGS = "/settings"
    UPDATE = "/update"


# 路由映射到页面函数
ROUTES = {
    AppRoutes.HOME: "home_page.home_page_view",
    AppRoutes.MODS: "mods_page.mods_page_view",
    AppRoutes.STEAM_WORKSHOP: "steam_workshop_page.steam_workshop_view",
    AppRoutes.SETTINGS: "settings_page.settings_page_view",
    AppRoutes.UPDATE: "update_page.update_page_view",
}


# 导航项定义
NAVIGATION_ITEMS = [
    {"text": "主页", "icon": "home", "route": AppRoutes.HOME},
    {"text": "模组管理", "icon": "folder_open", "route": AppRoutes.MODS},
    {"text": "创意工坊", "icon": "store", "route": AppRoutes.STEAM_WORKSHOP},
    {"text": "设置", "icon": "settings", "route": AppRoutes.SETTINGS},
]