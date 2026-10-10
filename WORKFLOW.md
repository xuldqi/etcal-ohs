# Harmony 独立工程说明

这个目录是独立的 HarmonyOS 工程目录，只负责鸿蒙打包和安装。

## 目录边界

- React 源码目录（只改前端逻辑）  
  `/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath/react-src`
- Harmony 工程目录（只做鸿蒙打包）  
  `/Users/macmima1234/Documents/harmony/chmath/chmath_new/chamath_harmony`

## 日常流程

1. 在 React 目录开发并测试。
2. 在 Harmony 目录执行：
   `./sync-react-assets.sh`
3. 用 DevEco 打开 `chamath_harmony` 目录，执行 `assembleHap`。

## 说明

- `sync-react-assets.sh` 会自动：
  - 执行 React `npm run build`
  - 将 `dist` 同步到 `entry/src/main/resources/rawfile/react-app`
  - 处理 `index.html` 资源路径，保证鸿蒙 WebView 可加载
