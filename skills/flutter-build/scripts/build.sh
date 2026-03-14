#!/bin/bash
set -e

# Flutter 自动构建脚本
# 支持 Android/iOS 多平台、多 flavor、自动版本管理、真机安装

# 配置默认值
CONFIG_FILE=".flutterbuild.yml"
VERSION_AUTO_INCREMENT=true
VERSION_NAME_FORMAT="v{major}.{minor}.{patch}+{build}"
BUILD_PLATFORM="android"
BUILD_TYPE="release"
BUILD_SPLIT_PER_ABI=true
BUILD_FLAVOR=""
INSTALL_AUTO_INSTALL=true
INSTALL_ONLY_REAL_DEVICE=true
EXPORT_PATH="~/Downloads"
EXPORT_NAME_FORMAT="{app_name}-{version}-{arch}.apk"

# 检查是否在 Flutter 项目根目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误：未找到 pubspec.yaml 文件，请在 Flutter 项目根目录执行"
    exit 1
fi

# 读取配置文件
if [ -f "$CONFIG_FILE" ]; then
    VERSION_AUTO_INCREMENT=$(yq e '.version.auto_increment' $CONFIG_FILE)
    VERSION_NAME_FORMAT=$(yq e '.version.name_format' $CONFIG_FILE)
    BUILD_PLATFORM=$(yq e '.build.platform' $CONFIG_FILE)
    BUILD_TYPE=$(yq e '.build.type' $CONFIG_FILE)
    BUILD_SPLIT_PER_ABI=$(yq e '.build.split_per_abi' $CONFIG_FILE)
    BUILD_FLAVOR=$(yq e '.build.flavor' $CONFIG_FILE)
    INSTALL_AUTO_INSTALL=$(yq e '.install.auto_install' $CONFIG_FILE)
    INSTALL_ONLY_REAL_DEVICE=$(yq e '.install.only_real_device' $CONFIG_FILE)
    EXPORT_PATH=$(yq e '.export.path' $CONFIG_FILE)
    EXPORT_NAME_FORMAT=$(yq e '.export.name_format' $CONFIG_FILE)
fi

# 读取当前版本号
CURRENT_VERSION=$(grep 'version: ' pubspec.yaml | awk '{print $2}')
IFS='+' read -r VERSION_NAME BUILD_NUMBER <<< "$CURRENT_VERSION"
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"

echo "🔍 当前版本：$VERSION_NAME+$BUILD_NUMBER"

# 自动递增版本号
if [ "$VERSION_AUTO_INCREMENT" = "true" ]; then
    NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
    NEW_VERSION="$VERSION_NAME+$NEW_BUILD_NUMBER"
    
    # 更新 pubspec.yaml
    sed -i '' "s/version: $CURRENT_VERSION/version: $NEW_VERSION/" pubspec.yaml
    echo "✅ 版本号已更新：$CURRENT_VERSION → $NEW_VERSION"
else
    NEW_VERSION=$CURRENT_VERSION
    NEW_BUILD_NUMBER=$BUILD_NUMBER
fi

# 清理缓存
echo "🧹 清理构建缓存..."
flutter clean > /dev/null 2>&1

# 同步依赖
echo "📦 同步依赖包..."
flutter pub get > /dev/null 2>&1

# 构建参数
BUILD_ARGS=""
if [ "$BUILD_SPLIT_PER_ABI" = "true" ] && [ "$BUILD_PLATFORM" = "android" ]; then
    BUILD_ARGS="$BUILD_ARGS --split-per-abi"
fi

if [ -n "$BUILD_FLAVOR" ]; then
    BUILD_ARGS="$BUILD_ARGS --flavor $BUILD_FLAVOR"
fi

# 构建 Android
if [ "$BUILD_PLATFORM" = "android" ] || [ "$BUILD_PLATFORM" = "all" ]; then
    echo "🏗️  构建 Android $BUILD_TYPE 包..."
    flutter build apk --$BUILD_TYPE $BUILD_ARGS > /dev/null 2>&1 || {
        echo "❌ Android 构建失败"
        exit 1
    }
    echo "✅ Android 构建完成"
fi

# 构建 iOS
if [ "$BUILD_PLATFORM" = "ios" ] || [ "$BUILD_PLATFORM" = "all" ]; then
    echo "🏗️  构建 iOS $BUILD_TYPE 包..."
    flutter build ios --$BUILD_TYPE --no-codesign $BUILD_ARGS > /dev/null 2>&1 || {
        echo "❌ iOS 构建失败"
        exit 1
    }
    echo "✅ iOS 构建完成"
fi

# 自动安装到设备
if [ "$INSTALL_AUTO_INSTALL" = "true" ] && [ "$BUILD_PLATFORM" = "android" ] || [ "$BUILD_PLATFORM" = "all" ]; then
    echo "📱 检测连接设备..."
    DEVICES=$(adb devices | grep -v "List of devices attached" | grep -v "emulator" | awk '{print $1}' | head -n 1)
    
    if [ -n "$DEVICES" ]; then
        echo "🔌 找到真机设备：$DEVICES"
        APK_PATH="build/app/outputs/flutter-apk/app-arm64-v8a-$BUILD_TYPE.apk"
        
        if [ -f "$APK_PATH" ]; then
            adb -s $DEVICES install -r $APK_PATH > /dev/null 2>&1
            echo "✅ 已安装到设备：$DEVICES"
        else
            echo "⚠️  未找到安装包，跳过安装"
        fi
    else
        echo "ℹ️  未检测到真机设备，跳过安装"
    fi
fi

# 导出文件
EXPORT_PATH_EXPANDED=$(eval echo $EXPORT_PATH)
mkdir -p $EXPORT_PATH_EXPANDED

if [ "$BUILD_PLATFORM" = "android" ] || [ "$BUILD_PLATFORM" = "all" ]; then
    ARCHS=("arm64-v8a" "armeabi-v7a" "x86_64")
    for ARCH in "${ARCHS[@]}"; do
        APK_SRC="build/app/outputs/flutter-apk/app-$ARCH-$BUILD_TYPE.apk"
        if [ -f "$APK_SRC" ]; then
            APK_DEST=$(echo $EXPORT_NAME_FORMAT | sed "s/{app_name}/app/g; s/{version}/$NEW_VERSION/g; s/{arch}/$ARCH/g")
            cp $APK_SRC "$EXPORT_PATH_EXPANDED/$APK_DEST"
            echo "📦 已导出：$EXPORT_PATH_EXPANDED/$APK_DEST"
        fi
    done
fi

echo "🎉 构建流程完成！"
