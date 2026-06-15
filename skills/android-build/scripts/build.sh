#!/bin/bash
set -e

# Android 自动构建脚本
# 支持 Groovy 和 KTS 格式的 build.gradle 文件
# 支持跨平台：macOS / Linux / Windows (Git Bash)

# ============================================================
# 配置加载（优先级：项目级 > 用户级 > 内置默认值）
# ============================================================

PROJECT_CONFIG=".androidbuild.yml"
USER_CONFIG="$HOME/.config/android-build/config.yml"

# 内置默认值
VERSION_STRATEGY="time"
VERSION_CODE_AUTO_INCREMENT=true
VERSION_NAME_FORMAT="%Y.%m.%d.%H%M"
SEMVER_FORMAT="{major}.{minor}.{patch}"
BUILD_TYPE="release"
BUILD_FLAVOR=""
GRADLE_TASK=""
EXPORT_PATHS=()
APK_NAME_FORMAT="app-{version_name}.apk"
APK_SOURCE="app/build/outputs/apk/{build_type}/app-{build_type}.apk"
EJECT_CMD=""
BEHAVIOR_SILENT=true
BEHAVIOR_ROLLBACK=true
LOG_LEVEL="minimal"

# 加载配置文件
load_config() {
    local config_file="$1"
    [ ! -f "$config_file" ] && return

    if command -v yq &> /dev/null; then
        VERSION_STRATEGY=$(yq e '.version.strategy // "'"$VERSION_STRATEGY"'"' "$config_file")
        VERSION_CODE_AUTO_INCREMENT=$(yq e '.version.code_auto_increment // true' "$config_file")
        VERSION_NAME_FORMAT=$(yq e '.version.name_format // "'"$VERSION_NAME_FORMAT"'"' "$config_file" | sed 's/YYYY/%Y/g; s/MM/%m/g; DD/%d/g; HH/%H/g; mm/%M/g')
        SEMVER_FORMAT=$(yq e '.version.semver_format // "'"$SEMVER_FORMAT"'"' "$config_file")
        BUILD_TYPE=$(yq e '.build.type // "'"$BUILD_TYPE"'"' "$config_file")
        BUILD_FLAVOR=$(yq e '.build.flavor // ""' "$config_file")
        GRADLE_TASK=$(yq e '.build.gradle_task // ""' "$config_file")
        APK_NAME_FORMAT=$(yq e '.export.filename_pattern // "'"$APK_NAME_FORMAT"'"' "$config_file")
        APK_SOURCE=$(yq e '.export.apk_source // "'"$APK_SOURCE"'"' "$config_file")
        EJECT_CMD=$(yq e '.export.eject_cmd // ""' "$config_file")
        BEHAVIOR_SILENT=$(yq e '.behavior.silent // true' "$config_file")
        BEHAVIOR_ROLLBACK=$(yq e '.behavior.rollback_on_failure // true' "$config_file")
        LOG_LEVEL=$(yq e '.behavior.log_level // "minimal"' "$config_file")

        # 解析导出路径
        local paths
        IFS=$'\n' read -d '' -r -a paths < <(yq e '.export.paths[] // ""' "$config_file" 2>/dev/null || true)
        [ ${#paths[@]} -gt 0 ] && EXPORT_PATHS=("${paths[@]}")
    else
        echo "警告：未安装 yq，使用内置默认配置" >&2
    fi
}

# 按优先级加载配置
load_config "$USER_CONFIG"
load_config "$PROJECT_CONFIG"

# 如果导出路径为空，使用默认值
[ ${#EXPORT_PATHS[@]} -eq 0 ] && EXPORT_PATHS=("$HOME/Downloads")

# ============================================================
# 环境变量替换
# ============================================================
expand_path() {
    local path="$1"
    # 展开环境变量 ${VAR}
    path=$(eval echo "$path" 2>/dev/null || echo "$path")
    # 展开 ~
    path="${path/#\~/$HOME}"
    echo "$path"
}

# ============================================================
# 环境检查
# ============================================================
if [ ! -f "app/build.gradle" ] && [ ! -f "app/build.gradle.kts" ]; then
    echo "错误：未找到 app/build.gradle 或 app/build.gradle.kts 文件，请在 Android 项目根目录执行"
    exit 1
fi

if [ -f "app/build.gradle.kts" ]; then
    GRADLE_FILE="app/build.gradle.kts"
else
    GRADLE_FILE="app/build.gradle"
fi

# ============================================================
# 版本更新
# ============================================================
ORIGINAL_VERSION_CODE=$(grep "versionCode =" "$GRADLE_FILE" | awk '{print $3}')
ORIGINAL_VERSION_NAME=$(grep "versionName =" "$GRADLE_FILE" | awk -F '"' '{print $2}')

if [ "$VERSION_CODE_AUTO_INCREMENT" = "true" ]; then
    NEW_VERSION_CODE=$((ORIGINAL_VERSION_CODE + 1))

    case "$VERSION_STRATEGY" in
        time)
            NEW_VERSION_NAME=$(date +"$VERSION_NAME_FORMAT")
            ;;
        semver)
            # 从 gradle 读取当前版本，自增 patch
            IFS='.' read -r major minor patch <<< "$ORIGINAL_VERSION_NAME"
            patch=$((patch + 1))
            NEW_VERSION_NAME="${major}.${minor}.${patch}"
            ;;
        build_number)
            NEW_VERSION_NAME="$NEW_VERSION_CODE"
            ;;
        *)
            NEW_VERSION_NAME=$(date +"$VERSION_NAME_FORMAT")
            ;;
    esac

    # 更新 gradle 文件
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/versionCode = $ORIGINAL_VERSION_CODE/versionCode = $NEW_VERSION_CODE/" "$GRADLE_FILE"
        sed -i '' "s/versionName = \".*\"/versionName = \"$NEW_VERSION_NAME\"/" "$GRADLE_FILE"
    else
        sed -i "s/versionCode = $ORIGINAL_VERSION_CODE/versionCode = $NEW_VERSION_CODE/" "$GRADLE_FILE"
        sed -i "s/versionName = \".*\"/versionName = \"$NEW_VERSION_NAME\"/" "$GRADLE_FILE"
    fi

    [ "$LOG_LEVEL" = "verbose" ] && echo "版本号已更新: $ORIGINAL_VERSION_CODE -> $NEW_VERSION_CODE, $ORIGINAL_VERSION_NAME -> $NEW_VERSION_NAME"
else
    NEW_VERSION_CODE=$ORIGINAL_VERSION_CODE
    NEW_VERSION_NAME=$ORIGINAL_VERSION_NAME
fi

# ============================================================
# 构建执行
# ============================================================
if [ -n "$GRADLE_TASK" ]; then
    ASSEMBLE_TASK="$GRADLE_TASK"
elif [ -n "$BUILD_FLAVOR" ]; then
    ASSEMBLE_TASK="assemble${BUILD_FLAVOR^}${BUILD_TYPE^}"
else
    ASSEMBLE_TASK="assemble${BUILD_TYPE^}"
fi

[ "$LOG_LEVEL" = "verbose" ] && echo "开始构建: ./gradlew $ASSEMBLE_TASK"

BUILD_OUTPUT=$(./gradlew "$ASSEMBLE_TASK" 2>&1) || {
    # 构建失败，回滚版本号
    if [ "$BEHAVIOR_ROLLBACK" = "true" ]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/versionCode = $NEW_VERSION_CODE/versionCode = $ORIGINAL_VERSION_CODE/" "$GRADLE_FILE"
            sed -i '' "s/versionName = \"$NEW_VERSION_NAME\"/versionName = \"$ORIGINAL_VERSION_NAME\"/" "$GRADLE_FILE"
        else
            sed -i "s/versionCode = $NEW_VERSION_CODE/versionCode = $ORIGINAL_VERSION_CODE/" "$GRADLE_FILE"
            sed -i "s/versionName = \"$NEW_VERSION_NAME\"/versionName = \"$ORIGINAL_VERSION_NAME\"/" "$GRADLE_FILE"
        fi
        echo "构建失败，已回滚版本号"
    else
        echo "构建失败"
    fi
    exit 1
}

# ============================================================
# 导出 APK
# ============================================================

# 构建 APK 源路径
APK_SOURCE_PATH=$(echo "$APK_SOURCE" | sed "s/{build_type}/$BUILD_TYPE/g")

# 生成导出文件名
APK_FILE=$(echo "$APK_NAME_FORMAT" | sed "s/{version}/$NEW_VERSION_NAME/g; s/{app_name}/app/g")

EXPORT_SUCCESS=false
for raw_path in "${EXPORT_PATHS[@]}"; do
    expanded_path=$(expand_path "$raw_path")
    [ -z "$expanded_path" ] && continue
    [ ! -d "$expanded_path" ] && continue

    cp "$APK_SOURCE_PATH" "$expanded_path/$APK_FILE"
    echo "已导出: $expanded_path/$APK_FILE"

    # 可选：弹出 U盘
    if [ -n "$EJECT_CMD" ] && [[ "$raw_path" == /Volumes/* || "$raw_path" == /mnt/* ]]; then
        eject_path="$expanded_path"
        eval "${EJECT_CMD//\{path\}/$eject_path}" > /dev/null 2>&1 && echo "U盘已安全弹出"
    fi

    EXPORT_SUCCESS=true
    break
done

if [ "$EXPORT_SUCCESS" = "false" ]; then
    # 兜底导出到 ~/Downloads
    fallback="$HOME/Downloads"
    cp "$APK_SOURCE_PATH" "$fallback/$APK_FILE"
    echo "已导出: $fallback/$APK_FILE"
fi
