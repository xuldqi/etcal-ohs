import { UnifiedHeader } from '../components/UnifiedHeader'
import { AudioManager } from '../managers/AudioManager'
import { StorageManager } from '../managers/StorageManager'
import common from '@ohos.app.ability.common'

interface SettingsSection {
  title: string
  content: string
}

interface SettingsContent {
  title: string
  sections: SettingsSection[]
}

interface SettingsItem {
  id: string
  title: string
  description: string
  icon: string
  color: string
  type: 'navigation' | 'info'
  route?: string
  content?: SettingsContent
}

@Component
export struct AppSettingsPage {
  onNavigate: (page: string) => void = () => {}
  openContentId: string = ''
  onOpened?: () => void = undefined
  onBackToHome?: () => void = undefined
  registerBackHandler: (handler: (() => boolean) | null) => void = () => {}
  @Prop fromPrivacyDialog: boolean = false

  @State selectedItem: SettingsItem | null = null
  @State pageTitle: string = '设置'
  private openedDirectly: boolean = false
  @State voiceEnabled: boolean = true
  private audioManager: AudioManager = AudioManager.getInstance()
  private storageManager: StorageManager = StorageManager.getInstance()
  private abilityContext: common.UIAbilityContext | null = null

  private handleBackNavigation(): boolean {
    if (this.selectedItem) {
      if (this.openedDirectly && this.fromPrivacyDialog) {
        this.openedDirectly = false
        if (this.onBackToHome) {
          this.onBackToHome()
        } else {
          this.onNavigate('home')
        }
      } else {
        this.selectedItem = null
        this.pageTitle = '设置'
        this.openedDirectly = false
      }
      return true
    }

    if (this.onBackToHome) {
      this.onBackToHome()
    } else {
      this.onNavigate('home')
    }
    return true
  }

  async aboutToAppear() {
    this.registerBackHandler(() => this.handleBackNavigation())
    // 初始化存储并恢复语音开关
    try {
      this.abilityContext = getContext(this) as common.UIAbilityContext
      if (this.abilityContext) {
        await this.storageManager.init(this.abilityContext)
      }
      const stored = await this.storageManager.getItem('voice_enabled')
      if (stored !== null) {
        const enabled = JSON.parse(stored) as boolean
        this.voiceEnabled = enabled
        this.audioManager.setEnabled(enabled)
      } else {
        // 若无存储，使用当前音频管理器状态并写入
        this.voiceEnabled = this.audioManager.getEnabled()
        await this.storageManager.setItem('voice_enabled', JSON.stringify(this.voiceEnabled))
      }
    } catch (error) {
      // 存储失败不影响页面显示
      this.voiceEnabled = this.audioManager.getEnabled()
    }
    if (this.openContentId) {
      const targetItem = this.items.find(item => item.id === this.openContentId)
      if (targetItem) {
        this.selectedItem = targetItem
        this.openedDirectly = true
        this.pageTitle = targetItem.content?.title || targetItem.title
      }
    } else {
      this.pageTitle = '设置'
    }
    
    if (this.onOpened) {
      setTimeout(() => {
        this.onOpened?.()
      }, 0)
    }
  }

  aboutToDisappear() {
    this.registerBackHandler(null)
  }

  private items: SettingsItem[] = [
    {
      id: 'privacy',
      title: '隐私说明',
      description: '数据与权限说明',
      icon: '',
      color: '#3b82f6',
      type: 'info',
      content: {
        title: '隐私说明',
        sections: [
          {
            title: '1. 适用范围',
            content: '本说明适用于《儿童语音计算器》。我们遵循合法、正当、必要原则，为儿童提供安全的语音数学学习体验。'
          },
          {
            title: '2. 数据收集范围',
            content: '• 设备运行信息：系统版本、设备型号、语言区域，用于兼容性适配；\n• 学习数据：练习成绩、错题记录、学习偏好，仅保存在本机；\n• 语音数据：仅在语音功能开启时本地识别，实时处理后即刻清除。'
          },
          {
            title: '3. 数据使用方式',
            content: '我们只将上述信息用于实现语音口算、学习统计等核心功能，以及在本机生成个性化学习内容，不用于广告或商业变现。'
          },
          {
            title: '4. 权限说明',
            content: '• 麦克风权限（必需）：在您主动使用语音计算时申请，用于识别语音指令；\n• 其他敏感权限：不申请位置、通讯录、存储等权限，确保应用在最小授权下运行。'
          },
          {
            title: '5. 数据存储与安全',
            content: '所有学习记录存放于应用沙箱内，不会上传至服务器。语音数据仅在内存中短暂存在。我们定期自查权限调用和日志，持续提升安全保障。'
          },
          {
            title: '6. 儿童信息保护',
            content: '应用无需注册账号，不提供广告、应用内购买和第三方统计 SDK。监护人可随时在设置页选择"清除学习数据"删除本机记录。\n\n有关14周岁以下儿童隐私保护的详细说明，请访问我们的儿童隐私政策页面：\nhttps://tsto.bambumoon.cn/children-privacy-policy.html'
          },
          {
            title: '7. 您的权利',
            content: '您可查看、导出或重置学习数据；可拒绝或撤回麦克风权限（语音功能将受限）；可通过应用内反馈或邮箱提出咨询与投诉，我们将在15个工作日内处理。'
          },
          {
            title: '8. 联系我们',
            content: '开发者：安徽通拓电子商务有限公司\n邮箱：novcat@colletools.com\n最新更新：2024年12月1日'
          }
        ]
      }
    },
    {
      id: 'children-privacy',
      title: '儿童隐私保护',
      description: '监护人需知的儿童信息保护要点',
      icon: '',
      color: '#ec4899',
      type: 'info',
      content: {
        title: '儿童隐私说明',
        sections: [
          {
            title: '1. 使用前提示',
            content: '本应用为3-12岁儿童设计，建议在监护人同意并陪同下使用。我们不会要求儿童填写真实姓名、联系方式等身份信息。'
          },
          {
            title: '2. 收集与不收集',
            content: '仅在本机保存练习成绩、错题本、语音听写记录等学习数据；不收集精确定位、相册、摄像头、通讯录、生物识别等敏感信息。'
          },
          {
            title: '3. 使用目的与限制',
            content: '所有数据只用于改进学习体验与难度推荐，不用于广告投放或跨应用追踪。应用不含社交分享、评论区、社区等功能。'
          },
          {
            title: '4. 家长工具',
            content: '监护人可在设置中查看学习报告、手动清除数据或停用语音权限，帮助孩子合理安排学习节奏。'
          },
          {
            title: '5. 反馈渠道',
            content: '若发现不当内容或隐私风险，请立即通过 novcat@colletools.com 联系我们，我们将在15个工作日内处理。'
          }
        ]
      }
    },
    {
      id: 'report',
      title: '问题举报',
      description: '举报不当内容或安全隐患',
      icon: '',
      color: '#ef4444',
      type: 'navigation',
      route: 'report-issue',
      content: {
        title: '问题举报',
        sections: [
          {
            title: '举报内容',
            content: '如果您发现以下问题，请及时联系我们：\n• 应用内容不当\n• 安全隐患\n• 功能故障\n• 其他问题'
          },
          {
            title: '举报方式',
            content: '邮箱：novcat@colletools.com\n请在邮件中详细描述问题，我们会在24小时内回复。'
          },
          {
            title: '处理流程',
            content: '1. 收到举报后，我们会立即核实\n2. 确认问题后，会在72小时内处理\n3. 处理完成后，会通过邮件通知您'
          }
        ]
      }
    },
    {
      id: 'terms',
      title: '用户协议',
      description: '服务条款与使用规则',
      icon: '',
      color: '#22c55e',
      type: 'info',
      content: {
        title: '用户协议',
        sections: [
          {
            title: '1. 协议生效',
            content: '安装、登录或使用 HarmonyOS 版本《儿童语音计算器》，即视为您已阅读并接受本协议全部条款。'
          },
          {
            title: '2. 服务内容',
            content: '提供语音算术训练、分级练习题、错题复盘、学习报告等面向儿童的教育功能。'
          },
          {
            title: '3. 使用规范',
            content: '• 仅将本应用用于合法的学习场景；\n• 不进行逆向工程、恶意攻击或传播不当内容；\n• 未成年人须在监护指导下使用。'
          },
          {
            title: '4. 权限与安全',
            content: '语音功能需授权麦克风权限，您可随时在系统设置中撤回，撤回后语音功能将不可用。请保持设备系统与安全补丁为最新状态。'
          },
          {
            title: '5. 知识产权与免责声明',
            content: '应用内容和代码均受保护，未经许可不得复制或商用。本应用按“现状”提供，不对因设备或系统故障导致的服务中断承担额外责任。'
          },
          {
            title: '6. 协议更新与咨询',
            content: '我们可能通过应用更新或公告调整条款，更新后继续使用视为接受。咨询邮箱：novcat@colletools.com。'
          }
        ]
      }
    },
    {
      id: 'about',
      title: '关于我们',
      description: '了解儿童语音计算器的开发团队',
      icon: '',
      color: '#a855f7',
      type: 'info',
      content: {
        title: '关于我们',
        sections: [
          {
            title: '我们的使命',
            content: '让每个孩子都能在快乐中学习数学，通过语音交互和游戏化的方式培养数学思维和计算能力。'
          },
          {
            title: '产品特色',
            content: '• 语音交互计算器\n• 数学练习功能\n• 数学大冒险游戏\n• 自定义语音方案\n• 学习进度跟踪'
          },
          {
            title: '开发理念',
            content: '我们相信学习应该是快乐的。通过语音交互和精心设计的游戏机制，让孩子在探索中学习，在挑战中成长。'
          }
        ]
      }
    },
    {
      id: 'contact',
      title: '联系我们',
      description: '反馈建议和技术支持',
      icon: '',
      color: '#f97316',
      type: 'info',
      content: {
        title: '联系我们',
        sections: [
          {
            title: '反馈建议',
            content: '如果您在使用过程中有任何建议或发现问题，欢迎通过以下方式联系我们。'
          },
          {
            title: '技术支持',
            content: '遇到技术问题？我们的技术团队随时为您提供帮助。请详细描述问题，我们会尽快回复。'
          },
          {
            title: '合作洽谈',
            content: '如果您有合作意向或商务咨询，欢迎与我们联系。我们期待与您的合作。'
          },
          {
            title: '联系方式',
            content: '邮箱：novcat@colletools.com\n工作时间：周一至周五 9:00-18:00'
          }
        ]
      }
    }
  ]

  private handleItemSelect(item: SettingsItem) {
    if (item.type === 'navigation' && item.route) {
      // 导航类型，跳转到指定页面
      this.onNavigate(item.route)
    } else {
      // 信息类型，展示内容面板
      this.selectedItem = item
      this.pageTitle = item.content?.title || item.title
    }
  }

  @Builder
  MenuCard(item: SettingsItem) {
    Button() {
      Row({ space: 16 }) {
        // 左侧图标（仅在有图标时显示）
        if (item.icon && item.icon !== '') {
          Column() {
            Text(item.icon)
              .fontSize(24)
          }
          .width(48)
          .height(48)
          .backgroundColor(item.color + '20')
          .borderRadius(12)
          .justifyContent(FlexAlign.Center)
        }

        // 中间文字
        Column({ space: 4 }) {
          Text(item.title)
            .fontSize(17)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Start)
            .width('100%')
          Text(item.description)
            .fontSize(13)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        // 右侧箭头
        Text('→')
          .fontSize(20)
          .fontColor('#9ca3af')
      }
      .width('100%')
      .height(80)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
    .onClick(() => { this.handleItemSelect(item) })
  }

  @Builder
  ContentPanel(item: SettingsItem) {
    Column({ space: 16 }) {
      // 内容区域（标题已在UnifiedHeader中显示，这里不再重复）
      if (item.content?.sections) {
        ForEach(item.content.sections, (section: SettingsSection) => {
          Column({ space: 8 }) {
            Text(section.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1f2937')
              .width('100%')
            Text(section.content)
              .fontSize(14)
              .fontColor('#6b7280')
              .lineHeight(22)
              .width('100%')
          }
          .width('100%')
          .padding({ left: 12, right: 12, top: 12, bottom: 12 })
          .backgroundColor('#f8fafc')
          .borderRadius(12)
          .border({ width: { left: 4 }, color: '#e5e7eb' })
        })
      }

      // 返回按钮
      Row() {
        Blank()
        Button('返回')
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor('#6b7280')
          .borderRadius(12)
          .padding({ left: 24, right: 24, top: 10, bottom: 10 })
          .onClick(() => { this.handleBackNavigation() })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 12, color: '#00000015', offsetX: 0, offsetY: 8 })
  }

  build() {
    Column() {
        // 统一标题栏
        UnifiedHeader({
          title: this.pageTitle,
          onBack: () => { this.handleBackNavigation() }
        })

      Scroll() {
        Column({ space: 16 }) {
          // 副标题（只在主页面显示）
          if (this.selectedItem === null) {
            Text('了解更多关于儿童语音计算器的信息')
              .fontSize(15)
              .fontColor('#6b7280')
              .textAlign(TextAlign.Center)
              .width('100%')
              .margin({ top: 8, bottom: 8 })

            // 语音播报开关卡片
            Row({ space: 12 }) {
              Column({ space: 4 }) {
                Text('语音播报')
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1f2937')
                Text(this.voiceEnabled ? '声音已开启' : '声音已关闭')
                  .fontSize(12)
                  .fontColor('#6b7280')
              }
              .layoutWeight(1)

              Button(this.voiceEnabled ? '关闭' : '开启')
                .fontSize(14)
                .fontColor(this.voiceEnabled ? '#ef4444' : Color.White)
                .backgroundColor(this.voiceEnabled ? '#fee2e2' : '#22c55e')
                .borderRadius(16)
                .padding({ left: 18, right: 18, top: 10, bottom: 10 })
                .onClick(async () => {
                  this.voiceEnabled = !this.voiceEnabled
                  this.audioManager.setEnabled(this.voiceEnabled)
                  try {
                    await this.storageManager.setItem('voice_enabled', JSON.stringify(this.voiceEnabled))
                  } catch (_) {}
                  if (this.voiceEnabled) {
                    this.audioManager.speakText('声音已开启')
                  }
                })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
          }

          // 内容区域
          if (this.selectedItem !== null) {
            this.ContentPanel(this.selectedItem as SettingsItem)
          } else {
            // 菜单卡片列表
            Column({ space: 16 }) {
              ForEach(this.items, (item: SettingsItem) => {
                this.MenuCard(item)
              })
            }
            .width('100%')

            // 底部信息
            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text('❤️')
                  .fontSize(18)
                Text('用心打造的儿童语音计算器')
                  .fontSize(14)
                  .fontColor('#6b7280')
                  .fontWeight(FontWeight.Medium)
                Text('⭐')
                  .fontSize(18)
              }
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
              .backgroundColor(Color.White)
              .borderRadius(20)
              .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })

              Text('儿童语音计算器 v1.2.3 | 让学习更有趣')
                .fontSize(12)
                .fontColor('#9ca3af')
            }
            .width('100%')
            .margin({ top: 24, bottom: 12 })
          }
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .align(Alignment.TopStart)
      .scrollBar(BarState.Auto)
      .scrollBarColor(Color.Transparent)
      .scrollBarWidth(0)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 24 })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#bae6fd', 0.0], ['#dbeafe', 0.5], ['#e9d5ff', 1.0]]
    })
  }
}
