# 儿童语音计算器 - HarmonyOS版本

一个专为儿童设计的语音数学学习应用，基于HarmonyOS开发。

## 功能特性

### 🎯 核心功能
- **语音计算器**：支持语音输入数学表达式
- **数学练习**：多种练习模式（加法、减法、乘法、除法、比大小）
- **数学大冒险**：游戏化学习体验
- **视觉学习**：直观的数学概念展示
- **学习报告**：详细的学习进度统计
- **语音方案**：自定义语音录制和管理

### 🛡️ 隐私保护
- **本地存储**：所有学习数据仅保存在设备本地
- **无网络依赖**：无需联网即可使用全部功能
- **隐私透明**：详细的隐私政策说明
- **家长控制**：支持一键清除学习数据

### 🎨 界面设计
- **儿童友好**：色彩丰富、界面简洁
- **语音反馈**：支持多种语音播报
- **动画效果**：流畅的交互体验
- **响应式布局**：适配不同屏幕尺寸

## 技术架构

### 开发框架
- **HarmonyOS ArkUI**：声明式UI框架
- **ArkTS**：TypeScript的超集
- **Stage模型**：现代应用架构

### 核心模块
- **语音识别**：集成HarmonyOS语音API
- **音频播放**：支持OGG格式音频文件
- **数据存储**：本地数据持久化
- **状态管理**：响应式状态管理

## 项目结构

```
entry/
├── src/main/ets/
│   ├── pages/           # 页面组件
│   ├── components/      # 通用组件
│   ├── managers/        # 业务管理器
│   └── entryability/    # 应用入口
├── src/main/resources/  # 资源文件
│   ├── base/
│   │   ├── element/     # 字符串资源
│   │   ├── media/       # 媒体资源
│   │   └── profile/     # 配置文件
└── build-profile.json5  # 构建配置
```

## 开发环境

### 系统要求
- **HarmonyOS SDK**：API 11+（默认使用 API 20 构建，也可安装 API 15 与 API 11 以构建向下兼容版本）
- **DevEco Studio**：最新版本
- **Node.js**：16.0+
- **hvigor**：构建工具

### 安装步骤
1. 克隆项目到本地
2. 使用DevEco Studio打开项目
3. 配置HarmonyOS SDK
4. 连接设备或启动模拟器
5. 运行项目

## 构建说明

```bash
# 清理项目
./hvigorw clean

# 构建应用
./hvigorw assembleApp

# 安装到设备
hdc install -r entry-default-unsigned.hap

# 针对 HarmonyOS 5 的向下兼容构建
./hvigorw --mode module -p module=entry@default -p product=hos5Compat -p buildMode=release assembleHap

# 针对 HarmonyOS 4 的向下兼容构建
./hvigorw --mode module -p module=entry@default -p product=hos4Compat -p buildMode=release assembleHap
```

## 贡献指南

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建 Pull Request

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 联系方式

- **项目维护者**：xuldqi
- **邮箱**：novcat@colletools.com
- **GitHub**：[https://github.com/xuldqi/etcal-ohs](https://github.com/xuldqi/etcal-ohs)

## 致谢

感谢所有为这个项目做出贡献的开发者和测试用户。

---

**注意**：本项目专为儿童设计，严格遵循隐私保护原则，所有数据仅保存在设备本地，不会上传到任何服务器。
