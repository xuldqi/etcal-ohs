#!/bin/bash

echo "🚀 开始构建 HarmonyOS APP v1.2.3"

# 清理环境变量
unset DEVECO_SDK_HOME
unset HARMONYOS_SDK_HOME
unset OHOS_SDK_HOME

# 设置正确的SDK路径
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export hwsdk_dir="/Applications/DevEco-Studio.app/Contents/sdk/default"
export sdk_dir="/Applications/DevEco-Studio.app/Contents/sdk/default"
export nodejs_dir="/Applications/DevEco-Studio.app/Contents/tools/node"
export HVIGOR_INST_PATH="/Applications/DevEco-Studio.app/Contents/tools/hvigor"

# 进入项目目录
cd "$(dirname "$0")"

echo "📦 清理项目..."
rm -rf build/
rm -rf entry/build/
rm -rf .hvigor/

# 检查Node.js是否存在
if ! command -v node &> /dev/null
then
    echo "❌ 未找到 Node.js，正在尝试使用系统Node.js"
    # 尝试使用系统Node.js
else
    echo "✅ 找到 Node.js"
fi

# 检查是否可以直接使用hvigor
if [ -f "node_modules/@ohos/hvigor/bin/hvigor.js" ]; then
    echo "🔧 使用本地hvigor进行项目同步..."
    node build_wrapper.js --sync -p product=default --analyze=false --no-parallel --no-incremental --no-daemon
else
    echo "🔧 尝试直接构建..."
fi

echo "🏗️ 构建APP..."
if [ -f "node_modules/@ohos/hvigor/bin/hvigor.js" ]; then
    node build_wrapper.js assembleApp -p product=default --analyze=false --no-parallel --no-incremental --no-daemon
else
    echo "⚠️  未找到hvigor，尝试使用默认构建命令"
    # 如果hvigorw不存在，尝试直接使用node运行
    node build_wrapper.js assembleHap -p product=default
fi

echo "✅ 构建完成！"
echo "📱 APP文件位置: build/outputs/default/OHS-default-signed.app"