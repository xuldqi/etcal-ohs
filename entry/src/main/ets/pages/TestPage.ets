import { AudioManager } from '../managers/AudioManager'
import { VoiceManager } from '../managers/VoiceManager'
import { StorageManager } from '../managers/StorageManager'
import common from '@ohos.app.ability.common'

@Component
export struct TestPage {
  @State testResults: string[] = []
  @State isTesting: boolean = false
  @State currentTest: string = ''

  private audioManager: AudioManager = new AudioManager()
  private voiceManager: VoiceManager = new VoiceManager()
  private storageManager: StorageManager = StorageManager.getInstance()
  private abilityContext: common.UIAbilityContext | null = null

  aboutToAppear() {
    if (!this.abilityContext) {
      try {
        this.abilityContext = getContext(this) as common.UIAbilityContext
      } catch (error) {
        console.error('测试页获取上下文失败:', error)
      }
    }
    if (this.abilityContext) {
      void this.storageManager.init(this.abilityContext)
    }
  }

  build() {
    Column() {
      // 标题
      Text('功能测试页面')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2c3e50')
        .margin({ bottom: 20 })

      // 测试状态
      if (this.isTesting) {
        Text(`正在测试: ${this.currentTest}`)
          .fontSize(16)
          .fontColor('#3b82f6')
          .margin({ bottom: 20 })
      }

      // 测试按钮
      Column() {
        Button('测试音频功能')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#10b981')
          .borderRadius(10)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .margin({ bottom: 10 })
          .onClick(() => {
            this.testAudioFunction()
          })

        Button('测试语音功能')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#8b5cf6')
          .borderRadius(10)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .margin({ bottom: 10 })
          .onClick(() => {
            this.testVoiceFunction()
          })

        Button('测试存储功能')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#f59e0b')
          .borderRadius(10)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .margin({ bottom: 10 })
          .onClick(() => {
            this.testStorageFunction()
          })

        Button('运行所有测试')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#ef4444')
          .borderRadius(10)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .margin({ bottom: 10 })
          .onClick(() => {
            this.runAllTests()
          })

        Button('清除测试结果')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#6b7280')
          .borderRadius(10)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .onClick(() => {
            this.clearResults()
          })
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 测试结果
      if (this.testResults.length > 0) {
        Column() {
          Text('测试结果')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2c3e50')
            .margin({ bottom: 10 })

          ForEach(this.testResults, (result: string, index: number) => {
            Text(`${index + 1}. ${result}`)
              .fontSize(14)
              .fontColor('#374151')
              .margin({ bottom: 5 })
              .alignSelf(ItemAlign.Start)
          })
        }
        .width('100%')
        .padding(15)
        .backgroundColor('#f8fafc')
        .borderRadius(10)
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
    .padding(20)
    .justifyContent(FlexAlign.Start)
  }

  // 测试音频功能
  async testAudioFunction() {
    this.addResult('开始测试音频功能...')
    this.isTesting = true
    this.currentTest = '音频功能'

    try {
      // 初始化音频管理器
      await this.audioManager.init()
      this.addResult('成功：音频管理器初始化成功')

      // 测试播放数字
      await this.audioManager.playNumber(5)
      this.addResult('成功：播放数字音频成功')

      // 测试播放运算符
      await this.audioManager.playOperator('+')
      this.addResult('成功：播放运算符音频成功')

      // 测试设置音量
      await this.audioManager.setVolume(0.8)
      this.addResult('成功：设置音量成功')

      // 测试预加载音频
      await this.audioManager.preloadCommonAudios()
      this.addResult('成功：预加载音频成功')

      this.addResult('完成：音频功能测试完成')
    } catch (error) {
      this.addResult(`失败：音频功能测试失败: ${error}`)
    } finally {
      this.isTesting = false
      this.currentTest = ''
    }
  }

  // 测试语音功能
  async testVoiceFunction() {
    this.addResult('开始测试语音功能...')
    this.isTesting = true
    this.currentTest = '语音功能'

    try {
      // 初始化语音管理器
      await this.voiceManager.init(
        (result) => {
          this.addResult(`成功：语音识别结果: ${result}`)
        },
        (error) => {
          this.addResult(`失败：语音识别错误: ${error}`)
        }
      )
      this.addResult('成功：语音管理器初始化成功')

      // 测试权限检查
      const hasPermission = await this.voiceManager.checkPermission()
      this.addResult(`成功：权限检查: ${hasPermission ? '已授权' : '未授权'}`)

      // 测试开始识别
      await this.voiceManager.startRecognition()
      this.addResult('成功：开始语音识别成功')

      // 等待识别完成
      setTimeout(async () => {
        try {
          await this.voiceManager.stopRecognition()
          this.addResult('成功：停止语音识别成功')
          this.addResult('完成：语音功能测试完成')
        } catch (error) {
          this.addResult(`失败：停止语音识别失败: ${error}`)
        } finally {
          this.isTesting = false
          this.currentTest = ''
        }
      }, 3000)

    } catch (error) {
      this.addResult(`失败：语音功能测试失败: ${error}`)
      this.isTesting = false
      this.currentTest = ''
    }
  }

  // 测试存储功能
  async testStorageFunction() {
    this.addResult('开始测试存储功能...')
    this.isTesting = true
    this.currentTest = '存储功能'

    try {
      // 初始化存储管理器
      await this.storageManager.init()
      this.addResult('成功：存储管理器初始化成功')

      // 测试设置数据
      await this.storageManager.setItem('test_key', 'test_value')
      this.addResult('成功：设置存储项成功')

      // 测试获取数据
      const value = await this.storageManager.getItem('test_key')
      this.addResult(`成功：获取存储项成功: ${value}`)

      // 测试检查键是否存在
      const hasKey = await this.storageManager.hasKey('test_key')
      this.addResult(`成功：检查键存在: ${hasKey}`)

      // 测试获取所有键
      const keys = await this.storageManager.getAllKeys()
      this.addResult(`成功：获取所有键成功: ${keys.length}个键`)

      // 测试获取存储大小
      const size = await this.storageManager.getSize()
      this.addResult(`成功：获取存储大小: ${size}个项`)

      // 测试批量设置
      await this.storageManager.setBatch([
        { key: 'batch_key1', value: 'batch_value1' },
        { key: 'batch_key2', value: 'batch_value2' }
      ])
      this.addResult('成功：批量设置存储项成功')

      // 测试批量获取
      const batchValues = await this.storageManager.getBatch(['batch_key1', 'batch_key2'])
      this.addResult(`成功：批量获取存储项成功: ${batchValues.length}个项`)

      // 测试导出数据
      const exportedData = await this.storageManager.exportData()
      this.addResult(`成功：导出数据成功: ${exportedData.length}个项`)

      // 清理测试数据
      await this.storageManager.removeItem('test_key')
      await this.storageManager.removeItem('batch_key1')
      await this.storageManager.removeItem('batch_key2')
      this.addResult('成功：清理测试数据成功')

      this.addResult('完成：存储功能测试完成')
    } catch (error) {
      this.addResult(`失败：存储功能测试失败: ${error}`)
    } finally {
      this.isTesting = false
      this.currentTest = ''
    }
  }

  // 运行所有测试
  async runAllTests() {
    this.clearResults()
    this.addResult('开始：开始运行所有测试...')

    await this.testAudioFunction()
    await new Promise(resolve => setTimeout(resolve, 1000))

    await this.testVoiceFunction()
    await new Promise(resolve => setTimeout(resolve, 1000))

    await this.testStorageFunction()

    this.addResult('完成：所有测试完成！')
  }

  // 添加测试结果
  addResult(result: string) {
    this.testResults.push(result)
  }

  // 清除测试结果
  clearResults() {
    this.testResults = []
  }
}
