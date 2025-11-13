# services/mod_collection_manager.py
import os
import json
from typing import List, Dict, Optional
from .config_manager import config_manager
from .mod_manager import mod_manager


class ModCollectionManager:
    """Mod合集管理器，负责管理用户创建的Mod合集"""
    
    def __init__(self):
        self.collections_file = os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 
            "data", 
            "mod_collections.json"
        )
        # 确保data目录存在
        os.makedirs(os.path.dirname(self.collections_file), exist_ok=True)
        self._collections_cache = None
        self._load_collections()
    
    def _load_collections(self) -> List[Dict]:
        """加载合集数据"""
        if self._collections_cache is not None:
            return self._collections_cache
            
        if os.path.exists(self.collections_file):
            try:
                with open(self.collections_file, 'r', encoding='utf-8') as f:
                    self._collections_cache = json.load(f)
                    # 确保每个合集都有mods_order字段
                    for collection in self._collections_cache:
                        if 'mods_order' not in collection:
                            collection['mods_order'] = []
                    return self._collections_cache
            except Exception as e:
                print(f"加载合集数据时出错: {e}")
                return []
        else:
            # 如果文件不存在，创建默认的空数组
            self._collections_cache = []
            self._save_collections()
            return self._collections_cache
    
    def _save_collections(self):
        """保存合集数据"""
        try:
            with open(self.collections_file, 'w', encoding='utf-8') as f:
                json.dump(self._collections_cache, f, ensure_ascii=False, indent=4)
        except Exception as e:
            print(f"保存合集数据时出错: {e}")
    
    def get_collections(self) -> List[Dict]:
        """获取所有合集"""
        return self._load_collections()
    
    def get_collection_by_id(self, collection_id: str) -> Optional[Dict]:
        """根据ID获取特定合集"""
        collections = self.get_collections()
        for collection in collections:
            if collection.get('id') == collection_id:
                return collection
        return None
    
    def create_collection(self, name: str) -> str:
        """创建新合集"""
        import uuid
        collections = self._load_collections()
        
        # 生成唯一ID
        collection_id = str(uuid.uuid4())
        
        # 创建新合集
        new_collection = {
            'id': collection_id,
            'name': name,
            'mods': [],  # 存储模组ID列表
            'mods_order': []  # 存储模组显示顺序
        }
        
        collections.append(new_collection)
        self._save_collections()
        self._collections_cache = None  # 清除缓存
        return collection_id
    
    def update_collection_name(self, collection_id: str, new_name: str) -> bool:
        """更新合集名称"""
        collections = self._load_collections()
        for collection in collections:
            if collection.get('id') == collection_id:
                collection['name'] = new_name
                self._save_collections()
                self._collections_cache = None  # 清除缓存
                return True
        return False
    
    def delete_collection(self, collection_id: str) -> bool:
        """删除合集"""
        collections = self._load_collections()
        for i, collection in enumerate(collections):
            if collection.get('id') == collection_id:
                collections.pop(i)
                self._save_collections()
                self._collections_cache = None  # 清除缓存
                return True
        return False
    
    def add_mods_to_collection(self, collection_id: str, mod_ids: List[str]) -> bool:
        """向合集中添加模组"""
        collections = self._load_collections()
        for collection in collections:
            if collection.get('id') == collection_id:
                # 添加模组ID（去重）
                for mod_id in mod_ids:
                    if mod_id not in collection['mods']:
                        collection['mods'].append(mod_id)
                        collection['mods_order'].append(mod_id)
                self._save_collections()
                self._collections_cache = None  # 清除缓存
                return True
        return False
    
    def remove_mods_from_collection(self, collection_id: str, mod_ids: List[str]) -> bool:
        """从合集中移除模组"""
        collections = self._load_collections()
        for collection in collections:
            if collection.get('id') == collection_id:
                # 移除模组ID
                collection['mods'] = [mod_id for mod_id in collection['mods'] if mod_id not in mod_ids]
                collection['mods_order'] = [mod_id for mod_id in collection['mods_order'] if mod_id not in mod_ids]
                self._save_collections()
                self._collections_cache = None  # 清除缓存
                return True
        return False
    
    def update_mods_order(self, collection_id: str, mods_order: List[str]) -> bool:
        """更新合集中模组的显示顺序"""
        collections = self._load_collections()
        for collection in collections:
            if collection.get('id') == collection_id:
                collection['mods_order'] = mods_order
                self._save_collections()
                self._collections_cache = None  # 清除缓存
                return True
        return False
    
    def get_collection_mods(self, collection_id: str) -> List[Dict]:
        """获取合集中的模组详细信息（按指定顺序）"""
        collection = self.get_collection_by_id(collection_id)
        if not collection:
            return []
        
        # 获取所有已下载的模组信息
        all_mods = {mod['id']: mod for mod in mod_manager.get_downloaded_mods()}
        
        # 按照指定顺序返回模组信息
        ordered_mods = []
        for mod_id in collection.get('mods_order', []):
            if mod_id in all_mods:
                ordered_mods.append(all_mods[mod_id])
        
        # 添加未在顺序列表中的模组（防止数据丢失）
        for mod_id in collection.get('mods', []):
            if mod_id not in collection.get('mods_order', []) and mod_id in all_mods:
                ordered_mods.append(all_mods[mod_id])
        
        return ordered_mods
    
    def enable_collection(self, collection_id: str) -> bool:
        """启用合集（禁用其他所有合集，只启用当前合集）"""
        collections = self.get_collections()
        
        # 先禁用所有合集中的模组
        all_mod_ids = set()
        for collection in collections:
            all_mod_ids.update(collection.get('mods', []))
        
        # 批量禁用所有模组
        if all_mod_ids:
            mod_manager.batch_disable_mods(list(all_mod_ids))
        
        # 启用当前合集的模组
        target_collection = self.get_collection_by_id(collection_id)
        if target_collection and target_collection.get('mods'):
            result = mod_manager.batch_enable_mods(target_collection['mods'])
            # 检查是否有启用失败的模组
            failed_count = sum(1 for success in result.values() if not success)
            if failed_count > 0:
                print(f"有 {failed_count} 个模组启用失败")
            return all(success for success in result.values())
        
        return True
    
    def disable_collection(self, collection_id: str) -> bool:
        """禁用合集"""
        collection = self.get_collection_by_id(collection_id)
        if collection and collection.get('mods'):
            result = mod_manager.batch_disable_mods(collection['mods'])
            # 检查是否有禁用失败的模组
            failed_count = sum(1 for success in result.values() if not success)
            if failed_count > 0:
                print(f"有 {failed_count} 个模组禁用失败")
            return all(success for success in result.values())
        return True


# 创建全局Mod合集管理器实例
collection_manager = ModCollectionManager()