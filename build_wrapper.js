#!/usr/bin/env node
delete process.env.DEVECO_SDK_HOME;
delete process.env.HARMONYOS_SDK_HOME;
delete process.env.OHOS_SDK_HOME;
delete process.env.hwsdk_dir;
process.env.sdk_dir = '/Applications/DevEco-Studio.app/Contents/sdk/default';
require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/bin/hvigor.js');
