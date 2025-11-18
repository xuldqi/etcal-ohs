// 统一标题栏组件
@Component
export struct UnifiedHeader {
  @Prop title: string = ''
  onBack: () => void = () => {}
  showBackButton: boolean = true
  rightButtonText: string = ''
  rightButtonColor: string = '#2C7A4B'
  rightButtonBgColor: string = '#EEF8F2'
  onRightButtonClick: () => void = () => {}

  @Builder
  build() {
    Row({ space: 12 }) {
      if (this.showBackButton) {
        this.HeaderButton('返回', '#1f2937', Color.White, () => { this.onBack() })
      } else {
        Blank()
          .width(72)
          .height(36)
      }

      Column() {
        Text(this.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
          .width('100%')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      if (this.rightButtonText.trim().length > 0) {
        this.HeaderButton(this.rightButtonText, this.rightButtonColor, this.rightButtonBgColor, () => { this.onRightButtonClick() })
      } else if (this.showBackButton) {
        Blank()
          .width(72)
          .height(36)
      }
    }
    .width('100%')
    .alignItems(VerticalAlign.Center)
    .padding({ top: 12, bottom: 4, left: 16, right: 16 })
  }

  @Builder
  HeaderButton(label: string, textColor: ResourceColor | string, backgroundColor: ResourceColor | string, onClick: () => void) {
    Button() {
      Text(label)
        .fontSize(14)
        .fontColor(textColor)
        .fontWeight(FontWeight.Medium)
    }
    .backgroundColor(backgroundColor)
    .borderRadius(20)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
    .onClick(() => { onClick() })
  }
}
