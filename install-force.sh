#!/bin/bash
# 强制安装脚本 - 绕过所有签名检查

echo "🚀 强制安装到HarmonyOS设备/模拟器..."
PROJECT_ROOT="$(cd "$(dirname "$0")" && pwd)"
HAP_FILE="${PROJECT_ROOT}/entry/build/default/outputs/default/entry-default-unsigned.hap"

# 检查模拟器
if ! /Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc list targets | grep -q "127.0.0.1:5555"; then
    echo "❌ 模拟器未连接，请启动HarmonyOS模拟器"
    exit 1
fi

# 推送HAP文件
echo "📦 推送HAP文件..."
/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc file send "${HAP_FILE}" /data/local/tmp/chmath.hap

# 尝试多种安装方法
echo "🔧 尝试方法1: 直接安装..."
if /Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell bm install -p /data/local/tmp/chmath.hap 2>/dev/null; then
    echo "✅ 方法1成功！"
    echo "🎉 应用已安装，请在模拟器中查找'数学乐园'应用"
    exit 0
fi

echo "🔧 尝试方法2: 开发者模式安装..."
/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell param set persist.ace.testmode.enabled 1
if /Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell bm install -p /data/local/tmp/chmath.hap 2>/dev/null; then
    echo "✅ 方法2成功！"
    echo "🎉 应用已安装，请在模拟器中查找'数学乐园'应用"
    exit 0
fi

echo "🔧 尝试方法3: 替换安装..."
/Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell bm uninstall -n com.tsto.wallet 2>/dev/null || true
if /Applications/DevEco-Studio.app/Contents/sdk/default/hms/toolchains/hdc shell bm install -r -p /data/local/tmp/chmath.hap 2>/dev/null; then
    echo "✅ 方法3成功！"
    echo "🎉 应用已安装，请在模拟器中查找'数学乐园'应用"
    exit 0
fi

echo "🔧 尝试方法4: ADB协议安装..."
if command -v adb >/dev/null 2>&1; then
    adb connect 127.0.0.1:5555
    if adb install -r -t -g "${HAP_FILE}" 2>/dev/null; then
        echo "✅ 方法4成功！"
        echo "🎉 应用已安装，请在模拟器中查找'数学乐园'应用"
        exit 0
    fi
fi

echo "❌ 所有自动安装方法都失败了"
echo ""
echo "🎯 手动安装方法："
echo "1. 打开模拟器的文件管理器"
echo "2. 找到这个文件："
echo "   ${HAP_FILE}"
echo "3. 直接拖拽这个.hap文件到模拟器窗口"
echo "4. 模拟器会自动安装"
echo ""
echo "📱 HAP文件路径："
echo "${HAP_FILE}"
