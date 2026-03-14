#!/bin/bash
set -e

# Android 自动构建脚本
# 支持 Groovy 和 KTS 格式的 build.gradle 文件

# 配置默认值
CONFIG_FILE=".androidbuild.yml"
VERSION_CODE_AUTO_INCREMENT=true
VERSION_NAME_FORMAT="%Y.%m.%d.%H%M"
BUILD_TYPE="release"
BUILD_FLAVOR=""
EXPORT_PRIORITY=("/Volumes/boox" "~/Downloads")
APK_NAME_FORMAT="app-{version_name}.apk"
AUTO_EJECT_USB=true

# 检查是否在Android项目根目录
if [ ! -f "app/build.gradle" ] && [ ! -f "app/build.gradle.kts" ]; then
    echo "错误：未找到 app/build.gradle 或 app/build.gradle.kts 文件，请在 Android 项目根目录执行"
    exit 1
fi

# 检测gradle文件格式
if [ -f "app/build.gradle.kts" ]; then
    GRADLE_FILE="app/build.gradle.kts"
else
    GRADLE_FILE="app/build.gradle"
fi

# 读取配置文件
if [ -f "$CONFIG_FILE" ]; then
    # 简单解析yml配置，提取值
    VERSION_CODE_AUTO_INCREMENT=$(yq e '.version.code_auto_increment' $CONFIG_FILE)
    VERSION_NAME_FORMAT=$(yq e '.version.name_format' $CONFIG_FILE)
    BUILD_TYPE=$(yq e '.build.type' $CONFIG_FILE)
    BUILD_FLAVOR=$(yq e '.build.flavor' $CONFIG_FILE)
    APK_NAME_FORMAT=$(yq e '.export.apk_name_format' $CONFIG_FILE)
    AUTO_EJECT_USB=$(yq e '.export.auto_eject_usb' $CONFIG_FILE)
    
    # 解析导出路径优先级
    IFS=$'\n' read -d '' -r -a EXPORT_PRIORITY < <(yq e '.export.path_priority[]' $CONFIG_FILE)
fi

# 备份原始版本号
ORIGINAL_VERSION_CODE=$(grep "versionCode =" $GRADLE_FILE | awk '{print $3}')
ORIGINAL_VERSION_NAME=$(grep "versionName =" $GRADLE_FILE | awk -F '"' '{print $2}')

# 自动递增versionCode
if [ "$VERSION_CODE_AUTO_INCREMENT" = "true" ]; then
    NEW_VERSION_CODE=$((ORIGINAL_VERSION_CODE + 1))
    NEW_VERSION_NAME=$(date +"$VERSION_NAME_FORMAT")
    
    # 更新版本号
    sed -i '' "s/versionCode = $ORIGINAL_VERSION_CODE/versionCode = $NEW_VERSION_CODE/" $GRADLE_FILE
    sed -i '' "s/versionName = \".*\"/versionName = \"$NEW_VERSION_NAME\"/" $GRADLE_FILE
    
    echo "版本号已更新: $ORIGINAL_VERSION_CODE -> $NEW_VERSION_CODE, $ORIGINAL_VERSION_NAME -> $NEW_VERSION_NAME"
else
    NEW_VERSION_CODE=$ORIGINAL_VERSION_CODE
    NEW_VERSION_NAME=$ORIGINAL_VERSION_NAME
fi

# 构建命令
if [ -n "$BUILD_FLAVOR" ]; then
    ASSEMBLE_TASK="assemble${BUILD_FLAVOR^}${BUILD_TYPE^}"
else
    ASSEMBLE_TASK="assemble${BUILD_TYPE^}"
fi

echo "开始构建: ./gradlew $ASSEMBLE_TASK"
./gradlew $ASSEMBLE_TASK > /dev/null 2>&1 || {
    # 构建失败，回滚版本号
    sed -i '' "s/versionCode = $NEW_VERSION_CODE/versionCode = $ORIGINAL_VERSION_CODE/" $GRADLE_FILE
    sed -i '' "s/versionName = \"$NEW_VERSION_NAME\"/versionName = \"$ORIGINAL_VERSION_NAME\"/" $GRADLE_FILE
    echo "构建失败，已回滚版本号"
    exit 1
}

# 生成文件名
APK_FILE=$(echo $APK_NAME_FORMAT | sed "s/{version_name}/$NEW_VERSION_NAME/g")
APK_FILE_APK1="${APK_FILE}1"

# 导出apk到下载目录
cp "app/build/outputs/apk/release/app-release.apk" ~/Downloads/$APK_FILE
echo "已导出到下载目录: ~/Downloads/$APK_FILE"

# 导出apk1到优先级最高的路径
EXPORT_SUCCESS=false
for path in "${EXPORT_PRIORITY[@]}"; do
    expanded_path=$(eval echo $path)
    if [ -d "$expanded_path" ]; then
        cp "app/build/outputs/apk/release/app-release.apk" "$expanded_path/$APK_FILE_APK1"
        echo "已导出到目标路径: $expanded_path/$APK_FILE_APK1"
        
        # 自动弹出U盘
        if [ "$AUTO_EJECT_USB" = "true" ] && [[ "$path" == /Volumes/* ]]; then
            diskutil eject "$path" > /dev/null 2>&1 && echo "U盘已安全弹出"
        fi
        
        EXPORT_SUCCESS=true
        break
    fi
done

# 没有找到优先级路径，导出到下载目录
if [ "$EXPORT_SUCCESS" = "false" ]; then
    cp "app/build/outputs/apk/release/app-release.apk" ~/Downloads/$APK_FILE_APK1
    echo "已导出到下载目录: ~/Downloads/$APK_FILE_APK1"
fi

echo "构建完成"
