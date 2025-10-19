import { router } from '@kit.ArkUI';
import { display } from '@kit.ArkUI';
import { VoiceCalculatorPage } from './VoiceCalculatorPage';
import { PracticePage } from './PracticePage';
import { AdventurePage } from './AdventurePage';
import { VisualLearningPage } from './VisualLearningPage';
import { LearningReportPage } from './LearningReportPage';
import { VoiceSettingsPage } from './VoiceSettingsPage';
import { AppSettingsPage } from './AppSettingsPage';
import { StorageManager } from '../managers/StorageManager';
import common from '@ohos.app.ability.common';

// 按钮状态接口
interface ButtonState {
  isHovered: boolean;
  isPressed: boolean;
  scale: number;
  translateY: number;
  emojiRotate: number;
  emojiScale: number;
}

// 单个按钮状态
interface SingleButtonState {
  scale: number;
  offsetY: number;
  shadowBlur: number;
  isPressed: boolean;
}

// 学习统计接口
interface LearningStats {
  totalProblems: number
  correctAnswers: number
  score: number
  totalCalculations?: number
  correctCount?: number
  bestStreak?: number
  currentStreak?: number
  practiceProblems?: number
}

@Entry
@Component
struct Index {
  @State isAudioEnabled: boolean = true
  @State gridCols: number = 2
  @State screenWidth: number = 0
  @State screenHeight: number = 0
  @State currentPage: string = 'home'
  @State currentVoice: string = '小美老师'
  @State showPrivacyDialog: boolean = false
  @State hasAgreedPrivacy: boolean = false
  @State showPolicyPage: string = '' // 'privacy' | 'agreement' | ''
  @State learningStats: LearningStats = {
    totalProblems: 0,
    correctAnswers: 0,
    score: 0,
    totalCalculations: 0,
    correctCount: 0,
    bestStreak: 0,
    currentStreak: 0,
    practiceProblems: 0
  }
  private abilityContext: common.UIAbilityContext | null = null
  // 按钮状态数组，为每个按钮维护独立状态
  @State buttonStates: SingleButtonState[] = [
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 20, isPressed: false }
  ]

  aboutToAppear() {
    try {
      const defaultDisplay = display.getDefaultDisplaySync()
      this.screenWidth = defaultDisplay.width
      this.screenHeight = defaultDisplay.height
    } catch (error) {
      const message: string = error instanceof Error
        ? `${error.name}: ${error.message}`
        : JSON.stringify(error)
      console.error(`获取屏幕信息失败: ${message}`)
      this.screenWidth = 0
      this.screenHeight = 0
    }
    // 固定为2列布局，不管什么设备
    this.gridCols = 2

    if (!this.abilityContext) {
      try {
        this.abilityContext = getContext(this) as common.UIAbilityContext
      } catch (error) {
        console.error('获取页面上下文失败:', error)
      }
    }
    if (this.abilityContext) {
      void StorageManager.getInstance().init(this.abilityContext)
    }
    
    // 检查隐私说明同意状态
    this.checkPrivacyAgreement()
  }

  // 检查隐私说明同意状态
  private async checkPrivacyAgreement() {
    try {
      const storageManager = StorageManager.getInstance()
      const hasAgreed = await storageManager.getPrivacyAgreement()
      this.hasAgreedPrivacy = hasAgreed
      
      if (!hasAgreed) {
        // 延迟显示弹窗，确保界面已加载
        setTimeout(() => {
          this.showPrivacyDialog = true
        }, 500)
      }
    } catch (error) {
      console.error('检查隐私说明同意状态失败:', error)
      // 如果检查失败，显示弹窗
      setTimeout(() => {
        this.showPrivacyDialog = true
      }, 500)
    }
  }

  // 同意隐私说明
  private async agreePrivacy() {
    try {
      const storageManager = StorageManager.getInstance()
      await storageManager.setPrivacyAgreement(true)
      this.hasAgreedPrivacy = true
      this.showPrivacyDialog = false
      console.log('用户已同意隐私说明')
    } catch (error) {
      console.error('保存隐私说明同意状态失败:', error)
      this.showPrivacyDialog = false
    }
  }

  // 拒绝隐私说明
  private rejectPrivacy() {
    console.log('用户拒绝了隐私说明')
    try {
      // 关闭隐私弹窗
      this.showPrivacyDialog = false
      
      // 在HarmonyOS中退出应用
      // 使用router.back()退出到桌面
      router.back()
      console.log('用户拒绝隐私说明，应用已退出')
    } catch (error) {
      console.error('退出应用失败:', error)
      // 如果无法退出，重新显示隐私弹窗
      this.showPrivacyDialog = true
    }
  }

  // 显示隐私说明页面
  private showPrivacyPolicy() {
    this.showPolicyPage = 'privacy'
  }

  // 显示用户协议页面
  private showUserAgreement() {
    this.showPolicyPage = 'agreement'
  }

  // 关闭政策页面
  private closePolicyPage() {
    this.showPolicyPage = ''
  }

  // 按钮按下效果
  onButtonPress(index: number): void {
    this.buttonStates[index] = {
      scale: 0.92,
      offsetY: 4,
      shadowBlur: 10,
      isPressed: true
    }
  }

  // 按钮释放效果
  onButtonRelease(index: number): void {
    this.buttonStates[index] = {
      scale: 1.05,
      offsetY: -2,
      shadowBlur: 25,
      isPressed: false
    }
    
    // 延迟恢复到正常状态
    setTimeout(() => {
      this.buttonStates[index] = {
        scale: 1.0,
        offsetY: 0,
        shadowBlur: 20,
        isPressed: false
      }
    }, 150)
  }

  // 页面导航方法
  navigateToPage(page: string): void {
    this.currentPage = page
  }

  // 设置当前语音
  setCurrentVoice(voice: string): void {
    this.currentVoice = voice
  }

  // 更新学习统计
  updateLearningStats(stats: LearningStats): void {
    this.learningStats = {
      totalProblems: stats.totalProblems || this.learningStats.totalProblems,
      correctAnswers: stats.correctAnswers || this.learningStats.correctAnswers,
      score: stats.score || this.learningStats.score,
      totalCalculations: stats.totalCalculations || this.learningStats.totalCalculations,
      correctCount: stats.correctCount || this.learningStats.correctCount,
      bestStreak: stats.bestStreak || this.learningStats.bestStreak,
      currentStreak: stats.currentStreak || this.learningStats.currentStreak,
      practiceProblems: stats.practiceProblems || this.learningStats.practiceProblems
    }
  }

  build() {
    Stack() {
      // 根据当前页面显示不同内容
      if (this.currentPage === 'home') {
        this.HomePage()
      } else if (this.currentPage === 'calculator') {
        VoiceCalculatorPage({ 
          onNavigate: (page: string) => this.navigateToPage(page),
          appState: this.learningStats,
          setAppState: (state: object) => this.updateLearningStats(state as LearningStats)
        })
      } else if (this.currentPage === 'practice') {
        PracticePage({ 
          onNavigate: (page: string) => this.navigateToPage(page),
          learningStats: this.learningStats,
          updateStats: (stats: LearningStats) => this.updateLearningStats(stats)
        })
      } else if (this.currentPage === 'adventure') {
        AdventurePage({ 
          onNavigate: (page: string) => this.navigateToPage(page)
        })
      } else if (this.currentPage === 'visual') {
        VisualLearningPage({ 
          onNavigate: (page: string) => this.navigateToPage(page)
        })
      } else if (this.currentPage === 'report') {
        LearningReportPage({ 
          onNavigate: (page: string) => this.navigateToPage(page)
        })
      } else if (this.currentPage === 'voice') {
        VoiceSettingsPage({ 
          onNavigate: (page: string) => this.navigateToPage(page)
        })
      } else if (this.currentPage === 'settings') {
        AppSettingsPage({ 
          onNavigate: (page: string) => this.navigateToPage(page)
        })
      }

      // 隐私说明同意弹窗 - 最顶层
      if (this.showPrivacyDialog) {
        this.PrivacyDialog()
      }

      // 隐私说明/用户协议页面 - 最顶层
      if (this.showPolicyPage !== '') {
        this.PolicyPage()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 主页面内容
  @Builder
  HomePage(): void {
    Stack() {
      // 带圆点装饰的背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#f8f9fa')
      
      // 可爱的圆点装饰
      this.DotPattern()

      // 主内容区域
      Column({ space: 20 }) {
        // 标题区域
        Column({ space: 8 }) {
          Text('儿童语音计算器')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2c3e50')
        }
        .margin({ top: 40, bottom: 30 })

        // 功能网格
        Grid() {
          // 语音计算器
          GridItem() {
            this.CartoonButton(
              0,
              '语音计算器',
              '🔢',
              '#fb923c',
              () => { 
                console.info('点击了语音计算器');
                this.navigateToPage('calculator');
              }
            )
          }
          
          // 数学练习
          GridItem() {
            this.CartoonButton(
              1,
              '数学练习',
              '📚',
              '#34d399',
              () => { 
                console.info('点击了数学练习');
                this.navigateToPage('practice');
              }
            )
          }
          
          // 数学大冒险
          GridItem() {
            this.CartoonButton(
              2,
              '数学大冒险',
              '🎮',
              '#a855f7',
              () => { 
                console.info('点击了数学大冒险');
                this.navigateToPage('adventure');
              }
            )
          }
          
          // 学数学
          GridItem() {
            this.CartoonButton(
              3,
              '学数学',
              '🐱',
              '#f43f5e',
              () => { 
                console.info('点击了学数学');
                this.navigateToPage('visual');
              }
            )
          }
          
          // 学习报告
          GridItem() {
            this.CartoonButton(
              4,
              '学习报告',
              '📊',
              '#22d3ee',
              () => { 
                console.info('点击了学习报告');
                this.navigateToPage('report');
              }
            )
          }
          
          // 语音选择
          GridItem() {
            this.CartoonButton(
              5,
              '语音选择',
              '🎤',
              '#ec4899',
              () => { 
                console.info('点击了语音选择');
                this.navigateToPage('voice');
              }
            )
          }
          
          // 设置
          GridItem() {
            this.CartoonButton(
              6,
              '设置',
              '⚙️',
              '#64748b',
              () => { 
                console.info('点击了设置');
                this.navigateToPage('settings');
              }
            )
          }
        }
        .columnsTemplate('1fr 1fr')
        .rowsTemplate('1fr 1fr 1fr 1fr')
        .columnsGap(16)
        .rowsGap(16)
        .width('100%')
        .height(500)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    }
    .width('100%')
    .height('100%')
  }
  
  // 可爱圆点装饰
  @Builder
  DotPattern(): void {
    // 创建简单的圆点装饰
    Stack() {
      // 第一排圆点
      Row() {
        Circle({ width: 8, height: 8 }).fill('#FFA8B8').opacity(0.4)
        Circle({ width: 8, height: 8 }).fill('#A8E6CF').opacity(0.4).margin({left: this.screenWidth/6})
        Circle({ width: 8, height: 8 }).fill('#C8A8E9').opacity(0.4).margin({left: this.screenWidth/6})
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .position({ y: 120 })
      
      // 第二排圆点
      Row() {
        Circle({ width: 8, height: 8 }).fill('#87CEEB').opacity(0.4)
        Circle({ width: 8, height: 8 }).fill('#FFD93D').opacity(0.4).margin({left: this.screenWidth/6})
        Circle({ width: 8, height: 8 }).fill('#FF9AA2').opacity(0.4).margin({left: this.screenWidth/6})
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .position({ y: 200 })
      
      // 第三排圆点
      Row() {
        Circle({ width: 8, height: 8 }).fill('#FFA8B8').opacity(0.4)
        Circle({ width: 8, height: 8 }).fill('#A8E6CF').opacity(0.4).margin({left: this.screenWidth/6})
        Circle({ width: 8, height: 8 }).fill('#C8A8E9').opacity(0.4).margin({left: this.screenWidth/6})
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
      .position({ y: 380 })
    }
    .width('100%')
    .height('100%')
  }

  // 获取圆点颜色
  getDotColor(index: number): string {
    const colors = ['#ff9a8b', '#a8e6cf', '#d299c2', '#89f7fe', '#fdbb2d', '#f093fb'];
    return colors[index % colors.length];
  }

  // 彩色渐变卡片按钮组件（优化版本）
  @Builder
  CartoonButton(index: number, title: string, emoji: string, color: string, onTap: () => void): void {
    Button() {
      Column({ space: 8 }) {
        Text(emoji)
          .fontSize(36)
          .scale({
            x: this.buttonStates[index].isPressed ? 0.9 : 1.1,
            y: this.buttonStates[index].isPressed ? 0.9 : 1.1
          })
          .animation({
            duration: 200,
            curve: Curve.EaseOut
          })

        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: this.getCardGradientColors(index)
    })
    .borderRadius(20)
    .shadow({
      radius: this.buttonStates[index].shadowBlur,
      color: this.buttonStates[index].isPressed ? '#00000020' : '#00000040',
      offsetX: 0,
      offsetY: this.buttonStates[index].isPressed ? 2 : 8
    })
    .scale({ 
      x: this.buttonStates[index].scale, 
      y: this.buttonStates[index].scale 
    })
    .translate({ 
      y: this.buttonStates[index].offsetY 
    })
    .animation({ 
      duration: 200, 
      curve: Curve.EaseOut 
    })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.onButtonPress(index)
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.onButtonRelease(index)
        onTap()
      }
    })
    // 添加悬浮效果
    .onHover((isHover: boolean) => {
      if (isHover && !this.buttonStates[index].isPressed) {
        this.buttonStates[index] = {
          scale: 1.02,
          offsetY: -1,
          shadowBlur: 25,
          isPressed: this.buttonStates[index].isPressed
        }
      } else if (!isHover && !this.buttonStates[index].isPressed) {
        this.buttonStates[index] = {
          scale: 1.0,
          offsetY: 0,
          shadowBlur: 20,
          isPressed: this.buttonStates[index].isPressed
        }
      }
    })
  }

  // 获取卡片渐变色
  getCardGradientColors(index: number): [ResourceColor, number][] {
    const gradients = [
      [['#FFA8B8', 0.0], ['#FF8FB1', 1.0]], // 温柔粉色
      [['#A8E6CF', 0.0], ['#7FDBDA', 1.0]], // 清新薄荷绿
      [['#C8A8E9', 0.0], ['#B595E6', 1.0]], // 优雅紫色
      [['#87CEEB', 0.0], ['#70B7E6', 1.0]], // 天空蓝
      [['#FFD93D', 0.0], ['#FFC107', 1.0]], // 阳光黄
      [['#FF9AA2', 0.0], ['#FF8A80', 1.0]], // 珊瑚粉
      [['#B5B5B5', 0.0], ['#9E9E9E', 1.0]]  // 优雅灰
    ];
    return gradients[index % gradients.length] as [ResourceColor, number][];
  }

  // 隐私说明同意弹窗
  @Builder
  PrivacyDialog(): void {
    Stack({ alignContent: Alignment.Center }) {
      // 半透明背景遮罩，覆盖在最底层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Black)
        .opacity(0.45)
        .zIndex(0)
        .onClick(() => {}) // 阻止点击穿透

      // 弹窗内容
      Column({ space: 20 }) {
        // 标题
        Text('温馨提示')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
          .width('100%')

        // 内容
        Column({ space: 16 }) {
          Text('欢迎使用儿童语音计算器APP！')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('我们非常重视您的个人信息和隐私保护，会通过《隐私说明》向您解释如何收集、使用、存储与保护数据，以及您可以行使的权利。')
            .fontSize(14)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('1、应用无需注册或登录，学习记录仅保存在应用沙箱内，您可在设置中随时清除；')
            .fontSize(14)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('2、仅在您启用语音计算时申请麦克风权限，语音数据在本地即时识别，不会上传或存储副本；')
            .fontSize(14)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('3、应用不接入广告与第三方统计服务，也不会访问定位、通讯录等额外权限。')
            .fontSize(14)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Start)
            .width('100%')

          // 应用特点
          Column({ space: 8 }) {
            Text('本应用特点：')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1e40af')
              .textAlign(TextAlign.Start)
              .width('100%')

            Text('• 无需联网与注册即可体验全部学习功能')
              .fontSize(12)
              .fontColor('#2563eb')
              .textAlign(TextAlign.Start)
              .width('100%')

            Text('• 仅在使用语音功能时申请麦克风权限')
              .fontSize(12)
              .fontColor('#2563eb')
              .textAlign(TextAlign.Start)
              .width('100%')

            Text('• 学习进度与错题全程本地存储，支持一键清除')
              .fontSize(12)
              .fontColor('#2563eb')
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor('#dbeafe')
          .borderRadius(8)

          // 协议链接
          Row({ space: 8 }) {
            Button('《隐私说明》')
              .fontSize(12)
              .fontColor('#3b82f6')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .onClick(() => this.showPrivacyPolicy())

            Text('|')
              .fontSize(12)
              .fontColor('#9ca3af')

            Button('《用户协议》')
              .fontSize(12)
              .fontColor('#3b82f6')
              .backgroundColor(Color.Transparent)
              .border({ width: 0 })
              .onClick(() => this.showUserAgreement())
          }
          .justifyContent(FlexAlign.Center)
          .width('100%')
        }
        .width('100%')

        // 按钮区域
        Column({ space: 12 }) {
          Button('同意并进入')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#3b82f6')
            .borderRadius(24)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .onClick(() => this.agreePrivacy())

          Button('退出')
            .fontSize(16)
            .fontColor('#6b7280')
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .onClick(() => this.rejectPrivacy())
        }
        .width('100%')
      }
      .width('85%')
      .height('80%')
      .padding({ left: 24, right: 24, top: 24, bottom: 24 })
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 20, color: '#00000030', offsetX: 0, offsetY: 10 })
      .zIndex(1)
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  // 隐私说明/用户协议页面
  @Builder
  PolicyPage(): void {
    Stack() {
      // 全屏背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.White)

      // 页面内容
      Column() {
        // 头部
        Row() {
          Button('返回')
            .fontSize(14)
            .fontColor('#1f2937')
            .backgroundColor('#f3f4f6')
            .borderRadius(8)
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .onClick(() => this.closePolicyPage())

          Blank()

          Text(this.showPolicyPage === 'privacy' ? '隐私说明' : '用户协议')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')

          Blank()

          Button('×')
            .fontSize(20)
            .fontColor('#6b7280')
            .backgroundColor(Color.Transparent)
            .border({ width: 0 })
            .onClick(() => this.closePolicyPage())
        }
        .width('100%')
        .height(48)
        .padding({ left: 16, right: 16 })
        .border({ width: { bottom: 1 }, color: '#e5e7eb' })

        // 内容区域
        if (this.showPolicyPage === 'privacy') {
          this.PrivacyPolicyContent()
        } else if (this.showPolicyPage === 'agreement') {
          this.UserAgreementContent()
        }
      }
      .width('100%')
      .height('100%')
        .zIndex(1)
    }
    .width('100%')
    .height('100%')
  }

  // 隐私说明内容
  @Builder
  PrivacyPolicyContent(): void {
    Scroll() {
      Column({ space: 20 }) {
        Text('隐私说明')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Start)
          .width('100%')

        Column({ space: 12 }) {
          Text('1. 适用范围')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('本说明适用于 HarmonyOS 版本的《儿童语音计算器》。我们在遵循合法、正当、必要原则的前提下，为儿童提供安全可靠的语音数学学习服务。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('2. 数据收集范围')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('我们仅收集维持核心功能所需的信息：\n• 设备运行信息：系统版本、设备型号、语言区域，用于兼容性验证；\n• 学习数据：练习成绩、错题记录、学习偏好，仅保存在本机；\n• 语音数据：在您主动使用语音功能时临时处理，识别完成后立即清除。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('3. 数据使用方式')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('上述信息仅用于：\n• 提供语音识别口算、练习统计等核心功能；\n• 在本机生成个性化题目与学习报告；\n• 保障应用稳定运行并排查 HarmonyOS 环境下的兼容问题。我们不会用于广告推送或出售给第三方。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('4. HarmonyOS 权限说明')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('我们秉持权限最小化原则：\n• ohos.permission.MICROPHONE（必需）：仅在您开启语音功能时申请，用于识别语音指令；\n• 其他敏感权限（位置、通讯录、存储等）：均不申请。您可随时在系统设置中撤回授权。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('5. 数据存储与安全')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('所有学习数据存放于 HarmonyOS 应用沙箱内，不会上传至云端。语音片段仅短暂存在内存中并在识别后删除。我们定期审查权限调用并更新安全措施，防止未授权访问和滥用。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('6. 儿童个人信息保护')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('应用无需注册账号，不含广告、第三方统计 SDK 或社交分享功能。监护人可在设置 > 清除学习数据处随时删除本机记录，并引导儿童合理使用电子产品。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('7. 您的权利与行使方式')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('您可以查看或重置学习数据，拒绝或撤回麦克风权限（语音功能将受限），并通过应用内反馈或邮箱提交咨询、投诉与建议，我们将在15个工作日内答复。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('8. 更新与联系')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('本说明如有重大变更，我们将在应用内弹窗或更新日志中提示。开发者：安徽通拓电子商务有限公司，联系方式：novcat@colletools.com。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .scrollBarColor(Color.Transparent)
    .scrollBarWidth(0)
  }

  // 用户协议内容
  @Builder
  UserAgreementContent(): void {
    Scroll() {
      Column({ space: 20 }) {
        Text('用户协议')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Start)
          .width('100%')

        Column({ space: 12 }) {
          Text('1. 协议说明')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('当您或受监护的儿童安装、使用或登录 HarmonyOS 版本《儿童语音计算器》，即表示已阅读并同意遵守本协议。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('2. 服务内容')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('应用提供语音口算、分级练习、错题巩固、学习报告等教育功能，用于辅助儿童在本地设备上进行数学学习。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('3. 使用规范')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('您承诺：\n• 仅将本应用用于合法、正当的学习场景；\n• 不进行逆向工程、破解或恶意攻击；\n• 不上传、制作、传播违法或不当内容；\n• 尊重我们及相关权利人的知识产权。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('4. 适龄用户与监护责任')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('本应用主要面向3-12岁儿童。监护人应在允许儿童使用前阅读本协议与隐私说明，并在使用过程中提供必要的指导与监督。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('5. 数据与隐私保护')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('我们按照《隐私说明》保护您的信息。学习数据仅存储在本机，监护人可通过设置页查看或清除。撤回麦克风权限后，语音功能将不可用但其他功能仍可使用。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('6. 权限与设备安全')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('语音功能需申请 ohos.permission.MICROPHONE。您可随时在系统设置中调整授权。请保持设备系统、补丁和安全防护为最新状态。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('7. 知识产权')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('本应用的界面设计、文本、音频、动画、程序代码及其他内容均受知识产权法保护，未经许可不得复制、改编、发布或用于商业用途。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('8. 服务变更与终止')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('我们可能因业务调整、政策要求或 HarmonyOS 平台变动对功能进行优化或下线。重大变更将通过应用内通知提示，如您不同意，可停止使用并卸载本应用。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('9. 免责声明')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('本应用按“现状”提供，我们将在合理范围内维护服务，但对因设备故障、系统异常、不可抗力或第三方原因造成的损失不承担额外责任。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 12 }) {
          Text('10. 协议更新与联系')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('我们可能通过更新日志或页面公告调整本协议，更新后继续使用即视为接受。咨询或投诉邮箱：novcat@colletools.com。')
            .fontSize(14)
            .fontColor('#374151')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .scrollBarColor(Color.Transparent)
    .scrollBarWidth(0)
  }
}
