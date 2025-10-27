#!/bin/bash

echo "🚀 开始构建 HarmonyOS APP v1.1.2"

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

echo "🔧 同步项目配置..."
./hvigorw --sync -p product=default --analyze=false --no-parallel --no-incremental --no-daemon

echo "🏗️ 构建APP..."
./hvigorw assembleApp -p product=default --analyze=false --no-parallel --no-incremental --no-daemon

echo "✅ 构建完成！"
echo "📱 APP文件位置: build/outputs/default/OHS-default-signed.app"



