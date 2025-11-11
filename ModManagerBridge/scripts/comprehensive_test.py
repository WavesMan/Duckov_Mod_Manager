"""
ModManagerBridge 综合测试脚本
测试所有命令和错误处理
"""

import socket
import json
import time
import sys

class ModManagerTester:
    def __init__(self, host='127.0.0.1', port=38274):
        self.host = host
        self.port = port
        self.timeout = 5
    
    def send_command(self, command, parameters=None):
        """发送命令到 ModManagerBridge"""
        client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        client.settimeout(self.timeout)
        
        try:
            client.connect((self.host, self.port))
            
            # 构造命令对象
            command_obj = {
                "command": command,
                "parameters": parameters or {}
            }
            
            # 发送 JSON 格式的命令
            command_json = json.dumps(command_obj, ensure_ascii=False)
            print(f"📤 发送命令: {command_json}")
            client.send(command_json.encode('utf-8'))
            
            # 接收响应
            response_data = client.recv(4096).decode('utf-8')
            print(f"📥 收到响应: {response_data}")
            return json.loads(response_data)
            
        except ConnectionRefusedError:
            print(f"❌ 连接被拒绝：请确保 ModManagerBridge 正在运行 ({self.host}:{self.port})")
            return None
        except socket.timeout:
            print(f"⏰ 连接超时：无法连接到 {self.host}:{self.port}")
            return None
        except Exception as e:
            print(f"❌ 命令执行错误：{e}")
            return None
        finally:
            client.close()
    
    def test_connection(self):
        """测试连接是否正常"""
        print("🔗 测试连接...")
        response = self.send_command("get_mod_list")
        return response is not None
    
    def test_get_mod_list(self):
        """测试获取 mod 列表"""
        print("\n📋 测试 get_mod_list 命令")
        response = self.send_command("get_mod_list")
        
        if response:
            status = response.get('status')
            if status == 'success':
                mods = response.get('data', [])
                print(f"✅ 成功获取 {len(mods)} 个 mod")
                for mod in mods:
                    name = mod.get('name', 'Unknown')
                    enabled = mod.get('enabled', False)
                    version = mod.get('version', 'Unknown')
                    author = mod.get('author', 'Unknown')
                    status_icon = "🟢" if enabled else "🔴"
                    print(f"   {status_icon} {name} (v{version}) - {author}")
                return True
            else:
                print(f"❌ 命令失败: {response.get('message', '未知错误')}")
                return False
        else:
            print("❌ 获取 mod 列表失败")
            return False
    
    def test_get_mod_info(self, mod_name):
        """测试获取特定 mod 信息"""
        print(f"\nℹ️  测试 get_mod_info 命令: {mod_name}")
        response = self.send_command("get_mod_info", {"ModName": mod_name})
        
        if response:
            status = response.get('status')
            if status == 'success':
                mod_info = response.get('data', {})
                name = mod_info.get('name', 'Unknown')
                enabled = mod_info.get('enabled', False)
                version = mod_info.get('version', 'Unknown')
                author = mod_info.get('author', 'Unknown')
                status_icon = "🟢" if enabled else "🔴"
                print(f"✅ Mod 信息:")
                print(f"   名称: {name}")
                print(f"   状态: {status_icon} {'已启用' if enabled else '已禁用'}")
                print(f"   版本: {version}")
                print(f"   作者: {author}")
                return True
            else:
                print(f"❌ 命令失败: {response.get('message', '未知错误')}")
                return False
        else:
            print(f"❌ 获取 mod 信息失败: {mod_name}")
            return False
    
    def test_enable_mod(self, mod_name):
        """测试启用 mod"""
        print(f"\n🔄 测试 enable_mod 命令: {mod_name}")
        response = self.send_command("enable_mod", {"ModName": mod_name})
        
        if response:
            status = response.get('status')
            message = response.get('message', '')
            if status == 'success':
                print(f"✅ {message}")
                return True
            else:
                print(f"❌ {message}")
                return False
        else:
            print(f"❌ 启用 mod 失败: {mod_name}")
            return False
    
    def test_disable_mod(self, mod_name):
        """测试禁用 mod"""
        print(f"\n🛑 测试 disable_mod 命令: {mod_name}")
        response = self.send_command("disable_mod", {"ModName": mod_name})
        
        if response:
            status = response.get('status')
            message = response.get('message', '')
            if status == 'success':
                print(f"✅ {message}")
                return True
            else:
                print(f"❌ {message}")
                return False
        else:
            print(f"❌ 禁用 mod 失败: {mod_name}")
            return False
    
    def test_invalid_command(self):
        """测试无效命令"""
        print("\n❓ 测试无效命令")
        response = self.send_command("invalid_command")
        
        if response:
            status = response.get('status')
            if status == 'error':
                print(f"✅ 正确处理无效命令: {response.get('message', '')}")
                return True
            else:
                print(f"❌ 无效命令处理异常")
                return False
        else:
            print("❌ 无效命令测试失败")
            return False
    
    def test_empty_parameters(self):
        """测试空参数"""
        print("\n📭 测试空参数")
        response = self.send_command("get_mod_info", {})
        
        if response:
            print(f"✅ 空参数处理正常")
            return True
        else:
            print("❌ 空参数测试失败")
            return False
    
    def run_comprehensive_test(self):
        """运行综合测试"""
        print("=" * 50)
        print("ModManagerBridge 综合测试")
        print("=" * 50)
        
        # 测试连接
        if not self.test_connection():
            print("\n❌ 连接测试失败，无法继续测试")
            return False
        
        print("\n✅ 连接测试通过")
        
        # 记录测试结果
        test_results = []
        
        # 测试获取 mod 列表
        test_results.append(("获取 mod 列表", self.test_get_mod_list()))
        time.sleep(1)
        
        # 测试获取特定 mod 信息
        test_results.append(("获取 mod 信息", self.test_get_mod_info("ModManagerBridge")))
        time.sleep(1)
        
        # 测试启用/禁用 mod (使用示例 mod)
        test_mod = "DisplayTotalReward"
        test_results.append((f"启用 mod: {test_mod}", self.test_enable_mod(test_mod)))
        time.sleep(1)
        
        test_results.append((f"禁用 mod: {test_mod}", self.test_disable_mod(test_mod)))
        time.sleep(1)
        
        # 测试无效命令
        test_results.append(("无效命令处理", self.test_invalid_command()))
        time.sleep(1)
        
        # 测试空参数
        test_results.append(("空参数处理", self.test_empty_parameters()))
        
        # 显示测试结果摘要
        print("\n" + "=" * 50)
        print("测试结果摘要")
        print("=" * 50)
        
        passed = 0
        failed = 0
        
        for test_name, result in test_results:
            status = "✅ 通过" if result else "❌ 失败"
            print(f"{status} - {test_name}")
            if result:
                passed += 1
            else:
                failed += 1
        
        print(f"\n📊 总计: {passed} 通过, {failed} 失败")
        
        if failed == 0:
            print("🎉 所有测试通过！")
            return True
        else:
            print("⚠️  部分测试失败，请检查 ModManagerBridge 配置")
            return False

def main():
    """主函数"""
    tester = ModManagerTester()
    
    if len(sys.argv) > 1:
        # 命令行模式
        command = sys.argv[1]
        if command == "list":
            tester.test_get_mod_list()
        elif command == "info" and len(sys.argv) > 2:
            tester.test_get_mod_info(sys.argv[2])
        elif command == "enable" and len(sys.argv) > 2:
            tester.test_enable_mod(sys.argv[2])
        elif command == "disable" and len(sys.argv) > 2:
            tester.test_disable_mod(sys.argv[2])
        elif command == "test":
            tester.run_comprehensive_test()
        else:
            print("用法:")
            print("  python comprehensive_test.py list        - 获取 mod 列表")
            print("  python comprehensive_test.py info <mod>   - 获取 mod 信息")
            print("  python comprehensive_test.py enable <mod> - 启用 mod")
            print("  python comprehensive_test.py disable <mod>- 禁用 mod")
            print("  python comprehensive_test.py test         - 运行综合测试")
    else:
        # 交互模式
        print("选择测试模式:")
        print("1. 综合测试")
        print("2. 获取 mod 列表")
        print("3. 获取 mod 信息")
        print("4. 启用 mod")
        print("5. 禁用 mod")
        
        try:
            choice = input("请输入选择 (1-5): ").strip()
            
            if choice == "1":
                tester.run_comprehensive_test()
            elif choice == "2":
                tester.test_get_mod_list()
            elif choice == "3":
                mod_name = input("请输入 mod 名称: ").strip()
                tester.test_get_mod_info(mod_name)
            elif choice == "4":
                mod_name = input("请输入要启用的 mod 名称: ").strip()
                tester.test_enable_mod(mod_name)
            elif choice == "5":
                mod_name = input("请输入要禁用的 mod 名称: ").strip()
                tester.test_disable_mod(mod_name)
            else:
                print("无效选择")
                
        except KeyboardInterrupt:
            print("\n测试已取消")
        except Exception as e:
            print(f"错误: {e}")

if __name__ == "__main__":
    main()
