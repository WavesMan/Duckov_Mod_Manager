#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Duckov Mod Manager 自动化构建和打包脚本
全流程：flet构建Windows应用 + Inno Setup打包
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path
import argparse
import time
from datetime import datetime

class FletPackager:
    def __init__(self, project_dir=".", build_dir="build/windows", iss_file="setup.iss"):
        """
        初始化打包器
        
        Args:
            project_dir: 项目目录
            build_dir: 构建输出目录
            iss_file: Inno Setup脚本文件
        """
        self.project_dir = Path(project_dir)
        self.build_dir = Path(build_dir)
        self.iss_file = Path(iss_file)
        # self.output_dir = Path("dist")
        
        # 验证路径
        self._validate_paths()
    
    def _validate_paths(self):
        """验证路径是否存在"""
        if not self.project_dir.exists():
            raise FileNotFoundError(f"项目目录不存在: {self.project_dir}")
        
        if not self.iss_file.exists():
            raise FileNotFoundError(f"Inno Setup脚本不存在: {self.iss_file}")
        
        print("✓ 路径验证通过")
    
    def build_windows_app(self, verbose=True):
        """
        构建Windows应用
        
        Args:
            verbose: 是否显示详细输出
            
        Returns:
            success: 是否成功
        """
        print("=" * 50)
        print("开始构建Windows应用...")
        print("=" * 50)
        
        # 确保构建目录存在
        self.build_dir.mkdir(parents=True, exist_ok=True)
        
        # 执行flet构建命令
        cmd = ["flet", "build", "windows", "-v"] if verbose else ["flet", "build", "windows"]
        
        try:
            print(f"执行命令: {' '.join(cmd)}")
            print(f"工作目录: {self.project_dir}")
            
            # 设置环境变量避免Unicode编码问题
            env = os.environ.copy()
            env['PYTHONIOENCODING'] = 'utf-8'
            
            # 使用subprocess.run简化输出处理
            result = subprocess.run(
                cmd,
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                encoding='utf-8',
                env=env
            )
            
            # 显示输出
            if verbose and result.stdout:
                print("构建输出:")
                print(result.stdout)
            
            if result.returncode == 0:
                print("✓ Windows应用构建成功")
                # 检查构建结果
                if self._check_build_result():
                    return True
                else:
                    print("⚠ 构建成功但未找到预期的构建文件")
                    return False
            else:
                print("✗ Windows应用构建失败")
                if result.stderr:
                    print("错误信息:")
                    print(result.stderr)
                return False
                
        except FileNotFoundError:
            print("✗ 找不到flet命令，请确保flet已安装")
            print("安装命令: pip install flet")
            return False
        except PermissionError:
            print("✗ 权限不足，无法执行构建操作")
            return False
        except Exception as e:
            print(f"✗ 构建过程中发生错误: {e}")
            return False
    
    def _check_build_result(self):
        """
        检查构建结果
        
        Returns:
            success: 是否找到有效的构建文件
        """
        # 检查构建目录中是否有Windows应用文件
        build_files = list(self.build_dir.rglob("*.exe"))
        if build_files:
            print(f"✓ 找到构建文件: {[f.name for f in build_files]}")
            return True
        
        # 检查默认的flet构建输出位置
        default_build_dirs = [
            self.project_dir / "build" / "windows",
            self.project_dir / "build",
            self.project_dir / "dist"
        ]
        
        for build_dir in default_build_dirs:
            if build_dir.exists():
                exe_files = list(build_dir.rglob("*.exe"))
                if exe_files:
                    print(f"✓ 在 {build_dir} 中找到构建文件: {[f.name for f in exe_files]}")
                    return True
        
        print("⚠ 未找到Windows可执行文件")
        return False
    
    def find_inno_setup_compiler(self):
        """
        查找Inno Setup编译器
        
        Returns:
            iscc_path: ISCC.exe路径
        """
        # 直接尝试使用iscc命令（用户已确认可用）
        try:
            # 简单测试iscc命令是否可用
            result = subprocess.run(
                ["iscc", "--help"], 
                capture_output=True, 
                text=True,
                encoding='utf-8'
            )
            if result.returncode == 0 or "Inno Setup" in result.stdout:
                print("✓ Inno Setup编译器在PATH中可用")
                return "iscc"
        except FileNotFoundError:
            print("iscc命令不在PATH中，尝试查找安装路径")
        except Exception as e:
            print(f"测试iscc命令失败: {e}")
        
        # 如果直接测试失败，尝试常见路径
        possible_paths = [
            r"C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
            r"C:\Program Files\Inno Setup 6\ISCC.exe",
            r"C:\Program Files (x86)\Inno Setup 5\ISCC.exe",
            r"C:\Program Files\Inno Setup 5\ISCC.exe"
        ]
        
        for path in possible_paths:
            if Path(path).exists():
                print(f"✓ 找到Inno Setup编译器: {path}")
                return path
        
        print("✗ 未找到Inno Setup编译器")
        print("请确保已安装Inno Setup，或使用 --iscc-path 参数手动指定路径")
        return None

    def compile_installer(self, iscc_path=None):
        """
        编译安装程序

        Args:
            iscc_path: ISCC.exe路径，如果为None则自动查找

        Returns:
            success: 是否成功
        """
        print("=" * 50)
        print("开始编译安装程序...")
        print("=" * 50)

        # 查找或使用指定的ISCC路径
        if iscc_path is None:
            iscc_path = self.find_inno_setup_compiler()
            if iscc_path is None:
                return False

        # 验证用户提供的ISCC路径
        if iscc_path and not Path(iscc_path).exists():
            print(f"✗ 指定的ISCC路径不存在: {iscc_path}")
            return False

        # 确保输出目录存在
        # self.output_dir.mkdir(exist_ok=True)

        # 确保所有路径都是字符串类型
        iscc_path_str = str(iscc_path) if not isinstance(iscc_path, str) else iscc_path
        iss_file_str = str(self.iss_file)
        work_dir_str = str(self.project_dir)

        # 执行ISCC编译命令
        cmd = [iscc_path_str, iss_file_str]

        try:
            print(f"执行命令: {' '.join(cmd)}")
            print(f"工作目录: {work_dir_str}")
            print(f"ISS文件: {iss_file_str}")

            result = subprocess.run(
                cmd,
                cwd=work_dir_str,
                capture_output=True,
                text=True,
                encoding='utf-8'
            )

            if result.returncode == 0:
                print("✓ 安装程序编译成功")
                if result.stdout:
                    # print("编译输出:")
                    # print(result.stdout)
                    return 0

                # 改进的文件查找逻辑 - 检查所有可能的输出位置
                possible_output_locations = [
                    self.project_dir,  # 项目目录
                    self.project_dir.parent,  # 父目录
                    # self.output_dir,  # dist目录
                    self.project_dir / "Releases",  # Releases目录（你的实际输出位置）
                    self.project_dir / "Output",  # 可能的其他输出目录
                ]

                found_setup = False
                for location in possible_output_locations:
                    if location.exists():
                        setup_files = list(location.glob("DuckovModManager-Setup-*.exe"))
                        if setup_files:
                            print(f"✓ 在 {location} 中找到安装程序: {[f.name for f in setup_files]}")

                            # # 如果不在dist目录，移动到dist目录
                            # if location != self.output_dir:
                            #     for setup_file in setup_files:
                            #         target_path = self.output_dir / setup_file.name
                            #         try:
                            #             shutil.move(str(setup_file), str(target_path))
                            #             print(f"✓ 安装程序已移动到: {target_path}")
                            #         except Exception as move_error:
                            #             print(f"⚠ 移动安装程序失败: {move_error}")
                            #             # 即使移动失败，也认为找到了文件
                            #             target_path = setup_file
                            #
                            # found_setup = True
                            break

                if found_setup:
                    return True
                # else:
                #     print("⚠ 未找到生成的安装程序文件")
                #     print("已检查以下位置:")
                #     for i, location in enumerate(possible_output_locations, 1):
                #         print(f"  {i}. {location}")
                #     return False
            else:
                print("✗ 安装程序编译失败")
                print(f"错误信息: {result.stderr}")
                return False

        except FileNotFoundError:
            print("✗ 找不到ISCC编译器，请确保Inno Setup已正确安装")
            return False
        except PermissionError:
            print("✗ 权限不足，无法执行编译操作")
            return False
        except Exception as e:
            print(f"✗ 编译过程中发生错误: {e}")
            return False

    def cleanup_build(self):
        """清理构建文件"""
        print("清理构建文件...")
        
        # 清理构建目录
        if self.build_dir.exists():
            try:
                shutil.rmtree(self.build_dir)
                print(f"✓ 已清理构建目录: {self.build_dir}")
            except Exception as e:
                print(f"⚠ 清理构建目录失败: {e}")
        
        # 清理临时文件
        temp_dirs_to_clean = [
            self.project_dir / "build",
            self.project_dir / "__pycache__",
            self.project_dir / "src" / "__pycache__"
        ]
        
        for temp_dir in temp_dirs_to_clean:
            if temp_dir.exists():
                try:
                    shutil.rmtree(temp_dir)
                    print(f"✓ 已清理临时目录: {temp_dir}")
                except Exception as e:
                    print(f"⚠ 清理临时目录失败: {e}")
        
        # 清理临时安装程序文件（保留输出目录中的最终文件）
        temp_setup_files = list(self.project_dir.glob("DuckovModManager-Setup-*.exe"))
        for setup_file in temp_setup_files:
            try:
                setup_file.unlink()
                print(f"✓ 已清理临时安装程序: {setup_file.name}")
            except Exception as e:
                print(f"⚠ 清理临时安装程序失败: {e}")
        
        print("✓ 清理完成")
    
    def run_full_pipeline(self, iscc_path=None, cleanup=True):
        """
        执行完整构建和打包流程
        
        Args:
            iscc_path: ISCC.exe路径
            cleanup: 是否清理构建文件
            
        Returns:
            success: 是否成功
        """
        print("开始执行完整构建打包流程...")
        start_time = time.time()
        
        try:
            # 1. 构建Windows应用
            if not self.build_windows_app():
                return False
            
            # 2. 编译安装程序
            if not self.compile_installer(iscc_path):
                return False
            
            # 3. 清理（可选）
            if cleanup:
                self.cleanup_build()
            
            end_time = time.time()
            duration = end_time - start_time
            print("=" * 50)
            print(f"✓ 完整流程执行成功！耗时: {duration:.2f}秒")
            print("=" * 50)
            return True
            
        except Exception as e:
            print(f"✗ 流程执行失败: {e}")
            return False

def main():
    """主函数"""
    parser = argparse.ArgumentParser(description="Duckov Mod Manager 自动化构建打包工具")
    parser.add_argument("--iscc-path", help="手动指定ISCC.exe路径")
    parser.add_argument("--no-cleanup", action="store_true", help="不清理构建文件")
    parser.add_argument("--build-only", action="store_true", help="仅构建应用，不打包")
    parser.add_argument("--package-only", action="store_true", help="仅打包，不重新构建")
    
    args = parser.parse_args()
    
    # 创建打包器实例
    packager = FletPackager()
    
    try:
        if args.build_only:
            # 仅构建应用
            success = packager.build_windows_app()
        elif args.package_only:
            # 仅打包
            success = packager.compile_installer(args.iscc_path)
        else:
            # 完整流程
            success = packager.run_full_pipeline(
                iscc_path=args.iscc_path,
                cleanup=not args.no_cleanup
            )
        
        sys.exit(0 if success else 1)
        
    except Exception as e:
        print(f"错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
