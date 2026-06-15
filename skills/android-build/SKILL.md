---
name: android-build
description: Android 项目自动构建发布，当用户需要打包、构建、导出 Android APK 时使用，支持自动版本号递增、签名打包、多路径导出。
---

# Android Build Skill

自动化完成 Android 项目全流程构建发布，支持版本号自动管理、智能导出、跨平台兼容。

## 工作流程

1. **环境检查**：确认在 Android 项目根目录，存在 build.gradle(.kts) 文件
2. **配置加载**：按优先级加载配置（项目级 > 用户级 > 内置默认值）
3. **版本更新**：根据策略自动更新 versionCode / versionName
4. **构建执行**：运行 gradle 构建命令生成签名包
5. **智能导出**：按优先级导出到指定目录，自动重命名
6. **完成反馈**：仅输出最终导出路径，减少冗余信息

## 配置体系

### 配置文件位置（优先级从高到低）

| 级别 | 路径 | 说明 |
|------|------|------|
| 项目级 | `<project>/.androidbuild.yml` | 项目特定配置 |
| 用户级 | `~/.config/android-build/config.yml` | 用户全局配置 |
| 内置 | 无文件时使用默认值 | 见下方默认行为 |

### 完整配置结构

```yaml
version:
  strategy: time              # time | semver | build_number
  code_auto_increment: true   # 是否自动递增 versionCode
  name_format: "YYYY.MM.DD.HHmm"  # time 策略的格式
  semver_format: "{major}.{minor}.{patch}"  # semver 策略的格式

build:
  type: release               # release | debug
  flavor: ""                  # 多 flavor 支持
  gradle_task: ""             # 自定义 gradle 任务（留空则自动拼接）

export:
  paths:                      # 导出路径优先级，按顺序查找
    - "${ANDROID_USB_PATH}"   # 环境变量（可选）
    - "~/Downloads"           # 跨平台兜底
  filename_pattern: "{app_name}-{version}.apk"
  apk_source: "app/build/outputs/apk/{build_type}/app-{build_type}.apk"

behavior:
  silent: true                # 是否跳过确认直接执行
  rollback_on_failure: true   # 构建失败时是否回滚版本号
  log_level: minimal          # minimal | verbose
```

### 版本策略说明

| 策略 | versionName 输出示例 | 说明 |
|------|---------------------|------|
| `time` | `2026.03.14.1530` | 基于当前时间戳，格式由 `name_format` 控制 |
| `semver` | `1.2.4` | 从 gradle 读取 major/minor，patch 自增 |
| `build_number` | `1234` | 使用 gradle 的 versionCode 作为版本名 |

### 平台适配

导出路径支持环境变量，不同平台通过 shell 环境或 `.bashrc`/`.zshrc` 预设：

```bash
# macOS: U盘挂载点
export ANDROID_USB_PATH="/Volumes/boox"

# Linux: U盘挂载点
export ANDROID_USB_PATH="/mnt/usb"

# Windows (Git Bash): U盘盘符
export ANDROID_USB_PATH="/d/"
```

### U盘弹出命令（可选）

如需自动弹出 U盘，在项目级或用户级配置中添加：

```yaml
export:
  eject_cmd: "diskutil eject {path}"  # macOS
  # eject_cmd: "udisksctl power-off -b {device}"  # Linux
  # eject_cmd: ""  # 留空则不弹出
```

## 默认行为（无配置文件时）

- versionCode 自动递增
- versionName 策略：`time`，格式 `YYYY.MM.DD.HHmm`
- 构建 release 版本
- 导出路径：`~/Downloads`
- 文件名格式：`app-{version}.apk`
- 构建失败时回滚版本号

## 约束规则

- 静默执行：用户发出打包指令后无需确认，直接执行
- 失败回滚：构建失败时自动恢复原来的版本号（可配置关闭）
- 仅输出结果：执行完成后仅报告导出路径，无冗余日志

## 示例

**输入**："帮我打个release包"
**输出**：
```
版本号已更新: 42 -> 43, 2026.03.14.1500 -> 2026.03.14.1530
构建完成: assembleRelease
已导出: ~/Downloads/app-2026.03.14.1530.apk
```
