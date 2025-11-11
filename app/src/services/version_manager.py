# services/version_manager.py
import requests
import re
import logging
from typing import Optional, Dict, Any
from urllib.parse import urlparse

logger = logging.getLogger(__name__)


class VersionManager:
    """版本管理器，负责检查应用更新"""
    
    def __init__(self):
        # 测试用的 GitHub 仓库
        self.github_repo = "WavesMan/Duckov_Mod_Manager"
        self.github_api_url = f"https://api.github.com/repos/{self.github_repo}/releases/latest"
        
    def get_current_version(self) -> str:
        """获取当前应用版本"""
        # 从配置管理器中读取版本信息
        from services.config_manager import config_manager
        return config_manager.get("current_version", "0.1.1")
    
    def format_version(self, version_str: str) -> str:
        """格式化版本字符串为标准格式 (major.minor.patch)"""
        # 移除前缀如 "EXE-v", "v" 等
        version_str = re.sub(r'^[A-Za-z\-_]*v?', '', version_str)
        
        # 分割版本号
        parts = version_str.split('.')
        
        # 确保至少有 major.minor.patch 三部分
        if len(parts) == 1:
            # 只有主版本号，添加 .0.0
            return f"{parts[0]}.0.0"
        elif len(parts) == 2:
            # 有主版本号和次版本号，添加 .0
            return f"{parts[0]}.{parts[1]}.0"
        else:
            # 已经有三个部分，直接返回
            return '.'.join(parts[:3])
    
    def compare_versions(self, version1: str, version2: str) -> int:
        """比较两个版本号
        返回: 1 表示 version1 > version2, -1 表示 version1 < version2, 0 表示相等
        """
        v1_parts = list(map(int, version1.split('.')))
        v2_parts = list(map(int, version2.split('.')))
        
        # 确保两个版本号都有相同数量的部分
        max_parts = max(len(v1_parts), len(v2_parts))
        v1_parts.extend([0] * (max_parts - len(v1_parts)))
        v2_parts.extend([0] * (max_parts - len(v2_parts)))
        
        for v1, v2 in zip(v1_parts, v2_parts):
            if v1 > v2:
                return 1
            elif v1 < v2:
                return -1
        
        return 0
    
    def get_latest_release_info(self) -> Optional[Dict[str, Any]]:
        """获取最新的发布信息"""
        try:
            logger.info(f"正在检查更新，API URL: {self.github_api_url}")
            
            # 设置请求头，避免 GitHub API 限流
            headers = {
                'Accept': 'application/vnd.github.v3+json',
                'User-Agent': 'Duckov-Mod-Manager'
            }
            
            response = requests.get(self.github_api_url, headers=headers, timeout=10)
            response.raise_for_status()
            
            release_data = response.json()
            logger.info(f"成功获取发布信息: {release_data.get('tag_name', 'Unknown')}")
            
            return release_data
            
        except requests.exceptions.RequestException as e:
            logger.error(f"获取发布信息失败: {e}")
            return None
        except Exception as e:
            logger.error(f"处理发布信息时发生错误: {e}")
            return None
    
    def check_for_updates(self) -> Dict[str, Any]:
        """检查是否有更新可用"""
        current_version = self.get_current_version()
        formatted_current = self.format_version(current_version)
        
        result = {
            'has_update': False,
            'current_version': current_version,
            'formatted_current': formatted_current,
            'latest_version': None,
            'formatted_latest': None,
            'release_info': None,
            'download_url': None,
            'error': None
        }
        
        release_info = self.get_latest_release_info()
        if not release_info:
            result['error'] = '无法获取发布信息'
            return result
        
        # 提取最新版本信息
        latest_tag = release_info.get('tag_name', '')
        formatted_latest = self.format_version(latest_tag)
        
        result.update({
            'latest_version': latest_tag,
            'formatted_latest': formatted_latest,
            'release_info': release_info,
            'download_url': release_info.get('html_url', '')  # 发布页面URL
        })
        
        # 比较版本
        comparison = self.compare_versions(formatted_latest, formatted_current)
        result['has_update'] = comparison > 0
        
        logger.info(f"版本检查结果: 当前 {formatted_current}, 最新 {formatted_latest}, 有更新: {result['has_update']}")
        
        return result
    
    def open_download_page(self, download_url: str) -> bool:
        """打开浏览器跳转到下载页面"""
        try:
            import webbrowser
            webbrowser.open(download_url)
            logger.info(f"已打开下载页面: {download_url}")
            return True
        except Exception as e:
            logger.error(f"打开下载页面失败: {e}")
            return False


# 创建全局版本管理器实例
version_manager = VersionManager()
