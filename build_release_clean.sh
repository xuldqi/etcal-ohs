#!/bin/bash

# 进入项目目录
cd "$(dirname "$0")"

# 设置正确的 SDK 路径并覆盖任何系统环境变量
export -n DEVECO_SDK_HOME 2>/dev/null
export -n HARMONYOS_SDK_HOME 2>/dev/null
export -n OHOS_SDK_HOME 2>/dev/null

# 设置新的 SDK 路径  
export SDK_DIR="/Applications/DevEco-Studio.app/Contents/sdk/default"

# 清理并打包
echo "🧹 清理环境..."
./hvigorw --stop-daemon

echo "📦 开始打包 Release 版本 v1.0.2..."
echo "SDK目录: $SDK_DIR"

# 使用 env 清除环境变量后重新设置
env -i \
  HOME="$HOME" \
  USER="$USER" \
  PATH="/Applications/DevEco-Studio.app/Contents/tools/node/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  LANG="en_US.UTF-8" \
  bash -c 'cd /Users/macmima1234/Documents/harmony/chmath/OHS && ./hvigorw --mode project -p product=default -p buildMode=release assembleApp --no-daemon'

if [ $? -eq 0 ]; then
    echo "✅ 打包成功！"
    echo "📦 输出文件："
    find . -name "*-signed.app" -o -name "*-signed.hap" 2>/dev/null | grep -v node_modules
else
    echo "❌ 打包失败"
    exit 1
fi







