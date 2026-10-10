#!/bin/bash
# 一键构建和部署脚本

echo "🔨 开始构建应用..."

# 1. 构建并同步 React 资源
echo "📦 构建并同步 React 资源..."
./sync-react-assets.sh

# 2. 构建HarmonyOS HAP
echo "🏗️ 构建HarmonyOS HAP..."
./hvigorw clean assembleHap

# 3. 检查模拟器连接
echo "📱 检查模拟器连接..."
targets=$(/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc list targets)
if [ -z "$targets" ]; then
    echo "❌ 没有检测到HarmonyOS设备，请启动模拟器"
    echo "💡 在DevEco Studio中: Tools → Device Manager → 启动模拟器"
    exit 1
fi

echo "✅ 检测到设备: $targets"

# 4. 部署应用
echo "🚀 部署应用到模拟器..."
/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc file send entry/build/default/outputs/default/entry-default-unsigned.hap /data/local/tmp/app.hap

# 5. 卸载旧版本（如果存在）
echo "🧹 卸载旧版本..."
/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell bm uninstall -n com.tsto.wallet 2>/dev/null || true

# 6. 安装新版本
echo "📲 安装应用..."
if /Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell bm install -p /data/local/tmp/app.hap; then
    echo "🎉 应用安装成功！"
    echo "📱 请在模拟器中查找'数学乐园'应用并启动"
else
    echo "❌ 安装失败，可能需要开发者签名"
    echo "💡 请在DevEco Studio中使用Run按钮来自动处理签名"
fi

echo "✨ 部署完成！"
