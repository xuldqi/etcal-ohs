// 统一标题栏组件
@Component
export struct UnifiedHeader {
  title: string = ''
  onBack: () => void = () => {}
  showBackButton: boolean = true

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
      }
      .width('100%')
    }
    .width('100%')
    .height(48)
    .margin({ top: 8, bottom: 8 })
  }
}