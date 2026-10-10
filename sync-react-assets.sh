#!/bin/bash
set -euo pipefail

# Usage:
#   ./sync-react-assets.sh
#   ./sync-react-assets.sh /absolute/path/to/react-src
#   REACT_SRC_DIR=/abs/path/to/react-src ./sync-react-assets.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEFAULT_REACT_SRC="/Users/macmima1234/Documents/harmony/chmath/react/react-src"
REACT_SRC_DIR="${1:-${REACT_SRC_DIR:-$DEFAULT_REACT_SRC}}"
TARGET_DIR="$SCRIPT_DIR/entry/src/main/resources/rawfile/react-app"

if [ ! -d "$REACT_SRC_DIR" ]; then
  echo "❌ React 源码目录不存在: $REACT_SRC_DIR"
  exit 1
fi

echo "📦 React 源码: $REACT_SRC_DIR"
echo "📁 同步目标: $TARGET_DIR"

cd "$REACT_SRC_DIR"
npm run build

mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_DIR"/*
cp -R "$REACT_SRC_DIR/dist/." "$TARGET_DIR/"

if [ -d "$REACT_SRC_DIR/public/audio" ]; then
  rm -rf "$TARGET_DIR/audio"
  cp -R "$REACT_SRC_DIR/public/audio" "$TARGET_DIR/"
fi

INDEX_FILE="$TARGET_DIR/index.html"
if [ -f "$INDEX_FILE" ]; then
  sed -i.tmp 's|src="/|src="|g' "$INDEX_FILE"
  sed -i.tmp 's|href="/|href="|g' "$INDEX_FILE"
  sed -i.tmp 's|="assets/|="./assets/|g' "$INDEX_FILE"
  rm -f "$INDEX_FILE.tmp"
fi

echo "✅ React 构建产物已同步到 Harmony 工程"
