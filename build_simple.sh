#!/bin/bash

echo "🚀 开始构建 HarmonyOS APP v1.2.3"

# 进入项目目录
cd "$(dirname "$0")"

echo "📦 清理项目..."
rm -rf build/
rm -rf entry/build/
rm -rf .hvigor/

echo "🔧 检查项目结构..."
if [ ! -d "entry" ]; then
    echo "❌ 未找到 entry 目录"
    exit 1
fi

echo "🏗️ 构建APP..."
echo "⚠️  请使用 DevEco Studio 打开项目并构建"
echo "📁 项目路径: $(pwd)"
echo "📱 构建完成后，APP文件位置: build/outputs/default/OHS-default-signed.app"

echo "✅ 构建脚本执行完成！"