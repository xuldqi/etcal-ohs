import { UnifiedHeader } from '../components/UnifiedHeader'

// 举报类型
type ReportType = 'bug' | 'feature' | 'ui' | 'performance' | 'other'

// 举报类型配置
interface ReportTypeConfig {
  id: ReportType
  label: string
  description: string
  icon: string
  color: string
}

@Component
export struct ReportIssuePage {
  onNavigate: (page: string) => void = () => {}
  registerBackHandler: (handler: (() => boolean) | null) => void = () => {}
  
  @State reportType: ReportType | null = null
  @State description: string = ''
  @State contact: string = ''
  @State isSubmitting: boolean = false
  @State showSuccess: boolean = false

  private handleBackNavigation(): boolean {
    this.onNavigate('settings')
    return true
  }
  
  // 举报类型配置
  private reportTypes: ReportTypeConfig[] = [
    {
      id: 'bug',
      label: '功能异常',
      description: '应用出现错误或异常',
      icon: '🐛',
      color: '#ef4444'
    },
    {
      id: 'feature',
      label: '功能建议',
      description: '希望添加新功能',
      icon: '💡',
      color: '#3b82f6'
    },
    {
      id: 'ui',
      label: '界面问题',
      description: '界面显示或交互问题',
      icon: '🎨',
      color: '#8b5cf6'
    },
    {
      id: 'performance',
      label: '性能问题',
      description: '应用运行缓慢或卡顿',
      icon: '⚡',
      color: '#f59e0b'
    },
    {
      id: 'other',
      label: '其他问题',
      description: '其他类型的问题',
      icon: '❓',
      color: '#6b7280'
    }
  ]

  aboutToAppear() {
    console.log('[问题举报] 页面初始化')
    this.registerBackHandler(() => this.handleBackNavigation())
  }

  aboutToDisappear() {
    this.registerBackHandler(null)
  }

  build() {
    Column() {
      // 统一标题栏
      UnifiedHeader({
        title: '问题举报',
        onBack: () => { this.handleBackNavigation() }
      })

      if (this.showSuccess) {
        this.SuccessView()
      } else {
        this.ReportForm()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f8fafc')
    .padding({ bottom: 20 })
  }

  // 举报表单
  @Builder
  ReportForm() {
    Scroll() {
      Column({ space: 24 }) {
        // 问题类型选择
        Column({ space: 16 }) {
          Text('请选择问题类型')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .alignSelf(ItemAlign.Start)

          Column({ space: 12 }) {
            ForEach(this.reportTypes, (type: ReportTypeConfig) => {
              this.ReportTypeCard(type)
            })
          }
        }

        // 问题描述
        Column({ space: 12 }) {
          Text('问题描述')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#374151')
            .alignSelf(ItemAlign.Start)

          TextArea({ placeholder: '请详细描述您遇到的问题...' })
            .width('100%')
            .height(120)
            .fontSize(14)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .padding(12)
            .border({ width: 1, color: '#d1d5db' })
            .onChange((value: string) => {
              this.description = value
            })
        }

        // 联系方式（可选）
        Column({ space: 12 }) {
          Text('联系方式（可选）')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#374151')
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: '邮箱或手机号，方便我们联系您' })
            .width('100%')
            .height(48)
            .fontSize(14)
            .backgroundColor('#ffffff')
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .border({ width: 1, color: '#d1d5db' })
            .onChange((value: string) => {
              this.contact = value
            })
        }

        // 提交按钮
        Button('提交举报')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor(this.canSubmit() ? '#3b82f6' : '#9ca3af')
          .fontColor('#ffffff')
          .borderRadius(8)
          .enabled(this.canSubmit())
          .onClick(() => {
            this.submitReport()
          })
      }
      .padding({ left: 20, right: 20, top: 20, bottom: 100 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .scrollBarColor(Color.Transparent)
    .scrollBarWidth(0)
  }

  // 举报类型卡片
  @Builder
  ReportTypeCard(type: ReportTypeConfig) {
    Row({ space: 12 }) {
      Text(type.icon)
        .fontSize(24)
      
      Column({ space: 4 }) {
        Text(type.label)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1f2937')
        
        Text(type.description)
          .fontSize(12)
          .fontColor('#6b7280')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.reportType === type.id) {
        Text('✓')
          .fontSize(20)
          .fontColor('#3b82f6')
          .fontWeight(FontWeight.Bold)
      }
    }
    .width('100%')
    .height(64)
    .padding(16)
    .backgroundColor(this.reportType === type.id ? '#eff6ff' : '#ffffff')
    .borderRadius(8)
    .border({ 
      width: this.reportType === type.id ? 2 : 1, 
      color: this.reportType === type.id ? '#3b82f6' : '#d1d5db' 
    })
    .onClick(() => {
      this.reportType = type.id
    })
  }

  // 成功页面
  @Builder
  SuccessView() {
    Column({ space: 24 }) {
      // 成功图标
      Text('✅')
        .fontSize(64)
        .margin({ top: 40 })

      Text('举报提交成功！')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#10b981')
        .textAlign(TextAlign.Center)

      Text('感谢您的反馈，我们会认真处理您的问题。')
        .fontSize(16)
        .fontColor('#6b7280')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })

      // 联系方式
      Column({ space: 12 }) {
        Text('如需紧急联系，请通过以下方式：')
          .fontSize(14)
          .fontColor('#374151')
          .textAlign(TextAlign.Center)

        Text('邮箱：novcat@colletools.com')
          .fontSize(14)
          .fontColor('#3b82f6')
          .textAlign(TextAlign.Center)
      }
      .margin({ top: 24 })

      // 返回按钮
      Button('返回设置')
        .width(200)
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#3b82f6')
        .fontColor('#ffffff')
        .borderRadius(8)
        .margin({ top: 32 })
        .onClick(() => {
          this.onNavigate('settings')
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .padding(20)
  }

  // 检查是否可以提交
  private canSubmit(): boolean {
    return !!(this.reportType && this.description.trim().length > 0)
  }

  // 提交举报
  private async submitReport() {
    if (!this.canSubmit()) {
      return
    }

    this.isSubmitting = true
    console.log('[问题举报] 提交举报:', {
      type: this.reportType,
      description: this.description,
      contact: this.contact
    })

    // 模拟提交过程
    setTimeout(() => {
      this.isSubmitting = false
      this.showSuccess = true
    }, 1000)
  }
}
