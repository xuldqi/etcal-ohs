#!/bin/bash

# 清理之前的构建
echo "清理之前的构建..."
rm -rf .hvigor/
rm -rf build/
rm -rf entry/build/

# 创建临时配置文件
echo "创建临时配置文件..."
cat > temp_hvigorfile.js << 'EOF'
const { appTasks } = require('@ohos/hvigor-ohos-plugin');

// 直接初始化configProps
appTasks.configProps = {
  productConfig: {
    default: {
      compileSdkVersion: "4.0.0(10)",
      compatibleSdkVersion: "4.0.0(10)",
      runtimeOS: "HarmonyOS"
    }
  }
};

module.exports = {
  system: appTasks,
  plugins: []
};
EOF

# 备份原始文件
echo "备份原始配置文件..."
mv hvigorfile.js hvigorfile.js.bak
mv temp_hvigorfile.js hvigorfile.js

# 执行构建
echo "开始构建应用..."
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode project assembleApp --analyze=false --no-parallel --no-incremental --no-daemon

# 恢复原始文件
echo "恢复原始配置文件..."
mv hvigorfile.js.bak hvigorfile.js

echo "构建脚本执行完成"