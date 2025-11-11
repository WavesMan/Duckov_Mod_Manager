"""
简单的 ModManagerBridge 测试脚本
用于验证 JSON 通信格式
"""

import socket
import json
import time

def send_simple_command(command, mod_name=None):
    """发送简单的命令到 ModManagerBridge"""
    client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    
    try:
        client.connect(('127.0.0.1', 38274))
        
        # 构造最简单的命令格式
        if mod_name:
            command_obj = {
                "command": command,
                "parameters": {
                    "ModName": mod_name
                }
            }
        else:
            command_obj = {
                "command": command,
                "parameters": {}
            }
        
        # 发送 JSON 格式的命令
        command_json = json.dumps(command_obj)
        print(f"发送命令: {command_json}")
        client.send(command_json.encode('utf-8'))
        
        # 接收响应
        response = client.recv(4096).decode('utf-8')
        print(f"收到响应: {response}")
        return json.loads(response)
    
    except Exception as e:
        print(f"错误: {e}")
        return None
    
    finally:
        client.close()

def test_basic_commands():
    """测试基本命令"""
    print("ModManagerBridge 基础测试")
    print("=" * 30)
    
    # 测试获取 mod 列表
    print("\n1. 测试 get_mod_list 命令")
    response = send_simple_command("get_mod_list")
    if response:
        print(f"状态: {response.get('status')}")
        if response.get('status') == 'success':
            mods = response.get('data', [])
            print(f"找到 {len(mods)} 个 mod")
            for mod in mods[:3]:  # 只显示前3个
                name = mod.get('name', 'Unknown')
                enabled = mod.get('enabled', False)
                status = "已启用" if enabled else "已禁用"
                print(f"  - {name} ({status})")
        else:
            print(f"错误: {response.get('message', '未知错误')}")
    else:
        print("获取 mod 列表失败")
    
    time.sleep(1)
    
    # 测试获取特定 mod 信息
    print("\n2. 测试 get_mod_info 命令")
    response = send_simple_command("get_mod_info", "ModManagerBridge")
    if response:
        print(f"状态: {response.get('status')}")
        if response.get('status') == 'success':
            mod_info = response.get('data', {})
            name = mod_info.get('name', 'Unknown')
            enabled = mod_info.get('enabled', False)
            status = "已启用" if enabled else "已禁用"
            print(f"Mod 信息:")
            print(f"  名称: {name}")
            print(f"  状态: {status}")
        else:
            print(f"错误: {response.get('message', '未知错误')}")
    else:
        print("获取 mod 信息失败")
    
    time.sleep(1)
    
    # 测试启用/禁用 mod
    print("\n3. 测试 enable_mod/disable_mod 命令")
    test_mod = "DisplayTotalReward"
    
    print(f"启用 mod: {test_mod}")
    response = send_simple_command("enable_mod", test_mod)
    if response:
        print(f"状态: {response.get('status')}")
        print(f"消息: {response.get('message', '')}")
    else:
        print("启用 mod 失败")
    
    time.sleep(1)
    
    print(f"禁用 mod: {test_mod}")
    response = send_simple_command("disable_mod", test_mod)
    if response:
        print(f"状态: {response.get('status')}")
        print(f"消息: {response.get('message', '')}")
    else:
        print("禁用 mod 失败")

if __name__ == "__main__":
    test_basic_commands()
