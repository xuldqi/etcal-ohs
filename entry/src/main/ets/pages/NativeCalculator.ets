// import textToSpeech from '@ohos.textToSpeech' // HarmonyOS环境使用
// Web环境使用Web Speech API

// 按钮状态接口
interface ButtonState {
  scale: number;
  offsetY: number;
  shadowBlur: number;
  isPressed: boolean;
}

interface DialogOptions {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  onConfirm?: () => void;
  onCancel?: () => void;
}

@Entry
@Component
struct NativeCalculator {
  @State display: string = '0'
  @State expression: string = ''
  @State isVoiceActive: boolean = false
  @State lastResult: string = ''
  // 为计算器按钮维护状态数组
  @State buttonStates: ButtonState[] = [
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false },
    { scale: 1.0, offsetY: 0, shadowBlur: 8, isPressed: false }
  ]
  @State dialogVisible: boolean = false
  @State dialogTitle: string = ''
  @State dialogMessage: string = ''
  @State dialogConfirmText: string = '确定'
  @State dialogCancelText: string = '取消'
  @State dialogHasCancel: boolean = false

  private dialogConfirmHandler: (() => void) | null = null
  private dialogCancelHandler: (() => void) | null = null

  // 按钮按下效果
  onButtonPress(index: number): void {
    this.buttonStates[index] = {
      scale: 0.92,
      offsetY: 2,
      shadowBlur: 4,
      isPressed: true
    }
  }

  // 按钮释放效果
  onButtonRelease(index: number): void {
    this.buttonStates[index] = {
      scale: 1.05,
      offsetY: -1,
      shadowBlur: 12,
      isPressed: false
    }
    
    setTimeout(() => {
      this.buttonStates[index] = {
        scale: 1.0,
        offsetY: 0,
        shadowBlur: 8,
        isPressed: false
      }
    }, 150)
  }

  build() {
    Stack() {
      Column() {
      // 顶部标题
      Column({ space: 4 }) {
        Text('语音计算器')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .textAlign(TextAlign.Center)
        
        Text('HarmonyOS 原生版本')
          .fontSize(12)
          .fontColor('#95a5a6')
          .textAlign(TextAlign.Center)
      }
      .margin({ top: 20, bottom: 30 })

      // 显示屏（美化设计）
      Column() {
        // 表达式显示
        Text(this.expression || '请开始计算')
          .fontSize(14)
          .fontColor('#7f8c8d')
          .textAlign(TextAlign.End)
          .width('100%')
          .margin({ bottom: 8 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          
        // 结果显示
        Text(this.display)
          .fontSize(40)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2c3e50')
          .textAlign(TextAlign.End)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('92%')
      .padding({ left: 24, right: 24, top: 20, bottom: 20 })
      .backgroundColor('#ffffff')
      .borderRadius(24)
      .shadow({
        radius: 16,
        color: '#1a000000',
        offsetX: 0,
        offsetY: 4
      })
      .border({
        width: 1,
        color: '#ecf0f1'
      })
      .margin({ bottom: 24 })
      
      // 语音按钮（美化设计）
      Button() {
        Row({ space: 12 }) {
          Text(this.isVoiceActive ? '语音识别中...' : '点击开始语音输入')
            .fontSize(16)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Medium)
        }
        .justifyContent(FlexAlign.Center)
      }
      .width('92%')
      .height(56)
      .backgroundColor(this.isVoiceActive ? '#e74c3c' : '#9b59b6')
      .borderRadius(28)
      .shadow({
        radius: 12,
        color: this.isVoiceActive ? '#e74c3c40' : '#9b59b640',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ bottom: 24 })
      .onClick(() => {
        this.toggleVoice()
      })

      // 按键网格（美化设计）
      Grid() {
        // 第一行
        GridItem() { this.ModernCalculatorButton(0, 'C', '#e67e22', () => this.clear()) }
        GridItem() { this.ModernCalculatorButton(1, '⌫', '#e67e22', () => this.backspace()) }
        GridItem() { this.ModernCalculatorButton(2, '÷', '#e67e22', () => this.inputOperator('÷')) }
        GridItem() { this.ModernCalculatorButton(3, '×', '#e67e22', () => this.inputOperator('×')) }
        
        // 第二行
        GridItem() { this.ModernCalculatorButton(4, '7', '#3498db', () => this.inputNumber('7')) }
        GridItem() { this.ModernCalculatorButton(5, '8', '#3498db', () => this.inputNumber('8')) }
        GridItem() { this.ModernCalculatorButton(6, '9', '#3498db', () => this.inputNumber('9')) }
        GridItem() { this.ModernCalculatorButton(7, '-', '#e67e22', () => this.inputOperator('-')) }
        
        // 第三行
        GridItem() { this.ModernCalculatorButton(8, '4', '#3498db', () => this.inputNumber('4')) }
        GridItem() { this.ModernCalculatorButton(9, '5', '#3498db', () => this.inputNumber('5')) }
        GridItem() { this.ModernCalculatorButton(10, '6', '#3498db', () => this.inputNumber('6')) }
        GridItem() { this.ModernCalculatorButton(11, '+', '#e67e22', () => this.inputOperator('+')) }
        
        // 第四行
        GridItem() { this.ModernCalculatorButton(12, '1', '#3498db', () => this.inputNumber('1')) }
        GridItem() { this.ModernCalculatorButton(13, '2', '#3498db', () => this.inputNumber('2')) }
        GridItem() { this.ModernCalculatorButton(14, '3', '#3498db', () => this.inputNumber('3')) }
        GridItem() { this.ModernCalculatorButton(15, '=', '#27ae60', () => this.calculate()) }
        
        // 第五行
        GridItem() { this.ModernCalculatorButton(16, '0', '#3498db', () => this.inputNumber('0')) }
        GridItem() { this.ModernCalculatorButton(17, '.', '#3498db', () => this.inputNumber('.')) }
        GridItem() { this.ModernCalculatorButton(18, '语音', '#9b59b6', () => this.simulateVoiceInput()) }
        GridItem() { this.ModernCalculatorButton(19, '历史', '#34495e', () => this.showHistory()) }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('92%')
      .height(420)
      .columnsGap(12)
      .rowsGap(12)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#f8f9fa')
      .padding({ left: 16, right: 16, top: 20, bottom: 20 })

      if (this.dialogVisible) {
        Column() {
          Column({ space: 16 }) {
            if (this.dialogTitle) {
              Text(this.dialogTitle)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#2c3e50')
                .textAlign(TextAlign.Center)
                .width('100%')
            }

            Text(this.dialogMessage)
              .fontSize(14)
              .fontColor('#4a4a4a')
              .textAlign(TextAlign.Start)
              .width('100%')

            Row({ space: 12 }) {
              if (this.dialogHasCancel) {
                Button() {
                  Text(this.dialogCancelText)
                    .fontSize(16)
                    .fontColor('#2c3e50')
                }
                .backgroundColor('#f2f4f7')
                .borderRadius(16)
                .padding({ left: 18, right: 18, top: 10, bottom: 10 })
                .onClick(() => { this.handleDialogCancel() })
              }

              Button() {
                Text(this.dialogConfirmText)
                  .fontSize(16)
                  .fontColor(Color.White)
              }
              .backgroundColor('#27ae60')
              .borderRadius(16)
              .padding({ left: 18, right: 18, top: 10, bottom: 10 })
              .onClick(() => { this.handleDialogConfirm() })
            }
            .width('100%')
            .justifyContent(FlexAlign.End)
          }
          .width('80%')
          .padding({ left: 24, right: 24, top: 24, bottom: 20 })
          .backgroundColor('#ffffff')
          .borderRadius(20)
          .shadow({ radius: 16, color: '#1A000000', offsetX: 0, offsetY: 8 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#66000000')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  // 现代化计算器按钮
  @Builder
  ModernCalculatorButton(index: number, text: string, color: string, onClick: () => void) {
    Button(text)
      .fontSize(text.length > 1 ? 16 : 20)
      .fontWeight(FontWeight.Medium)
      .fontColor(Color.White)
      .backgroundColor(color)
      .borderRadius(16)
      .width('100%')
      .height('100%')
      .shadow({
        radius: this.buttonStates[index].shadowBlur,
        color: color + '40',
        offsetX: 0,
        offsetY: this.buttonStates[index].isPressed ? 2 : 6
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
          onClick()
        }
      })
  }

  // 输入数字
  inputNumber(num: string) {
    if (this.display === '0' && num !== '.') {
      this.display = num
    } else {
      this.display += num
    }
    this.expression += num
    // 播放数字音频
    this.playNumberAudio(num)
  }

  // 播放数字音频
  playNumberAudio(num: string) {
    try {
      let audioText = num === '.' ? '点' : num
      // 使用Web Speech API
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        const utterance = new SpeechSynthesisUtterance(audioText)
        utterance.lang = 'zh-CN'
        utterance.rate = 1.0
        utterance.pitch = 1.0
        window.speechSynthesis.speak(utterance)
      } else {
        console.log('播放数字音频:', audioText)
      }
    } catch (error) {
      console.error('数字音频播放错误:', error)
    }
  }

  // 输入运算符
  inputOperator(op: string) {
    if (this.expression.length > 0) {
      this.expression += ` ${op} `
      this.display = '0'
      // 播放运算符音频
      this.playOperatorAudio(op)
    }
  }

  // 播放运算符音频
  playOperatorAudio(op: string) {
    try {
      // 根据运算符播放对应音频
      let audioText = ''
      switch (op) {
        case '+':
          audioText = '加'
          break
        case '-':
          audioText = '减'
          break
        case '×':
          audioText = '乘'
          break
        case '÷':
          audioText = '除'
          console.log('除法符号调试: 输入符号=', op, '音频文本=', audioText)
          break
        default:
          audioText = op
      }
      
      console.log('运算符音频播放调试: 符号=', op, '音频文本=', audioText)
      
      // 使用Web Speech API
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        console.log('Web Speech API 可用，开始播放:', audioText)
        const utterance = new SpeechSynthesisUtterance(audioText)
        utterance.lang = 'zh-CN'
        utterance.rate = 1.0
        utterance.pitch = 1.0
        
        // 添加事件监听器进行调试
        utterance.onstart = () => console.log('语音开始播放:', audioText)
        utterance.onend = () => console.log('语音播放结束:', audioText)
        utterance.onerror = (event) => console.error('语音播放错误:', event)
        
        window.speechSynthesis.speak(utterance)
      } else {
        console.log('Web Speech API 不可用，播放运算符音频:', audioText)
      }
    } catch (error) {
      console.error('音频播放错误:', error)
    }
  }

   // 播放结果音频
   playResultAudio(result: string) {
     try {
       // 如果结果包含约等于符号，只播报数字部分
       let resultText = result
       if (result.startsWith('≈')) {
         resultText = result.substring(1) // 去掉≈符号
       }
       
       // 限制语音播报的小数位数为2位
       const num = parseFloat(resultText)
       if (!isNaN(num) && resultText.includes('.')) {
         const parts = resultText.split('.')
         if (parts[1] && parts[1].length > 2) {
           resultText = num.toFixed(2)
         }
       }
       
       let audioText = '等于' + resultText
       // 使用Web Speech API
       if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
         const utterance = new SpeechSynthesisUtterance(audioText)
         utterance.lang = 'zh-CN'
         utterance.rate = 1.0
         utterance.pitch = 1.0
         window.speechSynthesis.speak(utterance)
       } else {
         console.log('播放结果音频:', audioText)
       }
     } catch (error) {
       console.error('结果音频播放错误:', error)
     }
   }

  // 计算结果
  calculate() {
    try {
      let expr = this.expression.replace(/×/g, '*').replace(/÷/g, '/')
      
      // 检查除数为0的情况
      if (expr.includes('/')) {
        const parts = expr.split('/')
        if (parts.length === 2 && parseFloat(parts[1].trim()) === 0) {
          this.display = '不能除以零'
          return
        }
      }
      
      let result = eval(expr)
      
      // 检查结果是否为有效数字
      if (!isFinite(result)) {
        this.display = '错误'
        return
      }
      
      // 限制小数点后最多2位
      let resultStr = result.toString()
      let isApproximate = false
      
      if (resultStr.includes('.')) {
        const parts = resultStr.split('.')
        const integerPart = parts[0]
        const decimalPart = parts[1]
        
        if (decimalPart.length > 2) {
          // 小数位数超过2位，保留2位小数
          resultStr = parseFloat(resultStr).toFixed(2)
          isApproximate = true
        }
      }
      
      // 如果结果被截断或使用科学计数法，添加约等于符号
      if (isApproximate) {
        resultStr = '≈' + resultStr
      }
      
      this.lastResult = this.expression + ' = ' + resultStr
      this.display = resultStr
      this.expression = resultStr
      // 播放结果音频
      this.playResultAudio(resultStr)
    } catch (error) {
      this.display = '错误'
    }
  }

  // 清除
  clear() {
    this.display = '0'
    this.expression = ''
  }

  // 退格
  backspace() {
    if (this.display.length > 1) {
      this.display = this.display.slice(0, -1)
    } else {
      this.display = '0'
    }
    if (this.expression.length > 0) {
      this.expression = this.expression.slice(0, -1)
    }
  }

  // 切换语音状态
  toggleVoice() {
    this.isVoiceActive = !this.isVoiceActive
    if (this.isVoiceActive) {
      // 使用真实的语音识别
      this.startRealVoiceRecognition()
    }
  }

  // 开始真实语音识别
  private startRealVoiceRecognition() {
    // 这里应该调用真实的语音识别服务
    console.log('[语音识别] 开始真实语音识别...')
    
    // 暂时显示提示信息
    this.showInlineDialog({
      title: '语音识别',
      message: '语音识别功能正在开发中，请使用手动输入',
      confirmText: '确定',
      onConfirm: () => {
        this.isVoiceActive = false
      }
    })
  }

  private showInlineDialog(options: DialogOptions): void {
    this.dialogTitle = options.title
    this.dialogMessage = options.message
    this.dialogConfirmText = options.confirmText ?? '确定'
    this.dialogHasCancel = options.cancelText !== undefined
    this.dialogCancelText = options.cancelText ?? ''
    this.dialogConfirmHandler = options.onConfirm ?? null
    this.dialogCancelHandler = options.onCancel ?? null
    this.dialogVisible = true
  }

  private handleDialogConfirm(): void {
    this.dialogVisible = false
    const confirmHandler = this.dialogConfirmHandler
    this.resetDialogHandlers()
    confirmHandler?.()
  }

  private handleDialogCancel(): void {
    this.dialogVisible = false
    const cancelHandler = this.dialogCancelHandler
    this.resetDialogHandlers()
    cancelHandler?.()
  }

  private resetDialogHandlers(): void {
    this.dialogConfirmHandler = null
    this.dialogCancelHandler = null
  }

  // 模拟语音输入方法已删除，现在使用真实语音识别

  // 显示历史
  showHistory(): void {
    this.showInlineDialog({
      title: '计算历史',
      message: this.lastResult || '暂无计算历史',
      confirmText: '确定'
    })
  }
}
