# config_manager.py
import json
import os

# 配置文件路径
CONFIG_FILE = "app_config.json"

# 默认配置
DEFAULT_CONFIG = {
    "game_directory": "C:/Games/MyGame/Mods",
    "cache_directory": "C:/Games/MyGame/Cache",
    "temp_directory": "C:/Temp/MyGame",
    "language": "简体中文",
    "auto_update": True,
    "minimize_to_tray": False,
    "enable_animations": True,
    # 版本检查相关配置
    "last_update_check": None,  # 最后检查更新时间
    "current_version": "0.1.0",  # 当前应用版本
    "skip_version": None,  # 跳过的版本号
    # 移除了 steam_api_key 和 steam_id 配置项
}


class ConfigManager:
    """配置管理器，负责配置的加载、保存和管理"""

    def __init__(self):
        self.config = DEFAULT_CONFIG.copy()
        self.load_config()

    def load_config(self):
        """从配置文件加载配置"""
        try:
            if os.path.exists(CONFIG_FILE):
                with open(CONFIG_FILE, 'r', encoding='utf-8') as f:
                    loaded_config = json.load(f)
                    # 合并默认配置和加载的配置，确保所有键都存在
                    self.config = {**DEFAULT_CONFIG, **loaded_config}
            else:
                # 如果配置文件不存在，保存默认配置
                self.save_config()
        except Exception as e:
            print(f"加载配置文件时出错: {e}")
            # 出错时使用默认配置
            self.config = DEFAULT_CONFIG.copy()

    def save_config(self):
        """保存配置到文件"""
        try:
            with open(CONFIG_FILE, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, ensure_ascii=False, indent=4)
        except Exception as e:
            print(f"保存配置文件时出错: {e}")

    def get(self, key, default=None):
        """获取配置项"""
        return self.config.get(key, default)

    def set(self, key, value):
        """设置配置项"""
        self.config[key] = value
        # 自动保存配置
        self.save_config()

    def get_all(self):
        """获取所有配置"""
        return self.config.copy()

    def reset_to_default(self):
        """重置为默认配置"""
        self.config = DEFAULT_CONFIG.copy()
        self.save_config()

    def get_steam_workshop_path(self):
        """根据游戏目录获取Steam创意工坊路径"""
        game_directory = self.get("game_directory", "")
        if game_directory and "Escape from Duckov" in game_directory:
            # 回退到steamapps目录
            steamapps_path = os.path.dirname(os.path.dirname(game_directory))
            if steamapps_path:
                # 构造创意工坊路径
                workshop_path = os.path.join(steamapps_path, "workshop", "content", "3167020")
                return workshop_path
        return None


# 创建全局配置管理器实例
config_manager = ConfigManager()
