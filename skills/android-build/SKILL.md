---
name: android-build
description: Android 项目自动构建发布，当用户需要打包、构建、导出 Android APK 时使用，支持自动版本号递增、签名打包、多路径导出。
---

# Android Build Skill

自动化完成 Android 项目全流程构建发布，支持版本号自动管理、智能导出、U盘自动处理等特性。

## 工作流程

1. **环境检查**：确认在 Android 项目根目录，存在 build.gradle(.kts) 文件
2. **版本更新**：自动递增 versionCode，按格式生成 versionName
3. **构建执行**：运行 gradle 构建命令生成签名包
4. **智能导出**：按优先级导出到U盘或指定目录，自动重命名
5. **完成反馈**：仅输出最终导出路径，减少冗余信息

## 配置文件（可选）
项目根目录下创建 `.androidbuild.yml` 自定义配置：
```yaml
version:
  code_auto_increment: true    # 是否自动递增versionCode
  name_format: "YYYY.MM.DD.HHmm"  # versionName格式
build:
  type: release                # 构建类型：release/debug
  flavor: ""                   # 多flavor支持
export:
  path_priority: ["/Volumes/boox", "~/Downloads"]  # 导出路径优先级
  apk_name_format: "{app_name}-{version_name}.apk" # 导出文件名格式
  auto_eject_usb: true         # 导出完成后是否自动弹出U盘
```

## 默认行为（无配置文件时）
- versionCode 自动递增
- versionName 格式：`YYYY.MM.DD.HHmm`
- 构建 release 版本
- 导出优先级：U盘 > ~/Downloads
- 自动弹出U盘
- 文件名格式：`app-{version_name}.apk`

## 约束规则
- 静默执行：用户发出打包指令后无需确认，直接执行
- 失败回滚：构建失败时自动恢复原来的版本号
- 仅输出结果：执行完成后仅报告导出路径，无冗余日志

## 示例

**输入**："帮我打个release包"
**输出**：
```
已导出到下载目录: ~/Downloads/app-2026.03.14.1530.apk
已导出到U盘: /Volumes/boox/app-2026.03.14.1530.apk1
U盘已安全弹出
```
