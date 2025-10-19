import router from '@ohos.router';

@Entry
@Component
struct UserAgreementPage {
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('← 返回')
          .backgroundColor('#f0f0f0')
          .fontColor('#333')
          .onClick(() => {
            router.back();
          })
          .margin({ left: 16 })
        
        Blank()
        
        Text('用户协议')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
        
        Blank()
        
        // 占位空间保持居中
        Row().width(80)
      }
      .height(56)
      .width('100%')
      .backgroundColor(Color.White)
      .shadow({ radius: 2, color: 'rgba(0,0,0,0.1)' })
      
      // 内容区域
      Scroll() {
        Column() {
          Text('用户协议')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })
          
          Text('更新日期：2024年12月1日')
            .fontSize(14)
            .fontColor('#666')
            .margin({ bottom: 24 })
          
          Column() {
            Text('1. 协议说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本协议适用于 HarmonyOS 版本的《儿童语音计算器》。当您或受监护的儿童下载、安装、使用或登录本应用，即表示您已阅读、理解并同意受本协议约束。')
              .fontSize(14)
              .lineHeight(20)
              .margin({ bottom: 20 })
            
            Text('2. 服务内容')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本应用提供以下学习服务：\n• 语音识别数学计算与口算训练；\n• 难度分级的数学练习题与错题巩固；\n• 动画化、游戏化的学习场景与激励机制；\n• 本地化的学习记录、学习报告与家长查看功能。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('3. 使用规范')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('您承诺在使用本应用时：\n• 遵守法律法规及社会公序良俗；\n• 不对应用进行逆向工程、破解或恶意攻击；\n• 不传播违法、暴力、低俗等不当内容；\n• 不将本应用用于商业推广或任何未经授权的用途。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('4. 适龄用户与监护责任')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本应用主要面向3-12岁儿童。未成年人使用应由监护人事先同意并在使用过程中给予必要的指导与监督。监护人应保障儿童合理安排学习时间，避免过度使用电子产品。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('5. 数据与隐私保护')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('我们将按照《隐私说明》保护您的信息，仅在本机保存学习相关数据。请您与儿童共同理解权限授权、数据保存与删除方式，必要时可通过“清除学习数据”随时删除本地记录。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('6. 权限与设备安全')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('为提供语音相关功能，我们将按需申请 ohos.permission.MICROPHONE。拒绝授权仅会使语音功能不可用，不影响其他学习功能。请妥善保管设备，及时安装 HarmonyOS 官方安全更新。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('7. 知识产权')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本应用展示或产生的所有内容（包括界面设计、文本、图片、音频、动画、程序代码等）均受知识产权法保护。未经书面许可，您不得复制、改编、传播或用于商业目的。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('8. 服务变更与终止')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('我们可能根据业务发展、HarmonyOS 平台政策或法律法规更新调整功能。对于重大变更，我们会通过应用内通知提示。若您不同意变更，可停止使用并卸载本应用。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('9. 免责声明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本应用按“现状”提供，我们将尽力保持服务连续、安全、可靠，但不对下列情况承担责任：\n• 因设备故障、系统缺陷导致的服务中断；\n• 因用户误用、未授权修改造成的数据损失；\n• 非我们控制范围内的不可抗力或第三方原因。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('10. 协议更新与联系')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('我们可能适时更新本协议，更新后的版本将通过应用内页面或更新日志生效并提示。若您对本协议或服务有任何疑问，请联系：novcat@colletools.com。')
              .fontSize(14)
              .margin({ bottom: 40 })
              .alignSelf(ItemAlign.Start)
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
        }
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
