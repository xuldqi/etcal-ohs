#!/bin/bash
# Local build script for HarmonyOS App Pack (.app)

set -e

# Navigate to project directory
cd "$(dirname "$0")"

echo "🧹 Cleaning and setting up environment..."
unset hwsdk_dir
unset sdk_dir

# Export correct SDK variables pointing to DevEco Studio SDK
export DEVECO_SDK_HOME="/Users/macmima1234/Library/Huawei/Sdk"
export OHOS_SDK_HOME="/Users/macmima1234/Library/Huawei/Sdk"
export HARMONYOS_SDK_HOME="/Users/macmima1234/Library/Huawei/Sdk"

echo "🔨 Building HarmonyOS APP Pack using local hvigorw..."

# Clean and build
./hvigorw clean
./hvigorw assembleApp -p buildMode=release --analyze=normal --parallel --incremental

echo "✅ App Pack Build completed successfully!"
