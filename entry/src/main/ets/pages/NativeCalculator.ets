import common from '@ohos.app.ability.common';
import { AudioManager } from '../common/managers/AudioManager';

interface VoiceCommand {
  text: string;
  expression: string;
}

// 简单的数学表达式求值函数，完全符合 ArkTS 的限制
function evaluateExpression(expr: string): number {
  const tokens = expr.split(/\s+/).filter((t: string) => t.length > 0);
  if (tokens.length === 0) {
    return 0;
  }
  const values: number[] = [];
  const ops: string[] = [];

  const hasPrecedence = (op1: string, op2: string): boolean => {
    if (op2 === '(' || op2 === ')') {
      return false;
    }
    if ((op1 === '*' || op1 === '/') && (op2 === '+' || op2 === '-')) {
      return false;
    }
    return true;
  };

  const applyOp = (op: string, b: number, a: number): number => {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '*': return a * b;
      case '/': 
        if (b === 0) {
          throw new Error('Division by zero');
        }
        return a / b;
    }
    return 0;
  };

  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];
    const parsed = Number.parseFloat(token);
    if (!Number.isNaN(parsed)) {
      values.push(parsed);
    } else if (token === '+' || token === '-' || token === '*' || token === '/') {
      while (ops.length > 0 && hasPrecedence(token, ops[ops.length - 1])) {
        const op = ops.pop()!;
        const val2 = values.pop();
        const val1 = values.pop();
        if (val1 !== undefined && val2 !== undefined) {
          values.push(applyOp(op, val2, val1));
        }
      }
      ops.push(token);
    }
  }

  while (ops.length > 0) {
    const op = ops.pop()!;
    const val2 = values.pop();
    const val1 = values.pop();
    if (val1 !== undefined && val2 !== undefined) {
      values.push(applyOp(op, val2, val1));
    }
  }

  return values.length > 0 ? values[0] : 0;
}

@Entry
@Component
struct NativeCalculator {
  @State display: string = '0'
  @State expression: string = ''
  @State isVoiceActive: boolean = false
  @State lastResult: string = ''

  aboutToAppear() {
    AudioManager.getInstance().setContext(getContext(this) as common.UIAbilityContext)
  }

  // 页面隐藏时停止语音播放
  onPageHide() {
    this.stopAllAudio()
  }

  // 页面销毁时停止语音播放
  aboutToDisappear() {
    this.stopAllAudio()
  }

  // 停止所有音频播放
  stopAllAudio() {
    try {
      AudioManager.getInstance().stopSpeaking()
    } catch (error) {
      console.error('停止音频播放失败:', JSON.stringify(error))
    }
  }

  build() {
    Column() {
      // 顶部标题
      Text('🧮 语音计算器')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2196F3')
        .textAlign(TextAlign.Center)
        .margin({ top: 20, bottom: 10 })
      
      Text('HarmonyOS 原生版本')
        .fontSize(14)
        .fontColor('#666')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 30 })

      // 显示屏
      Column() {
        Text(this.expression || '0')
          .fontSize(16)
          .fontColor('#999')
          .textAlign(TextAlign.End)
          .width('100%')
          .margin({ bottom: 10 })
          
        Text(this.display)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333')
          .textAlign(TextAlign.End)
          .width('100%')
      }
      .width('90%')
      .padding(20)
      .backgroundColor('#f8f8f8')
      .borderRadius(15)
      .margin({ bottom: 30 })
      
      // 语音按钮
      Button() {
        Row() {
          Text(this.isVoiceActive ? '🔴' : '🎤')
            .fontSize(20)
            .margin({ right: 8 })
          Text(this.isVoiceActive ? '语音识别中...' : '语音输入')
            .fontSize(16)
            .fontColor(Color.White)
        }
      }
      .width('90%')
      .height(50)
      .backgroundColor(this.isVoiceActive ? '#f44336' : '#9c27b0')
      .borderRadius(25)
      .margin({ bottom: 20 })
      .onClick((): void => {
        this.toggleVoice()
      })

      // 按键网格
      Grid() {
        // 第一行
        GridItem() { this.CalculatorButton('C', '#ff9800', (): void => { this.clear() }) }
        GridItem() { this.CalculatorButton('⌫', '#ff9800', (): void => { this.backspace() }) }
        GridItem() { this.CalculatorButton('÷', '#ff9800', (): void => { this.inputOperator('÷') }) }
        GridItem() { this.CalculatorButton('×', '#ff9800', (): void => { this.inputOperator('×') }) }
        
        // 第二行
        GridItem() { this.CalculatorButton('7', '#2196F3', (): void => { this.inputNumber('7') }) }
        GridItem() { this.CalculatorButton('8', '#2196F3', (): void => { this.inputNumber('8') }) }
        GridItem() { this.CalculatorButton('9', '#2196F3', (): void => { this.inputNumber('9') }) }
        GridItem() { this.CalculatorButton('-', '#ff9800', (): void => { this.inputOperator('-') }) }
        
        // 第三行
        GridItem() { this.CalculatorButton('4', '#2196F3', (): void => { this.inputNumber('4') }) }
        GridItem() { this.CalculatorButton('5', '#2196F3', (): void => { this.inputNumber('5') }) }
        GridItem() { this.CalculatorButton('6', '#2196F3', (): void => { this.inputNumber('6') }) }
        GridItem() { this.CalculatorButton('+', '#ff9800', (): void => { this.inputOperator('+') }) }
        
        // 第四行
        GridItem() { this.CalculatorButton('1', '#2196F3', (): void => { this.inputNumber('1') }) }
        GridItem() { this.CalculatorButton('2', '#2196F3', (): void => { this.inputNumber('2') }) }
        GridItem() { this.CalculatorButton('3', '#2196F3', (): void => { this.inputNumber('3') }) }
        GridItem() { this.CalculatorButton('=', '#4caf50', (): void => { this.calculate() }) }
        
        // 第五行
        GridItem() { this.CalculatorButton('0', '#2196F3', (): void => { this.inputNumber('0') }) }
        GridItem() { this.CalculatorButton('.', '#2196F3', (): void => { this.inputNumber('.') }) }
        GridItem() { this.CalculatorButton('语音', '#9c27b0', (): void => { this.simulateVoiceInput() }) }
        GridItem() { this.CalculatorButton('📊', '#607d8b', (): void => { this.showHistory() }) }
      }
      .columnsTemplate('1fr 1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr 1fr')
      .width('90%')
      .height(400)
      .columnsGap(8)
      .rowsGap(8)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#ffffff')
    .padding(20)
  }

  @Builder
  CalculatorButton(text: string, color: string, onClick: () => void) {
    Button(text)
      .fontSize(18)
      .fontColor(Color.White)
      .backgroundColor(color)
      .borderRadius(8)
      .width('100%')
      .height('100%')
      .onClick(onClick)
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
      AudioManager.getInstance().speakNumber(num)
    } catch (error) {
      console.error('数字音频播放错误:', JSON.stringify(error))
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
      AudioManager.getInstance().speakOperator(op)
    } catch (error) {
      console.error('音频播放错误:', JSON.stringify(error))
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
      const num = Number.parseFloat(resultText)
      if (!Number.isNaN(num) && resultText.includes('.')) {
        const parts = resultText.split('.')
        if (parts[1] && parts[1].length > 2) {
          resultText = num.toFixed(2)
        }
      }
      
      AudioManager.getInstance().speakText('等于' + resultText)
    } catch (error) {
      console.error('结果音频播放错误:', JSON.stringify(error))
    }
  }

  // 计算结果
  calculate() {
    try {
      let expr = this.expression.replace(/×/g, '*').replace(/÷/g, '/')
      
      // 检查除数为0的情况
      if (expr.includes('/')) {
        const parts = expr.split('/')
        if (parts.length === 2 && Number.parseFloat(parts[1].trim()) === 0) {
          this.display = '不能除以零'
          return
        }
      }
      
      let result = evaluateExpression(expr)
      
      // 检查结果是否为有效数字
      if (!Number.isFinite(result)) {
        this.display = '错误'
        return
      }
      
      // 限制小数点后最多2位
      let resultStr = result.toString()
      let isApproximate = false
      
      if (resultStr.includes('.')) {
        const parts = resultStr.split('.')
        const decimalPart = parts[1]
        
        if (decimalPart.length > 2) {
          // 小数位数超过2位，保留2位小数
          resultStr = Number.parseFloat(resultStr).toFixed(2)
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
      // 模拟语音识别
      setTimeout(() => {
        this.isVoiceActive = false
        this.simulateVoiceInput()
      }, 2000)
    }
  }

  // 模拟语音输入
  simulateVoiceInput() {
    const voiceCommands: VoiceCommand[] = [
      { text: '二加三', expression: '2 + 3' },
      { text: '五乘四', expression: '5 × 4' },
      { text: '十减六', expression: '10 - 6' },
      { text: '八除二', expression: '8 ÷ 2' }
    ]
    
    const random = voiceCommands[Math.floor(Math.random() * voiceCommands.length)]
    
    AlertDialog.show({
      title: '语音识别',
      message: `识别到: "${random.text}"\n将输入: ${random.expression}`,
      confirm: {
        value: '确认',
        action: () => {
          this.expression = random.expression
          this.calculate()
        }
      },
      cancel: () => {}
    })
  }

  // 显示历史
  showHistory() {
    AlertDialog.show({
      title: '计算历史',
      message: this.lastResult || '暂无计算历史',
      confirm: {
        value: '确定',
        action: () => {}
      }
    })
  }
}