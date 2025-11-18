#!/usr/bin/env node

// 删除所有无效的 SDK 环境变量
delete process.env.DEVECO_SDK_HOME;
delete process.env.HARMONYOS_SDK_HOME;
delete process.env.OHOS_SDK_HOME;
delete process.env.hwsdk_dir;

// 设置正确的路径
process.env.sdk_dir = '/Applications/DevEco-Studio.app/Contents/sdk/default';

// 加载 hvigor
require('./node_modules/@ohos/hvigor/bin/hvigor.js');













