#!/bin/bash

# 设置环境变量，指定一个用户有写入权限的目录作为临时SDK目录
export TEMP_SDK_DIR="$HOME/temp_harmony_sdk"
mkdir -p $TEMP_SDK_DIR

# 修改local.properties文件，使用临时目录
sed -i.bak "s|hwsdk.dir=.*|hwsdk.dir=$TEMP_SDK_DIR|g" local.properties

# 运行构建命令
npm run build

# 恢复原始local.properties文件
mv local.properties.bak local.properties

echo "构建过程完成"