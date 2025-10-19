import router from '@ohos.router';

@Entry
@Component
struct PrivacyPolicyPage {
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
        
        Text('隐私说明')
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
          Text('隐私说明')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })
          
          Text('更新日期：2024年12月1日')
            .fontSize(14)
            .fontColor('#666')
            .margin({ bottom: 24 })
          
          Column() {
            Text('1. 适用范围')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本隐私说明适用于 HarmonyOS 版本的《儿童语音计算器》（下称“本应用”）。应用由安徽通拓电子商务有限公司提供，旨在帮助儿童在 HarmonyOS 设备上进行语音数学学习。我们遵循合法、正当、最小必要原则处理个人信息。')
              .fontSize(14)
              .lineHeight(20)
              .margin({ bottom: 20 })
            
            Text('2. 我们收集的信息')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('我们仅在您使用功能时收集下列与服务直接相关的信息：')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)
            
            Text('• 设备运行信息：系统版本、设备型号、语言区域，仅用于保障兼容性与界面适配；')
              .fontSize(14)
              .margin({ bottom: 4 })
              .alignSelf(ItemAlign.Start)
            
            Text('• 学习数据：练习成绩、错题记录、学习偏好，全部保留在本地沙箱内，便于生成离线报告；')
              .fontSize(14)
              .margin({ bottom: 4 })
              .alignSelf(ItemAlign.Start)
            
            Text('• 语音数据：在您主动开启语音计算时临时处理的语音片段，仅在设备端实时识别，不会上传或保存副本。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('我们不会收集您的姓名、身份证件号码、精确定位、通讯录等与服务无关的敏感信息。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('3. 信息使用方式')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('前述信息仅用于：\n• 实现语音识别、练习题生成、学习统计等核心功能；\n• 保存您的学习进度与个性化配置，便于在本机继续学习；\n• 保障应用稳定运行，排查在 HarmonyOS 环境下出现的性能问题。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('我们不会将信息用于个性化广告、用户画像或向第三方出售。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('4. HarmonyOS 权限说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本应用遵循 HarmonyOS 权限最小化原则，仅在必要时申请以下权限：')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 8 })
              .alignSelf(ItemAlign.Start)
            
            Text('• ohos.permission.MICROPHONE（麦克风，必需）：用于语音计算与口算练习，仅在您触发语音功能时申请，可随时在系统设置中管理。除上述权限外，我们不申请位置、通讯录、存储等其他敏感权限。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('5. 数据存储与安全')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('• 所有业务数据仅存放在 HarmonyOS 提供的应用沙箱内，不会上传至云端；\n• 语音数据在识别完成后立即从内存中清除；\n• 关键学习记录采用本地加密与备份校验，防止未授权访问；\n• 我们定期检查权限调用与日志，及时修复潜在安全风险。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('6. 儿童个人信息保护')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('本应用面向儿童用户，未成年人使用需在监护人同意并监督下进行。我们承诺：\n• 不要求注册账号，不收集与身份识别相关的数据；\n• 不含广告、应用内购买或第三方统计 SDK；\n• 监护人可通过“设置 > 清除学习数据”随时删除本地信息。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('7. 您的权利与行使方式')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('您可以：\n• 在应用内查看、导出或重置学习记录；\n• 拒绝或撤回麦克风权限授权，语音功能将相应受限；\n• 通过我们提供的联系方式咨询、投诉或建议。我们将在15个工作日内答复。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('8. 本说明的更新')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('若本隐私说明发生重大变更，我们将通过应用内弹窗或更新日志提示您。变更后继续使用本应用，即表示您同意修订内容。')
              .fontSize(14)
              .margin({ bottom: 20 })
              .alignSelf(ItemAlign.Start)
            
            Text('9. 联系我们')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
              .alignSelf(ItemAlign.Start)
            
            Text('开发者：安徽通拓电子商务有限公司\n联系邮箱：novcat@colletools.com\n如您对隐私保护有任何疑问、意见或建议，请通过邮箱或应用内反馈与我们联系。')
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
