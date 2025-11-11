"""
ModManagerBridge 客户端库
提供统一的 JSON 格式和错误处理
"""

import socket
import json
import time
from typing import Optional, Dict, Any, List

class ModManagerClient:
    """ModManagerBridge 客户端类"""
    
    def __init__(self, host: str = '127.0.0.1', port: int = 38274, timeout: int = 5):
        self.host = host
        self.port = port
        self.timeout = timeout
    
    def send_command(self, command: str, parameters: Optional[Dict[str, Any]] = None) -> Optional[Dict[str, Any]]:
        """
        发送命令到 ModManagerBridge
        
        Args:
            command: 命令名称
            parameters: 命令参数
            
        Returns:
            响应数据或 None（如果出错）
        """
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.settimeout(self.timeout)
        
        try:
            client.connect((self.host, self.port))
            
            # 构造标准化的命令对象
            command_obj = {
                "command": command,
                "parameters": parameters or {}
            }
            
            # 发送 JSON 格式的命令
            command_json = json.dumps(command_obj, ensure_ascii=False)
            client.send(command_json.encode('utf-8'))
            
            # 接收响应
            response_data = client.recv(4096).decode('utf-8')
            return json.loads(response_data)
            
        except ConnectionRefusedError:
            raise ConnectionError(f"无法连接到 ModManagerBridge ({self.host}:{self.port})，请确保 mod 正在运行")
        except socket.timeout:
            raise TimeoutError(f"连接超时：无法连接到 {self.host}:{self.port}")
        except Exception as e:
            raise RuntimeError(f"命令执行错误：{e}")
        finally:
            client.close()
    
    def get_mod_list(self) -> List[Dict[str, Any]]:
        """获取 mod 列表"""
        response = self.send_command("get_mod_list")
        if response and response.get("status") == "success":
            return response.get("data", [])
        return []
    
    def get_mod_info(self, mod_name: str) -> Optional[Dict[str, Any]]:
        """获取指定 mod 的信息"""
        response = self.send_command("get_mod_info", {"ModName": mod_name})
        if response and response.get("status") == "success":
            return response.get("data", {})
        return None
    
    def enable_mod(self, mod_name: str) -> bool:
        """启用指定 mod"""
        response = self.send_command("enable_mod", {"ModName": mod_name})
        return response is not None and response.get("status") == "success"
    
    def disable_mod(self, mod_name: str) -> bool:
        """禁用指定 mod"""
        response = self.send_command("disable_mod", {"ModName": mod_name})
        return response is not None and response.get("status") == "success"
    
    def test_connection(self) -> bool:
        """测试连接是否正常"""
        try:
            response = self.send_command("get_mod_list")
            return response is not None
        except:
            return False


# 便捷函数
def create_client(host: str = '127.0.0.1', port: int = 38274) -> ModManagerClient:
    """创建 ModManagerBridge 客户端实例"""
    return ModManagerClient(host, port)


def send_command(command: str, parameters: Optional[Dict[str, Any]] = None, 
                host: str = '127.0.0.1', port: int = 38274) -> Optional[Dict[str, Any]]:
    """
    便捷函数：发送命令到 ModManagerBridge
    
    Args:
        command: 命令名称
        parameters: 命令参数
        host: 主机地址
        port: 端口号
        
    Returns:
        响应数据或 None（如果出错）
    """
    client = ModManagerClient(host, port)
    return client.send_command(command, parameters)


if __name__ == "__main__":
    # 测试客户端功能
    client = ModManagerClient()
    
    print("ModManagerBridge 客户端测试")
    print("=" * 30)
    
    # 测试连接
    if client.test_connection():
        print("✅ 连接成功")
        
        # 获取 mod 列表
        mods = client.get_mod_list()
        if mods:
            print(f"✅ 找到 {len(mods)} 个 mod")
            for mod in mods[:5]:  # 只显示前5个
                name = mod.get('name', 'Unknown')
                enabled = mod.get('enabled', False)
                status = "🟢 已启用" if enabled else "🔴 已禁用"
                print(f"  - {name} ({status})")
        else:
            print("❌ 获取 mod 列表失败")
    else:
        print("❌ 连接失败")
