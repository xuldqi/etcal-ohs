#!/bin/bash
# Local build script for HarmonyOS project

set -e

# Navigate to project directory
cd "$(dirname "$0")"

echo "🧹 Cleaning and setting up environment..."
# Unset any conflicting SDK variables from user environment
unset hwsdk_dir
unset sdk_dir

# Export correct SDK variables pointing to DevEco Studio SDK
export DEVECO_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export OHOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"
export HARMONYOS_SDK_HOME="/Applications/DevEco-Studio.app/Contents/sdk/default"

echo "🔨 Building HarmonyOS project using local hvigorw..."

# Clean and build
./hvigorw clean
./hvigorw assembleHap --analyze=normal --parallel --incremental

echo "✅ Build completed successfully!"
echo "📦 HAP file location: entry/build/default/outputs/default/"

# List the generated HAP files
ls -la entry/build/default/outputs/default/*.hap 2>/dev/null || echo "No HAP files found"