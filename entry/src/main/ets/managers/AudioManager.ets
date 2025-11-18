import media from '@ohos.multimedia.media'
// 语音配置接口
interface VoiceConfig {
  rate: number
  pitch: number
  description: string
}

// 语音设置接口
interface VoiceSettings {
  voice: string
  rate: number
  pitch: number
}

// 音频管理器 - 处理语音播报功能
export class AudioManager {
  private static instance: AudioManager | null = null
  private isEnabled: boolean = true
  private speechRate: number = 0.8
  private speechPitch: number = 1.1
  private currentVoice: string = '小美老师'
  private audioPlayer: media.AVPlayer | null = null
  private playerInitPromise: Promise<media.AVPlayer | null> | null = null
  private playbackQueue: Promise<void> = Promise.resolve()
  private targetVolume: number = 1.0
  private audioCache: Map<string, string> = new Map()
  private availableVoices: string[] = ['小美老师', '小明同学', '小华老师', '标准语音']
  private voiceSettings: Map<string, VoiceConfig> = new Map()

  private constructor() {
    void this.ensurePlayer()
    this.initializeAudioCache()
    this.initializeVoiceSettings()
  }

  static getInstance(): AudioManager {
    if (!AudioManager.instance) {
      AudioManager.instance = new AudioManager()
    }
    return AudioManager.instance
  }

  static hasInstance(): boolean {
    return AudioManager.instance !== null
  }

  private async ensurePlayer(): Promise<media.AVPlayer | null> {
    if (this.audioPlayer) {
      return this.audioPlayer
    }
    if (this.playerInitPromise) {
      return this.playerInitPromise
    }

    this.playerInitPromise = media.createAVPlayer()
      .then((player: media.AVPlayer) => {
        this.audioPlayer = player
        this.bindPlayerEvents(player)
        this.applyVolume(player)
        console.log('音频播放器初始化成功')
        return player
      })
      .catch((error: Error) => {
        console.error('音频播放器初始化失败:', error)
        this.audioPlayer = null
        return null
      })
      .finally(() => {
        this.playerInitPromise = null
      })

    return this.playerInitPromise
  }

  private bindPlayerEvents(player: media.AVPlayer) {
    try {
      player.on?.('error', (err: Error) => {
        console.error('[音频] 播放错误:', JSON.stringify(err))
      })
      player.on?.('stateChange', (state: string) => {
        console.debug(`[音频] 播放状态: ${state}`)
      })
    } catch (error) {
      console.warn('注册音频播放器事件失败:', error)
    }
  }

  private applyVolume(player: media.AVPlayer) {
    try {
      player.setVolume(this.targetVolume)
    } catch (_) {
      // 部分设备不支持设置音量，忽略
    }
  }

  // 初始化音频文件缓存
  private initializeAudioCache() {
    // 数字音频文件映射
    this.audioCache.set('0', 'rawfile:///audio/num0.ogg')
    this.audioCache.set('1', 'rawfile:///audio/num1.ogg')
    this.audioCache.set('2', 'rawfile:///audio/num2.ogg')
    this.audioCache.set('3', 'rawfile:///audio/num3.ogg')
    this.audioCache.set('4', 'rawfile:///audio/num4.ogg')
    this.audioCache.set('5', 'rawfile:///audio/num5.ogg')
    this.audioCache.set('6', 'rawfile:///audio/num6.ogg')
    this.audioCache.set('7', 'rawfile:///audio/num7.ogg')
    this.audioCache.set('8', 'rawfile:///audio/num8.ogg')
    this.audioCache.set('9', 'rawfile:///audio/num9.ogg')
    this.audioCache.set('10', 'rawfile:///audio/num10.ogg')
    this.audioCache.set('.', 'rawfile:///audio/dian.ogg')

    // 运算符音频文件映射
    this.audioCache.set('+', 'rawfile:///audio/jia.ogg')
    this.audioCache.set('-', 'rawfile:///audio/jian.ogg')
    this.audioCache.set('×', 'rawfile:///audio/multiple.ogg')
    this.audioCache.set('÷', 'rawfile:///audio/division.ogg')
    this.audioCache.set('=', 'rawfile:///audio/dengyu.ogg')

    // 中文数字映射
    this.audioCache.set('零', 'rawfile:///audio/zero.ogg')
    this.audioCache.set('一', 'rawfile:///audio/one.ogg')
    this.audioCache.set('二', 'rawfile:///audio/two.ogg')
    this.audioCache.set('三', 'rawfile:///audio/three.ogg')
    this.audioCache.set('四', 'rawfile:///audio/four.ogg')
    this.audioCache.set('五', 'rawfile:///audio/five.ogg')
    this.audioCache.set('六', 'rawfile:///audio/six.ogg')
    this.audioCache.set('七', 'rawfile:///audio/seven.ogg')
    this.audioCache.set('八', 'rawfile:///audio/eight.ogg')
    this.audioCache.set('九', 'rawfile:///audio/nine.ogg')
    this.audioCache.set('十', 'rawfile:///audio/shi.ogg')
    this.audioCache.set('点', 'rawfile:///audio/dian.ogg')

    // 中文运算符映射
    this.audioCache.set('加', 'rawfile:///audio/jia.ogg')
    this.audioCache.set('减', 'rawfile:///audio/jian.ogg')
    this.audioCache.set('乘', 'rawfile:///audio/multiple.ogg')
    this.audioCache.set('除', 'rawfile:///audio/division.ogg')
    this.audioCache.set('等于', 'rawfile:///audio/dengyu.ogg')

    console.log('音频文件缓存初始化完成，共', this.audioCache.size, '个音频文件')
  }

  // 初始化语音设置
  private initializeVoiceSettings() {
    this.voiceSettings.set('小美老师', { rate: 0.8, pitch: 1.1, description: '温柔女声，适合儿童' })
    this.voiceSettings.set('小明同学', { rate: 0.9, pitch: 1.0, description: '活泼男声，适合互动' })
    this.voiceSettings.set('小华老师', { rate: 0.7, pitch: 1.2, description: '专业女声，适合教学' })
    this.voiceSettings.set('标准语音', { rate: 1.0, pitch: 1.0, description: '标准语音，清晰准确' })
  }

  // 设置语音参数
  setVoiceSettings(voice: string, rate: number, pitch: number) {
    this.currentVoice = voice
    this.speechRate = rate
    this.speechPitch = pitch
  }

  // 启用/禁用语音
  setEnabled(enabled: boolean) {
    this.isEnabled = enabled
    console.log(`[音频] 语音播报${enabled ? '已启用' : '已禁用'}`)
  }
  
  // 获取语音状态
  getEnabled(): boolean {
    return this.isEnabled
  }

  // 语音播报文本
  speakText(text: string) {
    if (!this.isEnabled || !text) {
      return
    }

    try {
      // 直接使用TTS播报，避免AVPlayer状态问题
        this.speakWithTTS(text)
    } catch (error) {
      console.error('语音播报失败:', error)
      // 降级到控制台输出
      console.log('语音播报:', text)
    }
  }

  // 播放音频文件
  private playAudioFile(text: string) {
    const audioPath = this.audioCache.get(text)
    if (!audioPath) {
      console.warn(`音频文件不存在: ${text}`)
      return
    }

    this.enqueuePlayback(async () => {
      const player = await this.ensurePlayer()
      if (!player) {
        this.speakWithTTS(text)
        return
      }

      try {
        await player.stop()
      } catch (_) {}

      try {
        player.reset()
      } catch (error) {
        console.warn('[音频] 重置播放器失败:', error)
      }

      try {
        player.url = audioPath
        this.applyVolume(player)
        await player.prepare()
        await player.play()
        console.log(`[音频] 播放: ${text} -> ${audioPath}`)
      } catch (error) {
        console.error(`播放音频文件失败: ${text}`, error)
        this.speakWithTTS(text)
      }
    })
  }

  // 使用TTS播报
  private speakWithTTS(text: string) {
    try {
      // 在实际HarmonyOS环境中，应该这样调用：
      // import textToSpeech from '@ohos.textToSpeech'
      // textToSpeech.speak(text, {
      //   language: 'zh-CN',
      //   rate: this.speechRate,
      //   pitch: this.speechPitch,
      //   voice: this.currentVoice
      // })
      
      // 当前使用增强的模拟实现
      const voiceConfig = this.voiceSettings.get(this.currentVoice) || this.voiceSettings.get('小美老师')
      if (voiceConfig) {
        console.log(`[TTS] ${this.currentVoice}: ${text}`)
        console.log(`[TTS] 参数 - 语速: ${voiceConfig.rate}, 音调: ${voiceConfig.pitch}`)
        console.log(`[TTS] 描述: ${voiceConfig.description}`)
        
        // 模拟语音播报延迟（根据语速调整）
        const delay = Math.max(500, 2000 * voiceConfig.rate)
        setTimeout(() => {
          console.log(`[TTS] 播报完成: ${text}`)
        }, delay)
      } else {
        console.log(`[TTS] ${this.currentVoice}: ${text}`)
      }
      
    } catch (error) {
      console.error('TTS播报失败:', error)
    }
  }

  // 设置语音
  setVoice(voice: string) {
    if (this.availableVoices.includes(voice)) {
      this.currentVoice = voice
      const voiceConfig = this.voiceSettings.get(voice)
      if (voiceConfig) {
        this.speechRate = voiceConfig.rate
        this.speechPitch = voiceConfig.pitch
        console.log(`[TTS] 切换到语音: ${voice}`)
      }
    } else {
      console.warn(`[TTS] 不支持的语音: ${voice}`)
    }
  }

  // 获取可用语音列表
  getAvailableVoices(): string[] {
    return [...this.availableVoices]
  }

  // 获取语音设置
  getVoiceSettings(): Map<string, VoiceConfig> {
    return new Map(this.voiceSettings)
  }

  // 获取当前语音
  getCurrentVoice(): string {
    return this.currentVoice
  }

  // 设置语速
  setSpeechRate(rate: number) {
    if (rate >= 0.5 && rate <= 2.0) {
      this.speechRate = rate
      console.log(`[TTS] 语速设置为: ${rate}`)
    } else {
      console.warn(`[TTS] 语速超出范围 (0.5-2.0): ${rate}`)
    }
  }

  // 设置音调
  setSpeechPitch(pitch: number) {
    if (pitch >= 0.5 && pitch <= 2.0) {
      this.speechPitch = pitch
      console.log(`[TTS] 音调设置为: ${pitch}`)
    } else {
      console.warn(`[TTS] 音调超出范围 (0.5-2.0): ${pitch}`)
    }
  }

  // 获取当前设置
  getCurrentSettings(): VoiceSettings {
    return {
      voice: this.currentVoice,
      rate: this.speechRate,
      pitch: this.speechPitch
    }
  }

  // 测试语音
  testVoice(voice?: string) {
    const testText = '这是语音测试，请听一下效果'
    if (voice) {
      const originalVoice = this.currentVoice
      this.setVoice(voice)
      this.speakText(testText)
      // 恢复原语音
      setTimeout(() => {
        this.setVoice(originalVoice)
      }, 3000)
    } else {
      this.speakText(testText)
    }
  }

  // 播报数字
  speakNumber(number: string) {
    // 直接播放数字音频文件
    if (this.audioCache.has(number)) {
      this.playAudioFile(number)
    } else {
      // 降级到中文数字
      const numberText = this.convertNumberToText(number)
      this.speakText(numberText)
    }
  }

  // 播报运算符
  speakOperator(operator: string) {
    // 直接播放运算符音频文件
    if (this.audioCache.has(operator)) {
      this.playAudioFile(operator)
    } else {
      // 降级到中文运算符
      const operatorText = this.convertOperatorToText(operator)
      this.speakText(operatorText)
    }
  }

  // 播报中文数字
  speakChineseNumber(chineseNumber: string) {
    this.speakText(chineseNumber)
  }

  // 播报中文运算符
  speakChineseOperator(chineseOperator: string) {
    this.speakText(chineseOperator)
  }

  // 播报计算结果
  speakResult(expression: string, result: string) {
    const resultText = `${expression} 等于 ${result}`
    this.speakText(resultText)
  }

  // 播报练习题目
  speakQuestion(question: string) {
    const questionText = question.replace(/\+/g, '加').replace(/-/g, '减')
      .replace(/\*/g, '乘').replace(/\//g, '除')
      .replace(/=/g, '等于').replace(/\?/g, '多少')
    this.speakText(questionText)
  }

  // 播报鼓励话语
  speakEncouragement(isCorrect: boolean) {
    const encouragements = isCorrect ? [
      '太棒了！',
      '回答正确！',
      '你真聪明！',
      '继续加油！',
      '做得很好！'
    ] : [
      '不要灰心，再试一次！',
      '加油，你能行的！',
      '仔细想想，再试试！',
      '没关系，继续努力！'
    ]

    const randomEncouragement = encouragements[Math.floor(Math.random() * encouragements.length)]
    this.speakText(randomEncouragement)
  }

  // 转换数字为中文文本
  private convertNumberToText(number: string): string {
    const numberMap = new Map<string, string>()
    numberMap.set('0', '零')
    numberMap.set('1', '一')
    numberMap.set('2', '二')
    numberMap.set('3', '三')
    numberMap.set('4', '四')
    numberMap.set('5', '五')
    numberMap.set('6', '六')
    numberMap.set('7', '七')
    numberMap.set('8', '八')
    numberMap.set('9', '九')
    numberMap.set('.', '点')

    return number.split('').map(char => numberMap.get(char) || char).join('')
  }

  // 转换运算符为中文文本
  private convertOperatorToText(operator: string): string {
    const operatorMap = new Map<string, string>()
    operatorMap.set('+', '加')
    operatorMap.set('-', '减')
    operatorMap.set('*', '乘')
    operatorMap.set('/', '除')
    operatorMap.set('×', '乘')
    operatorMap.set('÷', '除')
    operatorMap.set('=', '等于')

    return operatorMap.get(operator) || operator
  }

  // 停止当前播报
  stopSpeaking() {
    this.enqueuePlayback(async () => {
      const player = await this.ensurePlayer()
      if (!player) {
        return
      }
      try {
        await player.stop()
      } catch (error) {
        console.warn('停止播放失败:', error)
      }
      try {
        player.reset()
      } catch (error) {
        console.warn('重置播放器失败:', error)
      }
    })
  }

  // 暂停播放
  pauseSpeaking() {
    this.enqueuePlayback(async () => {
      const player = await this.ensurePlayer()
      if (!player) {
        return
      }
      try {
        await player.pause()
      } catch (error) {
        console.error('暂停播报失败:', error)
      }
    })
  }

  // 恢复播放
  resumeSpeaking() {
    this.enqueuePlayback(async () => {
      const player = await this.ensurePlayer()
      if (!player) {
        return
      }
      try {
        await player.play()
      } catch (error) {
        console.error('恢复播报失败:', error)
      }
    })
  }

  // 检查TTS是否可用
  isTTSAvailable(): boolean {
    try {
      // 在实际HarmonyOS环境中，应该检查TTS服务是否可用
      return true
    } catch (error) {
      console.error('TTS服务检查失败:', error)
      return false
    }
  }

  async init(): Promise<void> {
    await this.ensurePlayer()
  }

  async playNumber(value: number): Promise<void> {
    this.speakNumber(String(value))
  }

  async playOperator(operator: string): Promise<void> {
    this.speakOperator(operator)
  }

  async setVolume(volume: number): Promise<void> {
    const clamped = Math.max(0, Math.min(1, volume))
    this.targetVolume = clamped
    const player = await this.ensurePlayer()
    if (player) {
      this.applyVolume(player)
    }
  }

  async preloadCommonAudios(): Promise<void> {
    await this.ensurePlayer()
  }

  private enqueuePlayback(task: () => Promise<void>) {
    this.playbackQueue = this.playbackQueue
      .catch(() => {})
      .then(task)
      .catch((error: Error) => {
        console.error('[音频] 播放队列任务失败:', error)
      })
  }


  // 设置语音类型
  setVoiceType(voiceType: string) {
    this.currentVoice = voiceType
    console.log(`[TTS] 切换语音类型: ${voiceType}`)
  }

  // 播报欢迎语
  speakWelcome() {
    const welcomeMessages = [
      '欢迎使用儿童语音计算器！',
      '让我们一起学习数学吧！',
      '准备好开始数学之旅了吗？',
      '数学学习，从这里开始！'
    ]

    const randomWelcome = welcomeMessages[Math.floor(Math.random() * welcomeMessages.length)]
    this.speakText(randomWelcome)
  }

  // 播报完成语
  speakCompletion() {
    const completionMessages = [
      '恭喜完成！',
      '任务完成！',
      '做得很好！',
      '继续加油！'
    ]

    const randomCompletion = completionMessages[Math.floor(Math.random() * completionMessages.length)]
    this.speakText(randomCompletion)
  }
}
