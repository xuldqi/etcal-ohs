#!/bin/bash

# 进入项目目录
cd "$(dirname "$0")"

# 清理所有缓存
echo "🧹 清理所有缓存..."
rm -rf .hvigor entry/build entry/.preview 2>/dev/null

# 使用全新的环境变量启动打包
echo "📦 开始打包 v1.0.2..."
echo "SDK 自动检测模式"

# 使用 env 创建干净的环境
exec env -i \
  HOME="$HOME" \
  USER="$USER" \
  PATH="/Applications/DevEco-Studio.app/Contents/tools/node/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" \
  LANG="en_US.UTF-8" \
  bash -c 'cd /Users/macmima1234/Documents/harmony/chmath/OHS && ./hvigorw --mode module -p module=entry@default -p product=default -p buildMode=release assembleHap --no-daemon 2>&1'







