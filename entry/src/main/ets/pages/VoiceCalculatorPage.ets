import { AudioManager } from '../managers/AudioManager'
import { UnifiedHeader } from '../components/UnifiedHeader'
import { VoiceManager } from '../managers/VoiceManager'
import { StorageManager } from '../managers/StorageManager'
import common from '@ohos.app.ability.common'

interface VoiceCommand {
  text: string
  expression: string
}

interface DialogOptions {
  title: string
  message: string
  confirmText?: string
  cancelText?: string
  onConfirm?: () => void
  onCancel?: () => void
}

@Component
export struct VoiceCalculatorPage {
  onNavigate: (page: string) => void = () => {}
  @Prop appState: object
  setAppState: (state: object) => void = () => {}

  @State display: string = '0'
  @State expression: string = ''
  @State isListening: boolean = false
  @State voiceStatus: string = '点击语音按钮开始语音计算'
  @State voiceResult: string = ''
  @State lastResult: string = ''
  @State errorMessage: string = ''
  @State showError: boolean = false
  @State previousValue: number | null = null
  @State currentOperation: string | null = null
  @State waitingForOperand: boolean = false
  @State calculationHistory: string[] = []
  @State isVoiceSupported: boolean = true
  @State dialogVisible: boolean = false
  @State dialogTitle: string = ''
  @State dialogMessage: string = ''
  @State dialogConfirmText: string = '确定'
  @State dialogCancelText: string = '取消'
  @State dialogHasCancel: boolean = false

  private audioManager: AudioManager = new AudioManager()
  private voiceManager: VoiceManager = new VoiceManager()
  private storageManager: StorageManager = StorageManager.getInstance()
  private pendingTimers: number[] = []
  private dialogConfirmHandler: (() => void) | null = null
  private dialogCancelHandler: (() => void) | null = null
  private abilityContext: common.UIAbilityContext | null = null

  aboutToAppear() {
    this.initializeManagers()
  }

  aboutToDisappear() {
    this.cleanup()
    this.voiceManager.stopListening()
  }

  private initializeManagers(): void {
    try {
      if (!this.abilityContext) {
        try {
          this.abilityContext = (getContext(this) as common.UIAbilityContext) ?? null
          if (this.abilityContext) {
            this.voiceManager.setContext(this.abilityContext)
            void this.storageManager.init(this.abilityContext)
          } else {
            console.warn('无法获取 UIAbilityContext，语音权限请求可能失败')
          }
        } catch (error) {
          console.error('获取UIAbilityContext失败:', error)
        }
      } else {
        this.voiceManager.setContext(this.abilityContext)
        void this.storageManager.init(this.abilityContext)
      }

      this.voiceManager.setCallbacks(
        (result: string) => this.handleVoiceResult(result),
        (error: string) => this.handleVoiceError(error),
        (status: string) => this.handleVoiceStatus(status)
      )
      this.isVoiceSupported = this.voiceManager.isVoiceRecognitionAvailable()
      this.loadCalculationHistory()
      console.log('语音计算器管理器初始化完成')
    } catch (error) {
      console.error('语音计算器管理器初始化失败:', error)
      this.showErrorMessage('初始化失败，请重启应用')
    }
  }

  private cleanup(): void {
    this.clearPendingTimers()
    this.audioManager.stopSpeaking()
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

  private loadCalculationHistory(): void {
    this.storageManager.loadCalculationHistory()
      .then((history: string[]) => {
        if (history && history.length > 0) {
          this.calculationHistory = history
          this.lastResult = history[0]
        }
      })
      .catch((error: Error) => {
        console.error('加载计算历史失败:', error)
      })
  }

  private handleVoiceResult(result: string): void {
    try {
      console.log('语音识别结果:', result)
      this.isListening = false

      const processedExpression = this.voiceManager.processVoiceInput(result)
      if (!processedExpression) {
        this.voiceResult = ''
        this.voiceStatus = `未能识别: "${result}"`
        this.showErrorMessage('无法识别表达式，请重新尝试')
        return
      }

      const equalsQuery = this.voiceManager.isEqualsQuery(result)
      const cleanedExpression = processedExpression.replace(/\s+/g, ' ').trim()

      this.voiceResult = `识别: ${cleanedExpression}`
      this.voiceStatus = equalsQuery
        ? '识别到等于类问题，正在计算答案...'
        : `识别成功: "${result}"`

      this.handleVoiceExpression(cleanedExpression, result, equalsQuery)
    } catch (error) {
      console.error('处理语音结果失败:', error)
      this.showErrorMessage('处理语音结果失败')
    }
  }

  private handleVoiceExpression(expression: string, originalTranscript: string, equalsQuery: boolean): void {
    if (!expression) {
      this.showErrorMessage('没有可计算的表达式')
      return
    }

    const parts: string[] = expression.split('=')
    const coreExpression: string = parts[0]?.trim() || ''
    const hasEquals: boolean = expression.includes('=')

    if (coreExpression.length === 0) {
      this.showErrorMessage('表达式为空，请重试')
      return
    }

    if (hasEquals || equalsQuery) {
      this.computeVoiceExpression(coreExpression, equalsQuery)
    } else {
      this.populateCalculatorFromExpression(coreExpression)
      this.voiceStatus = this.voiceManager.getSuccessPrompt(coreExpression)
      this.voiceResult = `识别: ${this.normalizeExpressionForDisplay(coreExpression)}`
      this.clearVoiceResultLater(2500)
    }
  }

  private computeVoiceExpression(expression: string, equalsQuery: boolean): void {
    const sanitized: string = expression.replace(/\s+/g, '')
    if (sanitized.length === 0) {
      this.showErrorMessage('表达式为空，请重试')
      return
    }

    const result: number = this.evaluateExpression(sanitized)
    if (!isFinite(result)) {
      this.showErrorMessage('计算失败，请检查表达式')
      return
    }

    const displayExpression: string = this.normalizeExpressionForDisplay(expression)
    const formattedResult: string = this.formatResult(result)

    this.display = formattedResult
    this.expression = `${displayExpression} =`
    this.previousValue = null
    this.currentOperation = null
    this.waitingForOperand = true
    this.voiceStatus = this.voiceManager.getSuccessPrompt(displayExpression)
    this.voiceResult = `识别: ${displayExpression} =`
    this.clearVoiceResultLater()

    this.appendHistory(displayExpression, formattedResult)
    this.playResultAudio(formattedResult, equalsQuery)
  }

  private populateCalculatorFromExpression(expression: string): void {
    this.resetCalculatorState()
    const tokens: string[] = this.tokenizeExpression(expression)

    if (tokens.length === 0) {
      return
    }

    tokens.forEach((token: string) => {
      if (this.isOperatorToken(token)) {
        this.inputOperator(token, true)
      } else {
        this.inputNumber(token, true, true)
      }
    })

    this.expression = this.normalizeExpressionForDisplay(expression)
    this.updateExpressionPreview()
  }

  private tokenizeExpression(expression: string): string[] {
    const sanitized: string = expression.replace(/\s+/g, '')
    const tokens: string[] = []
    const regex: RegExp = /(\d+\.?\d*)|[+\-×÷]/g
    let match: RegExpExecArray | null

    while ((match = regex.exec(sanitized)) !== null) {
      tokens.push(match[0])
    }

    return this.mergeNegativeNumbers(tokens)
  }

  private mergeNegativeNumbers(tokens: string[]): string[] {
    if (tokens.length === 0) {
      return []
    }

    const merged: string[] = []
    for (let i = 0; i < tokens.length; i++) {
      const token: string = tokens[i]
      if (token === '-' && (i === 0 || this.isOperatorToken(tokens[i - 1]))) {
        const nextToken: string | undefined = tokens[i + 1]
        if (nextToken !== undefined) {
          merged.push((-parseFloat(nextToken)).toString())
          i++
          continue
        }
      }
      merged.push(token)
    }

    return merged
  }

  private isOperatorToken(token: string): boolean {
    return token === '+' || token === '-' || token === '×' || token === '÷'
  }

  private evaluateExpression(expression: string): number {
    const tokens: string[] = this.tokenizeExpression(expression)
    if (tokens.length === 0) {
      return NaN
    }

    const stack: (number | string)[] = []
    let index: number = 0

    while (index < tokens.length) {
      const token: string = tokens[index]
      if (token === '×' || token === '÷') {
        const previous: number | string | undefined = stack.pop()
        const nextToken: string | undefined = tokens[index + 1]

        if (previous === undefined || nextToken === undefined) {
          return NaN
        }

        const previousValue: number = typeof previous === 'number' ? previous : parseFloat(previous)
        const nextValue: number = parseFloat(nextToken)

        if (isNaN(previousValue) || isNaN(nextValue)) {
          return NaN
        }

        if (token === '÷' && nextValue === 0) {
          return Infinity
        }

        const computed: number = token === '×' ? previousValue * nextValue : previousValue / nextValue
        stack.push(computed)
        index += 2
        continue
      }

      stack.push(!isNaN(parseFloat(token)) ? parseFloat(token) : token)
      index++
    }

    if (stack.length === 0) {
      return NaN
    }

    let result: number = typeof stack[0] === 'number' ? stack[0] : parseFloat(stack[0] as string)
    if (isNaN(result)) {
      return NaN
    }

    for (let i = 1; i < stack.length; i += 2) {
      const operator: string = stack[i] as string
      const operandToken: number | string | undefined = stack[i + 1]
      if (operandToken === undefined) {
        return result
      }

      const operand: number = typeof operandToken === 'number'
        ? operandToken
        : parseFloat(operandToken)

      if (isNaN(operand)) {
        return NaN
      }

      if (operator === '+') {
        result += operand
      } else if (operator === '-') {
        result -= operand
      } else {
        return NaN
      }
    }

    return result
  }

  private formatResult(value: number): string {
    if (!isFinite(value)) {
      return '错误'
    }

    if (Number.isInteger(value)) {
      return value.toString()
    }

    return value.toFixed(2).replace(/\.?0+$/, '')
  }

  private normalizeExpressionForDisplay(expression: string): string {
    return expression
      .replace(/\*/g, '×')
      .replace(/\//g, '÷')
      .replace(/([+\-×÷])/g, ' $1 ')
      .replace(/\s+/g, ' ')
      .trim()
  }

  private formatNumberForExpression(value: number): string {
    return Number.isInteger(value)
      ? value.toString()
      : value.toFixed(2).replace(/\.?0+$/, '')
  }

  private formatDisplayText(value: string): string {
    const numeric: number = parseFloat(value)
    if (isNaN(numeric)) {
      return value
    }
    return Number.isInteger(numeric)
      ? numeric.toString()
      : numeric.toFixed(2).replace(/\.?0+$/, '')
  }

  private updateExpressionPreview(): void {
    if (this.currentOperation && this.previousValue !== null) {
      if (this.waitingForOperand) {
        this.expression = `${this.formatNumberForExpression(this.previousValue)} ${this.currentOperation}`
      } else {
        this.expression = `${this.formatNumberForExpression(this.previousValue)} ${this.currentOperation} ${this.formatDisplayText(this.display)}`
      }
    } else {
      this.expression = this.formatDisplayText(this.display)
    }
  }

  private appendHistory(expression: string, result: string): void {
    const entry: string = `${expression} = ${result}`
    const updated: string[] = [entry, ...this.calculationHistory].slice(0, 20)
    this.calculationHistory = updated
    this.lastResult = entry

    this.storageManager.saveCalculationHistory(updated)
      .catch((error: Error) => {
        console.error('[存储] 保存计算历史失败:', error)
      })
  }

  private addPendingTimer(timer: number): void {
    this.pendingTimers.push(timer)
  }

  private clearPendingTimers(): void {
    this.pendingTimers.forEach((timer: number) => {
      clearTimeout(timer)
    })
    this.pendingTimers = []
  }

  private clearVoiceResultLater(delay: number = 3000): void {
    const timer: number = setTimeout(() => {
      this.voiceResult = ''
    }, delay)
    this.addPendingTimer(timer)
  }

  private playResultAudio(result: string, skipEqualsCue: boolean = false): void {
    try {
      const sanitizedResult: string = result.startsWith('≈') ? result.substring(1) : result

      if (skipEqualsCue) {
        const timer: number = setTimeout(() => {
          this.audioManager.speakNumber(sanitizedResult)
        }, 200)
        this.addPendingTimer(timer)
      } else {
        this.playOperatorAudio('=')
        const timer: number = setTimeout(() => {
          this.audioManager.speakNumber(sanitizedResult)
        }, 600)
        this.addPendingTimer(timer)
      }
    } catch (error) {
      console.error('结果音频播放错误:', error)
    }
  }

  private playNumberAudio(num: string): void {
    try {
      this.audioManager.speakNumber(num)
    } catch (error) {
      console.error('数字音频播放错误:', error)
    }
  }

  private playOperatorAudio(op: string): void {
    try {
      this.audioManager.speakOperator(op)
    } catch (error) {
      console.error('运算符音频播放错误:', error)
    }
  }

  private playDeleteAudio(): void {
    try {
      this.audioManager.speakText('删除')
    } catch (error) {
      console.error('删除音频播放错误:', error)
    }
  }

  private showErrorMessage(message: string): void {
    this.errorMessage = message
    this.showError = true
    const timer: number = setTimeout(() => {
      this.showError = false
    }, 3000)
    this.addPendingTimer(timer)
  }

  private handleVoiceError(error: string): void {
    console.error('语音识别错误:', error)
    this.isListening = false
    this.showErrorMessage(error)
    this.voiceStatus = '点击语音按钮开始语音计算'
  }

  private handleVoiceStatus(status: string): void {
    this.voiceStatus = status
  }

  private resetCalculatorState(): void {
    this.display = '0'
    this.expression = ''
    this.previousValue = null
    this.currentOperation = null
    this.waitingForOperand = false
  }

  async toggleVoiceRecognition(): Promise<void> {
    if (!this.isVoiceSupported) {
      this.showErrorMessage('当前设备暂不支持语音识别，使用模拟演示')
      this.simulateVoiceInput()
      return
    }

    if (this.isListening) {
      this.voiceManager.stopListening()
      this.isListening = false
      this.voiceStatus = '点击语音按钮开始语音计算'
      return
    }

    try {
      this.isListening = true
      this.voiceResult = ''
      this.voiceStatus = this.voiceManager.getVoicePrompt()
      await this.voiceManager.startListening()
    } catch (error) {
      console.error('启动语音识别失败:', error)
      this.isListening = false
      this.showErrorMessage('启动语音识别失败')
    }
  }

  private simulateVoiceInput(): void {
    const voiceCommands: VoiceCommand[] = [
      { text: '二加三等于几', expression: '2 + 3 =' },
      { text: '五乘四等于多少', expression: '5 × 4 =' },
      { text: '十减六', expression: '10 - 6' },
      { text: '八除以二等于多少', expression: '8 ÷ 2 =' }
    ]

    const random: VoiceCommand = voiceCommands[Math.floor(Math.random() * voiceCommands.length)]

    this.showInlineDialog({
      title: '语音识别',
      message: `识别到: "${random.text}"\n将输入: ${random.expression}`,
      confirmText: '确认',
      cancelText: '取消',
      onConfirm: () => {
        const equalsQuery: boolean = random.expression.includes('=')
        this.handleVoiceExpression(random.expression, random.text, equalsQuery)
      }
    })
  }

  inputNumber(num: string, silent: boolean = false, replaceCurrent: boolean = false): void {
    if (!replaceCurrent && num === '.' && this.display.includes('.')) {
      return
    }

    if (replaceCurrent) {
      this.display = num
      this.waitingForOperand = false
    } else if (this.waitingForOperand) {
      this.display = num === '.' ? '0.' : num
      this.waitingForOperand = false
    } else if (this.display === '0' && num !== '.') {
      this.display = num
    } else if (this.display === '-0' && num !== '.') {
      this.display = '-' + num
    } else if ((this.display === '0' || this.display === '-0') && num === '.') {
      this.display = this.display === '-0' ? '-0.' : '0.'
    } else {
      this.display = this.display + num
    }

    this.updateExpressionPreview()

    if (!silent) {
      this.playNumberAudio(num)
    }
  }

  inputOperator(op: string, silent: boolean = false): void {
    const inputValue: number = parseFloat(this.display)
    if (isNaN(inputValue)) {
      return
    }

    if (this.previousValue === null) {
      this.previousValue = inputValue
    } else if (this.currentOperation && !this.waitingForOperand) {
      const newValue: number = this.calculateValues(this.previousValue, inputValue, this.currentOperation)
      if (!isFinite(newValue)) {
        this.showErrorMessage('计算失败，请检查输入')
        return
      }
      this.previousValue = newValue
      this.display = this.formatResult(newValue)
    }

    this.currentOperation = op
    this.waitingForOperand = true
    this.updateExpressionPreview()

    if (!silent) {
      this.playOperatorAudio(op)
    }
  }

  private calculateValues(first: number, second: number, operation: string): number {
    switch (operation) {
      case '+':
        return first + second
      case '-':
        return first - second
      case '×':
        return first * second
      case '÷':
        return second === 0 ? Infinity : first / second
      default:
        return second
    }
  }

  calculate(playAudio: boolean = true): void {
    if (this.previousValue === null || !this.currentOperation) {
      return
    }

    const inputValue: number = parseFloat(this.display)
    if (isNaN(inputValue)) {
      return
    }

    const result: number = this.calculateValues(this.previousValue, inputValue, this.currentOperation)
    if (!isFinite(result)) {
      this.showErrorMessage('不能除以零')
      return
    }

    const formattedResult: string = this.formatResult(result)
    const expressionDisplay: string = `${this.formatNumberForExpression(this.previousValue)} ${this.currentOperation} ${this.formatDisplayText(this.display)}`

    this.display = formattedResult
    this.expression = `${expressionDisplay} =`
    this.previousValue = null
    this.currentOperation = null
    this.waitingForOperand = true
    this.lastResult = `${expressionDisplay} = ${formattedResult}`

    this.appendHistory(expressionDisplay, formattedResult)

    if (playAudio) {
      this.playResultAudio(formattedResult, false)
    }
  }

  calculateResult(): void {
    this.calculate()
  }

  clear(): void {
    this.resetCalculatorState()
    this.voiceResult = ''
    this.voiceStatus = '点击语音按钮开始语音计算'
    this.audioManager.speakText('已清除')
  }

  backspace(): void {
    if (this.waitingForOperand) {
      this.display = '0'
      this.waitingForOperand = false
    } else if (this.display.length > 1) {
      this.display = this.display.slice(0, -1)
    } else {
      this.display = '0'
    }

    this.updateExpressionPreview()
    this.playDeleteAudio()
  }

  toggleSign(): void {
    const numeric: number = parseFloat(this.display)
    if (isNaN(numeric)) {
      return
    }
    const toggled: string = (-numeric).toString()
    this.display = toggled
    this.waitingForOperand = false
    this.updateExpressionPreview()
  }

  applyPercent(): void {
    const numeric: number = parseFloat(this.display)
    if (isNaN(numeric)) {
      return
    }

    const percentValue: number = numeric / 100
    const percentText: string = this.formatResult(percentValue)
    this.display = percentText
    this.waitingForOperand = false
    this.updateExpressionPreview()
  }

  showHistory(): void {
    const message: string = this.calculationHistory.length > 0
      ? this.calculationHistory.slice(0, 10).join('\n')
      : '暂无计算历史'

    this.showInlineDialog({
      title: '计算历史',
      message,
      confirmText: '确定'
    })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [['#FFF7F9', 0.0], ['#FFFCFD', 1.0]]
        })

      Column({ space: 16 }) {
        // 统一标题栏
        UnifiedHeader({
          title: '语音计算器',
          onBack: () => { this.onNavigate('home') }
        })

        if (this.voiceStatus !== '点击语音按钮开始语音计算') {
          Text(this.voiceStatus)
            .fontSize(14)
            .fontColor('#34495E')
            .textAlign(TextAlign.Center)
            .width('90%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#E8F4FD')
            .borderRadius(15)
        }

        if (this.showError) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF4757')
            .textAlign(TextAlign.Center)
            .width('90%')
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('#FFE4E6')
            .borderRadius(15)
            .border({
              width: 1,
              color: '#FF4757'
            })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut
            })
        }

        if (this.voiceResult) {
          Text(this.voiceResult)
            .fontSize(14)
            .fontColor('#2C7A4B')
            .textAlign(TextAlign.Center)
            .width('90%')
            .padding({ left: 16, right: 16, top: 10, bottom: 10 })
            .backgroundColor('#E4F6EC')
            .borderRadius(15)
        }

        Column() {
          if (this.expression) {
            Text(this.expression)
              .fontSize(16)
              .fontColor('#7F8C8D')
              .textAlign(TextAlign.End)
              .width('100%')
              .padding({ right: 20, top: 8 })
          }
          
          Text(this.display)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#2C3E50')
            .textAlign(TextAlign.End)
            .width('100%')
            .padding({ right: 20, bottom: 8 })
        }
        .width('90%')
        .height(200)
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
        .justifyContent(FlexAlign.Center)
        .shadow({
          radius: 8,
          color: '#FFB6C120',
          offsetX: 0,
          offsetY: 4
        })
        .margin({ top: 8, bottom: 8 })

        Row({ space: 14 }) {
          this.UtilityButton(
            this.isListening ? '正在聆听...' : '语音输入',
            this.isListening ? '#FFE8EA' : '#EEF1FF',
            () => { this.toggleVoiceRecognition() },
            this.isListening ? '#E53935' : '#3455D1'
          )
          this.UtilityButton(
            '历史记录',
            '#EEF8F2',
            () => this.showHistory(),
            '#2C7A4B'
          )
        }
        .width('90%')
        .margin({ top: 12 })

        Column({ space: 12 }) {
          Row({ space: 12 }) {
            this.CalculatorButton('C', '#FDEBEC', () => this.clear(), '#E86464')
            this.CalculatorButton('±', '#FDEBEC', () => this.toggleSign(), '#E86464')
            this.CalculatorButton('%', '#FDEBEC', () => this.applyPercent(), '#E86464')
            this.CalculatorButton('÷', '#FFECD6', () => this.inputOperator('÷'), '#DA8A00')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.CalculatorButton('7', '#F7F7F9', () => this.inputNumber('7'))
            this.CalculatorButton('8', '#F7F7F9', () => this.inputNumber('8'))
            this.CalculatorButton('9', '#F7F7F9', () => this.inputNumber('9'))
            this.CalculatorButton('×', '#FFECD6', () => this.inputOperator('×'), '#DA8A00')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.CalculatorButton('4', '#F7F7F9', () => this.inputNumber('4'))
            this.CalculatorButton('5', '#F7F7F9', () => this.inputNumber('5'))
            this.CalculatorButton('6', '#F7F7F9', () => this.inputNumber('6'))
            this.CalculatorButton('-', '#FFECD6', () => this.inputOperator('-'), '#DA8A00')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.CalculatorButton('1', '#F7F7F9', () => this.inputNumber('1'))
            this.CalculatorButton('2', '#F7F7F9', () => this.inputNumber('2'))
            this.CalculatorButton('3', '#F7F7F9', () => this.inputNumber('3'))
            this.CalculatorButton('+', '#FFECD6', () => this.inputOperator('+'), '#DA8A00')
          }
          .width('100%')

          Row({ space: 12 }) {
            this.CalculatorButton('0', '#F7F7F9', () => this.inputNumber('0'), '#2C3E50', 2)
            this.CalculatorButton('.', '#F7F7F9', () => this.inputNumber('.'))
            this.CalculatorButton('=', '#FF9500', () => this.calculate(), '#FFFFFF')
          }
          .width('100%')
        }
        .width('90%')
      .margin({ top: 16 })
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 0, bottom: 40 })

    if (this.dialogVisible) {
      Column() {
        Column({ space: 16 }) {
          if (this.dialogTitle) {
            Text(this.dialogTitle)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
      .fontColor('#2C3E50')
              .textAlign(TextAlign.Center)
              .width('100%')
          }

          Text(this.dialogMessage)
            .fontSize(14)
            .fontColor('#4A4A4A')
            .textAlign(TextAlign.Start)
            .width('100%')

          Row({ space: 12 }) {
            if (this.dialogHasCancel) {
              Button() {
                Text(this.dialogCancelText)
                  .fontSize(16)
                  .fontColor('#2C3E50')
              }
              .backgroundColor('#F2F4F7')
              .borderRadius(16)
              .padding({ left: 18, right: 18, top: 10, bottom: 10 })
              .onClick(() => { this.handleDialogCancel() })
            }

            Button() {
              Text(this.dialogConfirmText)
                .fontSize(16)
                .fontColor(Color.White)
            }
            .backgroundColor('#FF6B9D')
            .borderRadius(16)
            .padding({ left: 18, right: 18, top: 10, bottom: 10 })
            .onClick(() => { this.handleDialogConfirm() })
          }
          .width('100%')
          .justifyContent(FlexAlign.End)
        }
        .width('80%')
        .padding({ left: 24, right: 24, top: 24, bottom: 20 })
        .backgroundColor('#FFFFFF')
        .borderRadius(24)
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

  @Builder
  CalculatorButton(label: string, backgroundColor: string, onClick: () => void, textColor: string = '#2C3E50', weight: number = 1) {
    Button() {
      Text(label)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(62)
    .layoutWeight(weight)
    .borderRadius(18)
    .backgroundColor(backgroundColor)
    .shadow({ radius: 12, color: '#1A000000', offsetX: 0, offsetY: 6 })
    .onClick(() => { onClick() })
  }

  @Builder
  UtilityButton(label: string, backgroundColor: string, onClick: () => void, textColor: string = '#2C3E50') {
    Button() {
      Text(label)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(textColor)
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .height(50)
    .layoutWeight(1)
    .borderRadius(16)
    .backgroundColor(backgroundColor)
    .shadow({ radius: 8, color: '#14000000', offsetX: 0, offsetY: 4 })
    .onClick(() => { onClick() })
  }
}
