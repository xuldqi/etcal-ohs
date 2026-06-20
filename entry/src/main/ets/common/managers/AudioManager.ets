import common from '@ohos.app.ability.common'
import { textToSpeech } from '@kit.CoreSpeechKit'
import { BusinessError } from '@kit.BasicServicesKit'

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

interface PendingSpeech {
  text: string
  queueMode: number
}

// 音频管理器 - 处理语音播报功能
export class AudioManager {
  private static instance: AudioManager | null = null
  private isEnabled: boolean = true
  private ttsEngine: textToSpeech.TextToSpeechEngine | null = null
  private isTtsInitializing: boolean = false
  private pendingSpeeches: PendingSpeech[] = []
  private speechRate: number = 0.8
  private speechPitch: number = 1.1
  private currentVoice: string = '小美老师'
  private targetVolume: number = 1.0
  private availableVoices: string[] = ['小美老师', '小明同学', '小华老师', '标准语音']
  private voiceSettings: Map<string, VoiceConfig> = new Map()
  private abilityContext: common.UIAbilityContext | null = null

  private constructor() {
    this.initializeVoiceSettings()
  }

  // 设置应用上下文
  setContext(context: common.UIAbilityContext) {
    this.abilityContext = context
    console.log('[音频] 应用上下文已设置')
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
  speakText(text: string, queueMode: number = 0) {
    if (!text || !this.isEnabled) {
      return;
    }

    if (this.ttsEngine) {
      this.speakWithEngine(text, queueMode);
      return;
    }

    this.enqueueSpeech(text, queueMode);
    this.initTtsEngine();
  }

  private speakWithEngine(text: string, queueMode: number): void {
    if (!this.ttsEngine) {
      this.enqueueSpeech(text, queueMode);
      this.initTtsEngine();
      return;
    }

    let speakParams: textToSpeech.SpeakParams = {
      requestId: `tts_${Date.now()}_${Math.floor(Math.random() * 100000)}`,
      extraParams: {
        "queueMode": queueMode,
        "playType": 1,
        "speed": this.speechRate,
        "pitch": this.speechPitch,
        "volume": Math.max(0, Math.min(2, this.targetVolume * 2))
      }
    };
    try {
      this.ttsEngine.speak(text, speakParams);
    } catch (error) {
      console.error('TTS speak failed:', JSON.stringify(error));
    }
  }

  private enqueueSpeech(text: string, queueMode: number): void {
    if (queueMode === 0) {
      this.pendingSpeeches = [];
    }
    this.pendingSpeeches.push({ text, queueMode });
    if (this.pendingSpeeches.length > 3) {
      this.pendingSpeeches = this.pendingSpeeches.slice(this.pendingSpeeches.length - 3);
    }
    console.info(`[TTS] 语音引擎未就绪，已暂存播报: ${text}`);
  }

  private flushPendingSpeeches(): void {
    if (!this.ttsEngine || this.pendingSpeeches.length === 0) {
      return;
    }
    const speeches = this.pendingSpeeches;
    this.pendingSpeeches = [];
    speeches.forEach((speech: PendingSpeech) => {
      this.speakWithEngine(speech.text, speech.queueMode);
    });
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
    const numberText = this.convertNumberToChinese(number)
    this.speakText(numberText, 0)
  }

  // 播报运算符
  speakOperator(operator: string) {
    const operatorText = this.convertOperatorToText(operator)
    this.speakText(operatorText, 0)
  }

  // 播报中文数字
  speakChineseNumber(chineseNumber: string) {
    this.speakText(chineseNumber, 0)
  }

  // 播报中文运算符
  speakChineseOperator(chineseOperator: string) {
    this.speakText(chineseOperator, 0)
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
    this.speakText(randomEncouragement, 1)
  }

  // 转换数字为符合中文朗读习惯的文本 (例如: "45" -> "四十五")
  private convertNumberToChinese(numberStr: string): string {
    const num = parseInt(numberStr, 10);
    if (isNaN(num)) return numberStr;
    if (num < 0 || num > 100) return numberStr; // 仅针对游戏数字处理0-100
    if (num === 100) return '一百';
    
    const digits = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    if (num <= 9) return digits[num];
    if (num < 20) {
      const units = num % 10;
      return '十' + (units === 0 ? '' : digits[units]);
    }
    const tens = Math.floor(num / 10);
    const units = num % 10;
    return digits[tens] + '十' + (units === 0 ? '' : digits[units]);
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
    operatorMap.set('>', '大于')
    operatorMap.set('<', '小于')

    return operatorMap.get(operator) || operator
  }

  // 停止当前播报
  stopSpeaking() {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.stop()
      } catch (error) {
        console.warn('TTS停止失败:', error)
      }
    }
  }

  // 检查TTS是否可用
  isTTSAvailable(): boolean {
    return this.ttsEngine !== null
  }

  private initTtsEngine() {
    if (this.ttsEngine || this.isTtsInitializing) {
      return;
    }
    this.isTtsInitializing = true;
    this.createTtsEngine(0);
  }

  private getTtsInitParams(): textToSpeech.CreateEngineParams[] {
    // HarmonyOS 6.1 on some devices rejects unsupported extraParams such as style.
    // Keep engine creation params minimal and retry with offline mode if online TTS is unavailable.
    let extraParams: Record<string, Object> = {};
    return [
      {
        language: 'zh-CN',
        person: 0,
        online: 1,
        extraParams: extraParams
      },
      {
        language: 'zh-CN',
        person: 0,
        online: 0,
        extraParams: extraParams
      }
    ];
  }

  private createTtsEngine(index: number): void {
    const initParamsList = this.getTtsInitParams();
    if (index >= initParamsList.length) {
      this.isTtsInitializing = false;
      this.pendingSpeeches = [];
      console.error('Failed to create TTS engine: all init params failed');
      return;
    }

    try {
      textToSpeech.createEngine(initParamsList[index], (err: BusinessError, engine: textToSpeech.TextToSpeechEngine) => {
        if (!err) {
          this.isTtsInitializing = false;
          this.ttsEngine = engine;
          let listener: textToSpeech.SpeakListener = {
            onStart: (requestId: string, response: Object) => { console.info('TTS Playback started: ' + requestId); },
            onComplete: (requestId: string, response: Object) => { console.info('TTS Playback completed: ' + requestId); },
            onStop: (requestId: string, response: Object) => { console.info('TTS Playback stopped: ' + requestId); },
            onError: (requestId: string, errorCode: number, errorMessage: string) => {
              console.error(`TTS Error: ${errorCode}, ${errorMessage}`);
            }
          };
          this.ttsEngine.setListener(listener);
          console.info('TTS Engine created successfully');
          this.flushPendingSpeeches();
        } else {
          console.error(`Failed to create TTS engine with params index ${index}:`, JSON.stringify(err));
          this.createTtsEngine(index + 1);
        }
      });
    } catch (error) {
      console.error(`Failed to call createEngine with params index ${index}:`, JSON.stringify(error));
      this.createTtsEngine(index + 1);
    }
  }

  async init(): Promise<void> {
    this.initTtsEngine()
  }

  async playNumber(value: number): Promise<void> {
    this.speakNumber(String(value))
  }

  async playOperator(operator: string): Promise<void> {
    this.speakOperator(operator)
  }

  async playDelete(): Promise<void> {
    if (this.ttsEngine) {
      try {
        this.ttsEngine.stop()
      } catch (error) {
        console.warn('TTS停止失败:', error)
      }
    }
    this.speakText('删除', 1)
  }

  destroy(): void {
    const engine = this.ttsEngine
    if (engine) {
      try {
        engine.shutdown()
      } catch (error) {
        console.error('TTS engine shutdown error:', JSON.stringify(error))
      }
      this.ttsEngine = null
    }
    this.isTtsInitializing = false
    this.pendingSpeeches = []
  }

  async setVolume(volume: number): Promise<void> {
    const clamped = Math.max(0, Math.min(1, volume))
    this.targetVolume = clamped
    // HarmonyOS 6.1 TTS speak 参数要求 volume 在 0-2 范围内。
  }

  async preloadCommonAudios(): Promise<void> {
    // 纯TTS方案，不再需要预加载音频文件
    console.log('[音频] 预加载功能已移除，已完全使用TTS方案')
  }

  // 设置语音类型
  setVoiceType(voiceType: string) {
    this.currentVoice = voiceType
    const config = this.voiceSettings.get(voiceType)
    if (config) {
      this.speechRate = config.rate
      this.speechPitch = config.pitch
    }
    console.log(`[TTS] 切换语音类型: ${voiceType}, rate: ${this.speechRate}, pitch: ${this.speechPitch}`)
    this.initTtsEngine()
  }

  // 播报欢迎语
  speakWelcome() {
    const welcomeMessages = [
      '欢迎使用语音计算器！',
      '让我们一起学习数学吧！',
      '准备好开始数学之旅了吗？',
      '数学学习，从这里开始！'
    ]

    const randomWelcome = welcomeMessages[Math.floor(Math.random() * welcomeMessages.length)]
    this.speakText(randomWelcome, 1)
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
    this.speakText(randomCompletion, 1)
  }
}
