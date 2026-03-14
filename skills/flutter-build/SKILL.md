---
name: flutter-build
description: Flutter 项目自动构建发布，当用户需要打包 Flutter 应用、构建 APK/IPA、自动安装到设备时使用，支持版本号管理、多架构打包、真机自动安装。
---

# Flutter Build Skill

自动化完成 Flutter 项目全流程构建发布，支持自动版本管理、多平台构建、真机自动安装、智能导出等特性。

## 工作流程

1. **环境检查**：确认在 Flutter 项目根目录，存在 pubspec.yaml 文件
2. **清理缓存**：执行 flutter clean 清理构建缓存
3. **依赖同步**：执行 flutter pub get 同步依赖包
4. **版本更新**：自动递增版本号（可选）
5. **构建执行**：按配置构建对应平台的安装包
6. **智能安装**：检测真机设备，优先安装到真机
7. **导出备份**：未检测到真机时导出到 Downloads 目录
8. **结果反馈**：仅输出最终构建结果和路径

## 配置文件（可选）
项目根目录下创建 `.flutterbuild.yml` 自定义配置：
```yaml
version:
  auto_increment: true          # 是否自动递增版本号
  name_format: "v{major}.{minor}.{patch}+{build}"  # 版本号格式
build:
  platform: android             # 构建平台：android/ios/all
  type: release                 # 构建类型：release/debug/profile
  split_per_abi: true           # 是否按架构拆分 APK
  flavor: ""                    # 多 flavor 支持
install:
  auto_install: true            # 是否自动安装到设备
  only_real_device: true        # 禁止安装到模拟器
export:
  path: "~/Downloads"           # 导出路径
  name_format: "{app_name}-{version}-{arch}.apk" # 导出文件名格式
```

## 默认行为（无配置文件时）
- 自动递增版本号
- 构建 Android release 版本，按架构拆分
- 优先安装到真机，禁止安装到模拟器
- 未检测到设备时导出到 Downloads 目录
- 文件名格式：`app-{version}-{arch}-release.apk`

## 约束规则
- 静默执行：用户发出打包指令后无需确认，直接执行
- 真机优先：始终优先安装到真实设备，禁止自动安装到模拟器
- 失败终止：任何步骤失败立即终止，输出错误信息
- 精简输出：仅输出关键步骤和最终结果，无冗余日志

## 示例

**输入**："帮我打个 release 包并安装到手机"
**输出**：
```
✅ 构建完成：app-arm64-v8a-release.apk
📱 已安装到设备：f0bc5f56
📦 已备份到：~/Downloads/app-v1.0.0+1-arm64-v8a-release.apk
```

**输入**："打iOS debug包"
**输出**：
```
✅ iOS 构建完成：Runner.app
📦 已导出到：~/Downloads/Runner-v1.0.0+1-debug.ipa
```
