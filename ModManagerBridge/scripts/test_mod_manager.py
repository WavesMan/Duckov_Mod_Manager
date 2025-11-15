#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
ModManagerBridge 测试脚本
用于测试与游戏中的ModManagerBridge mod的WebSocket连接
"""

import asyncio
import websockets
import json
import sys
import argparse


class ModManagerClient:
    def __init__(self, uri):
        self.uri = uri
        self.websocket = None

    async def connect(self):
        """连接到WebSocket服务器"""
        try:
            self.websocket = await websockets.connect(self.uri)
            print(f"已连接到 {self.uri}")
            return True
        except Exception as e:
            print(f"连接失败: {e}")
            return False

    async def disconnect(self):
        """断开连接"""
        if self.websocket:
            await self.websocket.close()
            print("连接已断开")

    async def send_request(self, action, data=None):
        """发送请求到服务器"""
        if not self.websocket:
            print("未连接到服务器")
            return None

        request = {
            "action": action,
            "data": data
        }

        try:
            await self.websocket.send(json.dumps(request))
            response = await self.websocket.recv()
            return json.loads(response)
        except Exception as e:
            print(f"发送请求时出错: {e}")
            return None

    async def get_mod_list(self):
        """获取mod列表"""
        print("正在获取mod列表...")
        response = await self.send_request("get_mod_list")
        if response and response.get("success"):
            # 注意：data字段是一个JSON字符串，需要先解析
            mods_data = response.get("data", "[]")
            try:
                mods = json.loads(mods_data)
            except json.JSONDecodeError as e:
                print(f"解析mod列表数据时出错: {e}")
                return
                
            print(f"找到 {len(mods)} 个mod:")
            for mod in mods:
                status = "已激活" if mod.get("isActive") else "未激活"
                print(f"  - Mod_Name: {mod.get('name')}  ")
                print(f"    DisplayName: {mod.get('displayName')}")
                print(f"    是否启用： [{status}]")
                print(f"    路径: {mod.get('path')}")
                print(f"    创意工坊ID： {mod.get('publishedFileId')}")
                print(f"    描述: {mod.get('description')}")
        else:
            print(f"获取mod列表失败: {response.get('message') if response else '未知错误'}")

    async def activate_mod(self, mod_name):
        """激活指定mod"""
        print(f"正在激活mod: {mod_name}")
        # 使用json.dumps确保mod名称被引号包裹
        response = await self.send_request("activate_mod", json.dumps(mod_name))
        if response and response.get("success"):
            print(f"Mod '{mod_name}' 激活成功")
        else:
            print(f"激活mod失败: {response.get('message') if response else '未知错误'}")

    async def deactivate_mod(self, mod_name):
        """停用指定mod"""
        print(f"正在停用mod: {mod_name}")
        # 使用json.dumps确保mod名称被引号包裹
        response = await self.send_request("deactivate_mod", json.dumps(mod_name))
        if response and response.get("success"):
            print(f"Mod '{mod_name}' 停用成功")
        else:
            print(f"停用mod失败: {response.get('message') if response else '未知错误'}")

    async def activate_mods(self, mod_names):
        """批量激活mods"""
        print(f"正在批量激活mods: {', '.join(mod_names)}")
        # 直接发送mod名称列表的JSON表示，无需额外的引号包装
        response = await self.send_request("activate_mods", json.dumps(mod_names))
        if response and response.get("success"):
            print(f"批量激活成功: {response.get('message')}")
        else:
            print(f"批量激活失败: {response.get('message') if response else '未知错误'}")

    async def deactivate_mods(self, mod_names):
        """批量停用mods"""
        print(f"正在批量停用mods: {', '.join(mod_names)}")
        # 直接发送mod名称列表的JSON表示，无需额外的引号包装
        response = await self.send_request("deactivate_mods", json.dumps(mod_names))
        if response and response.get("success"):
            print(f"批量停用成功: {response.get('message')}")
        else:
            print(f"批量停用失败: {response.get('message') if response else '未知错误'}")

    async def rescan_mods(self):
        """重新扫描mods"""
        print("正在重新扫描mods...")
        response = await self.send_request("rescan_mods")
        if response and response.get("success"):
            print("Mods重新扫描成功")
        else:
            print(f"重新扫描mods失败: {response.get('message') if response else '未知错误'}")


async def interactive_mode(client):
    """交互模式"""
    print("\n=== ModManagerBridge 交互式测试客户端 ===")
    show_help()
    print("\n")

    while True:
        try:
            user_input = await asyncio.get_event_loop().run_in_executor(None, input, "请输入命令或数字: ")
            command = user_input.strip().lower()

            if command in ['quit', 'exit', '6']:
                print("退出程序...")
                break
            elif command in ['list', '1']:
                await client.get_mod_list()
            elif command in ['activate', '2']:
                mod_name = input("请输入要激活的mod名称: ").strip()
                if mod_name:
                    await client.activate_mod(mod_name)
                else:
                    print("错误: mod名称不能为空")
            elif command in ['deactivate', '3']:
                mod_name = input("请输入要停用的mod名称: ").strip()
                if mod_name:
                    await client.deactivate_mod(mod_name)
                else:
                    print("错误: mod名称不能为空")
            elif command in ['rescan', '4']:
                await client.rescan_mods()
            elif command in ['help', 'h', '?', '5']:
                show_help()
            elif command in ['batch_activate']:
                mod_names_input = input("请输入要激活的mod名称列表(用逗号分隔): ").strip()
                if mod_names_input:
                    mod_names = [name.strip() for name in mod_names_input.split(",")]
                    await client.activate_mods(mod_names)
                else:
                    print("错误: mod名称列表不能为空")
            elif command in ['batch_deactivate']:
                mod_names_input = input("请输入要停用的mod名称列表(用逗号分隔): ").strip()
                if mod_names_input:
                    mod_names = [name.strip() for name in mod_names_input.split(",")]
                    await client.deactivate_mods(mod_names)
                else:
                    print("错误: mod名称列表不能为空")
            else:
                print(f"未知命令: {command}. 输入 'help' 或 '5' 查看可用命令.")
        except KeyboardInterrupt:
            print("\n收到中断信号，退出程序...")
            break
        except EOFError:
            print("\n输入结束，退出程序...")
            break
        except Exception as e:
            print(f"处理命令时出错: {e}")

    # 确保连接正确关闭
    try:
        await client.disconnect()
    except:
        pass


def show_help():
    """显示帮助信息"""
    print("可用命令:")
    print("  1. list             - 获取mod列表")
    print("  2. activate         - 激活指定mod")
    print("  3. deactivate       - 停用指定mod")
    print("  4. rescan           - 重新扫描mods")
    print("  5. help             - 显示帮助信息")
    print("  6. quit/exit        - 退出程序")
    print("  batch_activate      - 批量激活mods")
    print("  batch_deactivate    - 批量停用mods")


async def main():
    parser = argparse.ArgumentParser(description="ModManagerBridge 测试客户端")
    parser.add_argument("--host", default="localhost", help="WebSocket服务器主机 (默认: localhost)")
    parser.add_argument("--port", type=int, default=9001, help="WebSocket服务器端口 (默认: 9001)")
    
    subparsers = parser.add_subparsers(dest="command", help="可用命令")
    
    # 获取mod列表命令
    subparsers.add_parser("list", help="获取mod列表")
    
    # 激活mod命令
    activate_parser = subparsers.add_parser("activate", help="激活mod")
    activate_parser.add_argument("mod_name", help="要激活的mod名称")
    
    # 停用mod命令
    deactivate_parser = subparsers.add_parser("deactivate", help="停用mod")
    deactivate_parser.add_argument("mod_name", help="要停用的mod名称")
    
    # 批量激活mods命令
    activate_mods_parser = subparsers.add_parser("activate_mods", help="批量激活mods")
    activate_mods_parser.add_argument("mod_names", nargs="+", help="要激活的mod名称列表")
    
    # 批量停用mods命令
    deactivate_mods_parser = subparsers.add_parser("deactivate_mods", help="批量停用mods")
    deactivate_mods_parser.add_argument("mod_names", nargs="+", help="要停用的mod名称列表")
    
    # 重新扫描命令
    subparsers.add_parser("rescan", help="重新扫描mods")
    
    # 交互模式命令
    subparsers.add_parser("interactive", help="进入交互模式")
    
    args = parser.parse_args()
    
    uri = f"ws://{args.host}:{args.port}"
    client = ModManagerClient(uri)
    
    if not await client.connect():
        return
    
    try:
        if args.command == "list":
            await client.get_mod_list()
        elif args.command == "activate":
            await client.activate_mod(args.mod_name)
        elif args.command == "deactivate":
            await client.deactivate_mod(args.mod_name)
        elif args.command == "activate_mods":
            await client.activate_mods(args.mod_names)
        elif args.command == "deactivate_mods":
            await client.deactivate_mods(args.mod_names)
        elif args.command == "rescan":
            await client.rescan_mods()
        elif args.command == "interactive":
            await interactive_mode(client)
        elif args.command is None:
            # 如果没有指定命令，则进入交互模式
            await interactive_mode(client)
        else:
            parser.print_help()
    except KeyboardInterrupt:
        print("\n程序被用户中断")
    finally:
        try:
            await client.disconnect()
        except:
            pass


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n程序被用户中断")
    except Exception as e:
        print(f"程序执行出错: {e}")