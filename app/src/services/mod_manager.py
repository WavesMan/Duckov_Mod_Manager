# services/mod_manager.py
import os
import json
import shutil
import configparser
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
                    # 获取模组信息
                    mod_info = self._get_mod_info(item, item_path)
                    downloaded_mods.append(mod_info)
        except Exception as e:
            print(f"获取已下载模组时出错: {e}")
            
        print(f"找到 {len(downloaded_mods)} 个已下载的模组")
        return downloaded_mods
    
    def _get_mod_info(self, mod_id: str, mod_path: str) -> Dict[str, str]:
        """
        获取模组详细信息
        
        Args:
            mod_id (str): 模组ID
            mod_path (str): 模组路径
            
        Returns:
            Dict[str, str]: 模组信息
        """
        mod_info = {
            'id': mod_id,
            'path': mod_path,
            'name': f"模组 {mod_id}",
            'display_name': f"模组 {mod_id}",
            'description': "暂无描述",
            'version': "1.0.0",
            'size': self._get_directory_size(mod_path)
        }
        
        # 尝试从模组目录中的info.ini文件获取信息
        info_ini_path = os.path.join(mod_path, 'info.ini')
        if os.path.exists(info_ini_path):
            try:
                with open(info_ini_path, 'r', encoding='utf-8-sig') as f:
                    for line in f:
                        line = line.strip()
                        if line and '=' in line:
                            key, value = line.split('=', 1)
                            key = key.strip()
                            value = value.strip()
                            if key == 'displayName':
                                mod_info['display_name'] = value
                            elif key == 'name' and not mod_info.get('display_name'):
                                mod_info['display_name'] = value
                            elif key == 'name':
                                mod_info['name'] = value
                            elif key == 'description':
                                mod_info['description'] = value
                            elif key == 'version':
                                mod_info['version'] = value
            except Exception as e:
                print(f"读取info.ini时出错: {e}")
        
        # 尝试从模组目录中的json文件获取更多信息
        try:
            for file_name in os.listdir(mod_path):
                if file_name.endswith('.json'):
                    info_file_path = os.path.join(mod_path, file_name)
                    try:
                        with open(info_file_path, 'r', encoding='utf-8') as f:
                            info_data = json.load(f)
                            if 'name' in info_data and mod_info['name'] == f"模组 {mod_id}":
                                mod_info['name'] = info_data['name']
                            if 'version' in info_data:
                                mod_info['version'] = info_data['version']
                            break
                    except:
                        pass
        except:
            pass
            
        return mod_info
    
    def _get_directory_size(self, path: str) -> str:
        """
        计算目录大小并返回格式化字符串
        
        Args:
            path (str): 目录路径
            
        Returns:
            str: 格式化的大小字符串
        """
        total_size = 0
        try:
            for dirpath, dirnames, filenames in os.walk(path):
                for filename in filenames:
                    filepath = os.path.join(dirpath, filename)
                    if os.path.exists(filepath):
                        total_size += os.path.getsize(filepath)
        except:
            pass
            
        # 格式化大小
        if total_size < 1024:
            return f"{total_size} B"
        elif total_size < 1024 * 1024:
            return f"{total_size // 1024} KB"
        elif total_size < 1024 * 1024 * 1024:
            return f"{total_size // (1024 * 1024)} MB"
        else:
            return f"{total_size // (1024 * 1024 * 1024)} GB"
    
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
    
    def get_mods_directory(self) -> str:
        """
        获取游戏模组目录路径
        
        Returns:
            str: 游戏模组目录路径
        """
        game_directory = config_manager.get("game_directory", "")
        if game_directory:
            mods_directory = os.path.join(game_directory, "Duckov_Data", "Mods")
            # 确保目录存在
            os.makedirs(mods_directory, exist_ok=True)
            return mods_directory
        return ""
    
    def get_global_json_path(self) -> str:
        """
        获取游戏Global.json文件路径
        
        Returns:
            str: Global.json文件路径
        """
        # 获取用户数据目录
        user_data_path = os.path.expandvars("%USERPROFILE%\AppData\LocalLow\TeamSoda\Duckov\Saves")
        # 确保目录存在
        os.makedirs(user_data_path, exist_ok=True)
        return os.path.join(user_data_path, "Global.json")
    
    def is_mod_enabled(self, mod_id: str) -> bool:
        """
        检查模组是否已启用（通过检查Global.json中的配置）
        
        Args:
            mod_id (str): 模组ID
            
        Returns:
            bool: 如果模组已启用返回True，否则返回False
        """
        try:
            # 获取模组信息以获取显示名称
            mod_info = self._get_mod_info(mod_id, os.path.join(self.workshop_path, mod_id))
            mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_id}'))
            
            # 获取Global.json文件路径
            global_json_path = self.get_global_json_path()
            
            # 如果文件不存在，创建一个默认的
            if not os.path.exists(global_json_path):
                default_content = {}
                with open(global_json_path, 'w', encoding='utf-8') as f:
                    json.dump(default_content, f, ensure_ascii=False, indent=4)
                return False
            
            # 读取Global.json文件
            with open(global_json_path, 'r', encoding='utf-8') as f:
                global_data = json.load(f)
            
            # 检查对应的模组启用状态
            mod_key = f"ModActive_{mod_name}"
            if mod_key in global_data and isinstance(global_data[mod_key], dict):
                return global_data[mod_key].get("value", False)
            
            return False
        except Exception as e:
            print(f"检查模组启用状态时出错: {e}")
            return False
    
    def enable_mod(self, mod_id: str) -> bool:
        """
        启用模组（通过修改Global.json文件）
        
        Args:
            mod_id (str): 模组ID
            
        Returns:
            bool: 如果启用成功返回True，否则返回False
        """
        try:
            # 获取源模组路径
            self._update_workshop_path()
            if not self.workshop_path:
                print("工作坊路径为空")
                return False
                
            source_mod_path = os.path.join(self.workshop_path, mod_id)
            if not os.path.exists(source_mod_path):
                print(f"源模组路径不存在: {source_mod_path}")
                return False
            
            # 获取模组信息以获取显示名称
            mod_info = self._get_mod_info(mod_id, source_mod_path)
            mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_id}'))
            
            # 获取Global.json文件路径
            global_json_path = self.get_global_json_path()
            
            # 如果文件不存在，创建一个默认的
            if not os.path.exists(global_json_path):
                default_content = {}
                with open(global_json_path, 'w', encoding='utf-8') as f:
                    json.dump(default_content, f, ensure_ascii=False, indent=4)
            
            # 读取Global.json文件
            with open(global_json_path, 'r', encoding='utf-8') as f:
                global_data = json.load(f)
            
            # 更新模组启用状态
            mod_key = f"ModActive_{mod_name}"
            global_data[mod_key] = {
                "__type": "bool",
                "value": True
            }
            
            # 写入修改后的内容
            with open(global_json_path, 'w', encoding='utf-8') as f:
                json.dump(global_data, f, ensure_ascii=False, indent=4)
            
            print(f"模组 {mod_id} ({mod_name}) 启用成功")
            return True
        except Exception as e:
            print(f"启用模组时出错: {e}")
            import traceback
            traceback.print_exc()
            return False
    
    def disable_mod(self, mod_id: str) -> bool:
        """
        禁用模组（通过修改Global.json文件）
        
        Args:
            mod_id (str): 模组ID
            
        Returns:
            bool: 如果禁用成功返回True，否则返回False
        """
        try:
            # 获取源模组路径
            self._update_workshop_path()
            if not self.workshop_path:
                print("工作坊路径为空")
                return False
                
            source_mod_path = os.path.join(self.workshop_path, mod_id)
            if not os.path.exists(source_mod_path):
                print(f"源模组路径不存在: {source_mod_path}")
                return False
            
            # 获取模组信息以获取显示名称
            mod_info = self._get_mod_info(mod_id, source_mod_path)
            mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_id}'))
            
            # 获取Global.json文件路径
            global_json_path = self.get_global_json_path()
            
            # 如果文件不存在，创建一个默认的
            if not os.path.exists(global_json_path):
                default_content = {}
                with open(global_json_path, 'w', encoding='utf-8') as f:
                    json.dump(default_content, f, ensure_ascii=False, indent=4)
                return True
            
            # 读取Global.json文件
            with open(global_json_path, 'r', encoding='utf-8') as f:
                global_data = json.load(f)
            
            # 更新模组启用状态
            mod_key = f"ModActive_{mod_name}"
            global_data[mod_key] = {
                "__type": "bool",
                "value": False
            }
            
            # 写入修改后的内容
            with open(global_json_path, 'w', encoding='utf-8') as f:
                json.dump(global_data, f, ensure_ascii=False, indent=4)
            
            print(f"模组 {mod_id} ({mod_name}) 禁用成功")
            return True
        except Exception as e:
            print(f"禁用模组时出错: {e}")
            import traceback
            traceback.print_exc()
            return False


# 创建全局模组管理器实例
mod_manager = ModManager()
