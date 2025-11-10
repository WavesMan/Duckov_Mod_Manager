# services/mod_manager.py
import os
from typing import List, Dict
from .config_manager import config_manager


class ModManager:
    """模组管理器，负责管理本地模组"""
    
    def __init__(self):
        self.workshop_path = None
        self._update_workshop_path()
        
    def _update_workshop_path(self):
        """更新创意工坊路径"""
        self.workshop_path = config_manager.get_steam_workshop_path()
        print(f"工作坊路径更新为: {self.workshop_path}")
    
    def get_downloaded_mods(self) -> List[Dict[str, str]]:
        """
        获取已下载的模组列表
        
        Returns:
            List[Dict[str, str]]: 已下载模组的列表，每个模组包含id和路径信息
        """
        self._update_workshop_path()
        
        if not self.workshop_path or not os.path.exists(self.workshop_path):
            print(f"工作坊路径不存在: {self.workshop_path}")
            return []
            
        downloaded_mods = []
        try:
            # 遍历创意工坊目录下的所有子目录
            for item in os.listdir(self.workshop_path):
                item_path = os.path.join(self.workshop_path, item)
                # 检查是否为目录且目录名是数字（模组ID）
                if os.path.isdir(item_path) and item.isdigit():
                    downloaded_mods.append({
                        'id': item,
                        'path': item_path
                    })
        except Exception as e:
            print(f"获取已下载模组时出错: {e}")
            
        print(f"找到 {len(downloaded_mods)} 个已下载的模组")
        return downloaded_mods
    
    def is_mod_downloaded(self, mod_id: str) -> bool:
        """
        检查模组是否已下载
        
        Args:
            mod_id (str): 模组ID
            
        Returns:
            bool: 如果模组已下载返回True，否则返回False
        """
        if not mod_id:
            return False
            
        self._update_workshop_path()
        
        if not self.workshop_path:
            print("工作坊路径为空")
            return False
            
        mod_path = os.path.join(self.workshop_path, mod_id)
        exists = os.path.exists(mod_path)
        print(f"检查模组 {mod_id} 是否存在: {exists} 路径: {mod_path}")
        return exists


# 创建全局模组管理器实例
mod_manager = ModManager()