// 语音管理器 - 处理语音识别功能
import common from '@ohos.app.ability.common'

// 语音状态接口
interface VoiceStatus {
  isListening: boolean
  isEnabled: boolean
  language: string
}

// 语音命令结果接口
interface VoiceCommandResult {
  action: string
  data?: string
}

// 语音识别结果接口
interface VoiceRecognitionResult {
  text: string
  confidence: number
  timestamp: number
}

export class VoiceManager {
  private isEnabled: boolean = true
  private isListening: boolean = false
  private recognitionLanguage: string = 'zh-CN'
  private onResultCallback?: (result: string) => void
  private onErrorCallback?: (error: string) => void
  private onStatusCallback?: (status: string) => void
  private context: common.UIAbilityContext | null = null
  private recognitionTimeout: number = 10000 // 10秒超时
  private asrEngine: object | null = null
  private sessionId: string = ''
  private readonly equalsKeywords: string[] = ['等于几', '等于多少', '是多少', '是几', '多少', '等于什么', '是多少呢']
  private englishNumberMap: Map<string, string> = new Map([
    ['zero', '0'],
    ['one', '1'],
    ['two', '2'],
    ['three', '3'],
    ['four', '4'],
    ['five', '5'],
    ['six', '6'],
    ['seven', '7'],
    ['eight', '8'],
    ['nine', '9'],
    ['ten', '10']
  ])
  private englishOperatorMap: Map<string, string> = new Map([
    ['plus', '+'],
    ['add', '+'],
    ['minus', '-'],
    ['subtract', '-'],
    ['times', '×'],
    ['multiply', '×'],
    ['multipliedby', '×'],
    ['multiplied by', '×'],
    ['dividedby', '÷'],
    ['divided by', '÷'],
    ['divide', '÷'],
    ['over', '÷'],
    ['equals', '='],
    ['equal', '=']
  ])

  constructor() {
    this.initializeVoiceRecognition()
  }

  // 初始化语音识别
  private initializeVoiceRecognition() {
    try {
      this.createSpeechEngine()
      console.log('语音识别管理器初始化完成')
    } catch (error) {
      console.error('语音识别管理器初始化失败:', error)
    }
  }

  // 创建语音识别引擎
  private createSpeechEngine() {
    try {
      this.sessionId = Date.now().toString()
      console.log('语音识别引擎初始化中...')
      console.log('当前使用模拟语音识别模式')
      this.fallbackToSimulation()
    } catch (error) {
      console.error('创建语音识别引擎异常:', error)
      this.fallbackToSimulation()
    }
  }

  // 设置引擎监听器
  private setupEngineListener() {
    if (!this.asrEngine) {
      return
    }
    console.info('模拟模式下跳过语音识别监听器设置')
  }

  // 回退到模拟模式
  private fallbackToSimulation() {
    console.warn('语音识别API不可用，使用模拟模式')
    this.asrEngine = null
  }

  // 设置上下文
  setContext(context: common.UIAbilityContext) {
    this.context = context
    console.info('[语音识别] 已注入UIAbilityContext')
  }

  // 设置语音识别回调
  setCallbacks(
    onResult: (result: string) => void, 
    onError: (error: string) => void,
    onStatus?: (status: string) => void
  ) {
    this.onResultCallback = onResult
    this.onErrorCallback = onError
    this.onStatusCallback = onStatus
  }

  // 开始语音识别
  async startListening() {
    if (!this.isEnabled || this.isListening) {
      return
    }

    try {
      // 检查权限
      const hasPermission = await this.checkMicrophonePermission()
      if (!hasPermission) {
        if (this.onErrorCallback) {
          this.onErrorCallback('需要麦克风权限才能使用语音识别')
        }
        return
      }

      this.sessionId = Date.now().toString()
      this.isListening = true
      console.log('[语音识别] 开始听取...')
      
      // 如果有真实的语音识别引擎，使用真实API
      if (this.asrEngine) {
        this.startRealVoiceRecognition()
      } else {
        // 否则使用模拟模式
        this.enhancedSimulateVoiceRecognition()
      }
    } catch (error) {
      console.error('启动语音识别失败:', error)
      this.isListening = false
      if (this.onErrorCallback) {
        this.onErrorCallback('启动语音识别失败')
      }
    }
  }

  // 开始真实语音识别
  private startRealVoiceRecognition() {
    console.log('真实语音识别功能待实现，使用模拟模式')
    this.enhancedSimulateVoiceRecognition()
  }

  // 停止语音识别
  stopListening() {
    if (!this.isListening) {
      return
    }

    try {
      this.isListening = false
      console.log('[语音识别] 停止听取')
      
      // 模拟模式无需额外处理
    } catch (error) {
      console.error('停止语音识别失败:', error)
    }
  }

  // 检查麦克风权限
  private async checkMicrophonePermission(): Promise<boolean> {
    console.log('[权限] 模拟麦克风权限检查')
    return true
  }

  private async requestMicrophonePermission(): Promise<boolean> {
    console.log('[权限] 模拟麦克风权限请求')
    return true
  }

  // 智能生成数学表达式
  private generateSmartMathExpression(): string {
    const numbers = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九', '十']
    const operators = ['加', '减', '乘', '除']
    const symbols = ['+', '-', '×', '÷']
    
    // 随机选择数字和运算符
    const num1 = numbers[Math.floor(Math.random() * 11)]
    const num2 = numbers[Math.floor(Math.random() * 11)]
    const operator = operators[Math.floor(Math.random() * 4)]
    const symbol = symbols[Math.floor(Math.random() * 4)]
    
    // 随机选择表达格式
    const formats = [
      `${num1}${operator}${num2}`,           // 中文格式：二加三
      `${num1}${symbol}${num2}`,             // 符号格式：二+三
      `${num1}${operator}${num2}等于`,       // 带等于：二加三等于
      `${num1}${symbol}${num2}=`,            // 符号带等于：二+三=
      `${num1}${operator}${num2}等于多少`,   // 问句格式：二加三等于多少
    ]
    
    return formats[Math.floor(Math.random() * formats.length)]
  }

  // 增强的模拟语音识别（用于演示）
  private enhancedSimulateVoiceRecognition() {
    // 模拟语音识别过程，包含更多状态反馈
    let progress = 0
    const progressInterval = setInterval(() => {
      if (!this.isListening) {
        clearInterval(progressInterval)
        return
      }

      progress += 15
      if (this.onStatusCallback) {
        if (progress < 100) {
          this.onStatusCallback(`正在识别中... ${progress}%`)
        }
      }
    }, 400)

    // 模拟识别结果
    setTimeout(() => {
      if (this.isListening) {
        clearInterval(progressInterval)
        
        // 智能生成数学表达式
        const randomResult = this.generateSmartMathExpression()
        console.log(`[语音识别] 识别结果: ${randomResult}`)
        
        if (this.onStatusCallback) {
          this.onStatusCallback(`识别成功: "${randomResult}"`)
        }
        
        if (this.onResultCallback) {
          this.onResultCallback(randomResult)
        }
        
        this.isListening = false
        
        // 3秒后重置状态
        setTimeout(() => {
          if (this.onStatusCallback) {
            this.onStatusCallback('点击语音按钮开始语音计算')
          }
        }, 3000)
      }
    }, 2000) // 模拟2秒识别时间

    // 设置超时
    setTimeout(() => {
      if (this.isListening) {
        clearInterval(progressInterval)
        this.isListening = false
        if (this.onErrorCallback) {
          this.onErrorCallback('识别超时，请重新尝试')
        }
        if (this.onStatusCallback) {
          this.onStatusCallback('识别超时，请重新尝试')
        }
      }
    }, this.recognitionTimeout)
  }

  // 模拟语音识别（用于演示）
  private simulateVoiceRecognition() {
    // 保持向后兼容
    this.enhancedSimulateVoiceRecognition()
  }

  // 处理语音识别结果
  processVoiceInput(transcript: string): string | null {
    try {
      if (!transcript) {
        return null
      }

      let expression = transcript
        .replace(/[，。！？,!?]/g, ' ')
        .replace(/多少/g, '')
        .replace(/哦|啊|呢/g, '')

      this.englishNumberMap.forEach((value: string, key: string) => {
        const regex = new RegExp(`\\b${key}\\b`, 'ig')
        expression = expression.replace(regex, ` ${value} `)
      })

      this.englishOperatorMap.forEach((value: string, key: string) => {
        const regex = new RegExp(`\\b${key}\\b`, 'ig')
        expression = expression.replace(regex, ` ${value} `)
      })

      // 清理和标准化语音输入
      expression = expression
        .replace(/加上|加/g, '+')
        .replace(/减去|减/g, '-')
        .replace(/乘以|乘|乘上/g, '×')
        .replace(/除以|除|除于/g, '÷')
        .replace(/等于/g, '=')
        .replace(/[零〇]/g, '0')
        .replace(/[一壹]/g, '1')
        .replace(/[二贰]/g, '2')
        .replace(/[三叁]/g, '3')
        .replace(/[四肆]/g, '4')
        .replace(/[五伍]/g, '5')
        .replace(/[六陆]/g, '6')
        .replace(/[七柒]/g, '7')
        .replace(/[八捌]/g, '8')
        .replace(/[九玖]/g, '9')
        .replace(/[十拾]/g, '10')
        .replace(/二十/g, '20')
        .replace(/三十/g, '30')
        .replace(/四十/g, '40')
        .replace(/五十/g, '50')
        .replace(/六十/g, '60')
        .replace(/七十/g, '70')
        .replace(/八十/g, '80')
        .replace(/九十/g, '90')
        .replace(/一百/g, '100')
        .replace(/点/g, '.')

      // 清理多余空格
      expression = expression
        .replace(/([+\-×÷=])/g, ' $1 ')
        .replace(/\s+/g, ' ')
        .trim()

      // 验证表达式
      if (/^[0-9+\-×÷=\s.()]+$/.test(expression) && /\d/.test(expression)) {
        return expression
      }

      return null
    } catch (error) {
      console.error('处理语音输入失败:', error)
      return null
    }
  }

  // 检查语音识别是否可用
  isVoiceRecognitionAvailable(): boolean {
    try {
      // 检查是否有真实的语音识别引擎
      if (this.asrEngine) {
        console.log('真实语音识别引擎可用')
        return true
      } else {
        console.log('使用模拟语音识别模式')
        return true // 模拟模式总是可用
      }
    } catch (error) {
      console.error('语音识别服务检查失败:', error)
      return false
    }
  }

  // 设置识别语言
  setLanguage(language: string) {
    this.recognitionLanguage = language
    console.log(`[语音识别] 设置语言: ${language}`)
  }

  // 启用/禁用语音识别
  setEnabled(enabled: boolean) {
    this.isEnabled = enabled
    if (!enabled && this.isListening) {
      this.stopListening()
    }
  }

  // 获取当前状态
  getStatus(): VoiceStatus {
    return {
      isListening: this.isListening,
      isEnabled: this.isEnabled,
      language: this.recognitionLanguage
    }
  }

  // 处理语音命令
  processVoiceCommand(command: string): VoiceCommandResult | null {
    const lowerCommand = command.toLowerCase()

    // 计算命令
    if (lowerCommand.includes('计算') || lowerCommand.includes('算')) {
      const expression = this.processVoiceInput(command)
      if (expression) {
        return { action: 'calculate', data: expression }
      }
    }

    // 清除命令
    if (lowerCommand.includes('清除') || lowerCommand.includes('清零')) {
      return { action: 'clear', data: undefined }
    }

    // 帮助命令
    if (lowerCommand.includes('帮助') || lowerCommand.includes('怎么用')) {
      return { action: 'help', data: undefined }
    }

    // 设置命令
    if (lowerCommand.includes('设置') || lowerCommand.includes('配置')) {
      return { action: 'settings', data: undefined }
    }

    return null
  }

  // 获取语音提示
  getVoicePrompt(): string {
    const prompts = [
      '请说出您要计算的数学表达式',
      '请说出计算题目',
      '请用语音输入数学表达式',
      '请说出要计算的数字和运算符'
    ]

    return prompts[Math.floor(Math.random() * prompts.length)]
  }

  // 获取错误提示
  getErrorPrompt(error: string): string {
    const errorPrompts = new Map<string, string>()
    errorPrompts.set('no_match', '抱歉，没有听清楚，请重新说一遍')
    errorPrompts.set('network', '网络连接失败，请检查网络后重试')
    errorPrompts.set('permission', '需要语音权限，请在设置中开启')
    errorPrompts.set('timeout', '识别超时，请重新尝试')
    errorPrompts.set('default', '语音识别出现错误，请重试')

    return errorPrompts.get(error) || errorPrompts.get('default') || '语音识别出现错误，请重试'
  }

  // 获取成功提示
  getSuccessPrompt(result: string): string {
    return `识别成功：${result}`
  }

  // 检查语音中是否包含等于类问题
  isEqualsQuery(transcript: string): boolean {
    if (!transcript) {
      return false
    }
    return this.equalsKeywords.some(keyword => transcript.includes(keyword))
  }

}
