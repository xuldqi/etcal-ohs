#!/bin/bash

# 进入项目目录
cd "$(dirname "$0")"

# 完全清理环境变量
unset DEVECO_SDK_HOME
unset HARMONYOS_SDK_HOME
unset OHOS_SDK_HOME
unset hwsdk_dir
unset sdk_dir

# 停止所有 daemon
./hvigorw --stop-daemon 2>/dev/null

echo "🧹 开始清理..."
./hvigorw clean --no-daemon

echo "📦 开始打包 Release 版本..."
./hvigorw --mode project -p product=default -p buildMode=release assembleApp --no-daemon

if [ $? -eq 0 ]; then
    echo "✅ 打包成功！"
    echo "📍 输出路径: build/default/outputs/default/"
    ls -lh build/default/outputs/default/*.app 2>/dev/null || ls -lh entry/build/default/outputs/default/*.hap 2>/dev/null
else
    echo "❌ 打包失败"
    exit 1
fi







