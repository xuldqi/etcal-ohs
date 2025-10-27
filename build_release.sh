#!/bin/bash

# 清除旧的环境变量
unset DEVECO_SDK_HOME
unset HARMONYOS_SDK_HOME
unset OHOS_SDK_HOME

# 停止 daemon
./hvigorw --stop-daemon

# 打包 Release 版本
./hvigorw --mode module -p module=entry@default -p product=default -p buildMode=release assembleHap







