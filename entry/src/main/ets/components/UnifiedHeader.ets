// 统一标题栏组件
@Component
export struct UnifiedHeader {
  @Prop title: string = ''
  onBack: () => void = () => {}
  showBackButton: boolean = true
  rightButtonText?: string = ''
  rightButtonColor?: string = '#2C7A4B'
  rightButtonBgColor?: string = '#EEF8F2'
  onRightButtonClick?: () => void = () => {}

  @Builder
  build() {
    Stack() {
      // 居中标题
      Text(this.title)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')
        .textAlign(TextAlign.Center)
        .width('100%')

      // 左侧返回按钮
      Row() {
        if (this.showBackButton) {
          Button('返回')
            .fontSize(14)
            .fontColor('#1f2937')
            .backgroundColor(Color.White)
            .borderRadius(20)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
            .margin({ left: 4 })
            .onClick(() => { this.onBack() })
        }

        Blank()

        // 右侧按钮
        if (this.rightButtonText) {
          Button(this.rightButtonText)
            .fontSize(14)
            .fontColor(this.rightButtonColor)
            .backgroundColor(this.rightButtonBgColor)
            .borderRadius(20)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
            .margin({ right: 4 })
            .onClick(() => { this.onRightButtonClick?.() })
        }
      }
      .width('100%')
    }
    .width('100%')
    .height(48)
    .margin({ top: 8, bottom: 8 })
  }
}