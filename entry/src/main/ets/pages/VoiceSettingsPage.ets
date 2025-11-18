import { AudioManager } from '../managers/AudioManager'
import { UnifiedHeader } from '../components/UnifiedHeader'
import media from '@ohos.multimedia.media'
import common from '@ohos.app.ability.common'
import abilityAccessCtrl from '@ohos.abilityAccessCtrl'
import fs from '@ohos.file.fs'
import preferences from '@ohos.data.preferences'
import { audio } from '@kit.AudioKit'

interface AudioItem {
  id: string
  label: string
  key: string
  audioPath?: string
  isRecorded?: boolean
}

interface VoiceScheme {
  id: string
  name: string
  description: string
  icon: string
  recordedCount: number
  totalCount: number
  isDefault: boolean
}

interface RecordedItemsMap {
  schemeId: string
  items: string[]
}

interface PermissionRequestResult {
  permissions: string[]
  authResults: number[]
}

interface FileDescriptor {
  fd: number
  offset: number
  length: number
}

interface RecordingFileInfo {
  fd: number
  path: string
}

// 持久化数据结构
interface PersistedMapEntry {
  schemeId: string
  items: string[]
}

interface PersistedPathItem {
  itemId: string
  path: string
}

interface PersistedPathEntry {
  schemeId: string
  paths: PersistedPathItem[]
}

interface PersistedData {
  version: number
  recordedMap: PersistedMapEntry[]
  recordedAudioPaths: PersistedPathEntry[]
  voiceSchemes?: VoiceScheme[]
}

@Component
export struct VoiceSettingsPage {
  onNavigate: (page: string) => void = () => {}
  registerBackHandler: (handler: (() => boolean) | null) => void = () => {}

  @State currentView: 'list' | 'recording' = 'list'
  @State selectedScheme: VoiceScheme | null = null
  @State isAudioEnabled: boolean = true
  @State showCreateDialog: boolean = false
  @State newSchemeName: string = ''
  @State playingItemId: string = ''
  @State statusMessage: string = ''
  @State recordedMap: Map<string, string[]> = new Map()
  
  @State voiceSchemes: VoiceScheme[] = [
    { 
      id: 'system', 
      name: '系统默认', 
      description: '标准普通话发音，适合大多数儿童', 
      icon: '🎙️',
      recordedCount: 23,
      totalCount: 23,
      isDefault: true
    },
    { 
      id: 'dad', 
      name: '爸爸的声音', 
      description: '让爸爸为你录制专属声音', 
      icon: '👨',
      recordedCount: 0,
      totalCount: 23,
      isDefault: false
    },
    { 
      id: 'mom', 
      name: '妈妈的声音', 
      description: '让妈妈为你录制温柔声音', 
      icon: '👩',
      recordedCount: 0,
      totalCount: 23,
      isDefault: false
    }
  ]

  private handleBackNavigation(): boolean {
    if (this.currentView === 'recording') {
      this.backToList()
    } else {
      this.onNavigate('home')
    }
    return true
  }

  private audioItems: AudioItem[] = [
    { id: '0', label: '数字 0', key: '0', audioPath: 'rawfile/audio/num0.ogg' },
    { id: '1', label: '数字 1', key: '1', audioPath: 'rawfile/audio/num1.ogg' },
    { id: '2', label: '数字 2', key: '2', audioPath: 'rawfile/audio/num2.ogg' },
    { id: '3', label: '数字 3', key: '3', audioPath: 'rawfile/audio/num3.ogg' },
    { id: '4', label: '数字 4', key: '4', audioPath: 'rawfile/audio/num4.ogg' },
    { id: '5', label: '数字 5', key: '5', audioPath: 'rawfile/audio/num5.ogg' },
    { id: '6', label: '数字 6', key: '6', audioPath: 'rawfile/audio/num6.ogg' },
    { id: '7', label: '数字 7', key: '7', audioPath: 'rawfile/audio/num7.ogg' },
    { id: '8', label: '数字 8', key: '8', audioPath: 'rawfile/audio/num8.ogg' },
    { id: '9', label: '数字 9', key: '9', audioPath: 'rawfile/audio/num9.ogg' },
    { id: 'plus', label: '加号 +', key: '+', audioPath: 'rawfile/audio/jia.ogg' },
    { id: 'minus', label: '减号 -', key: '-', audioPath: 'rawfile/audio/jian.ogg' },
    { id: 'multiply', label: '乘号 ×', key: '×', audioPath: 'rawfile/audio/multiple.ogg' },
    { id: 'divide', label: '除号 ÷', key: '÷', audioPath: 'rawfile/audio/division.ogg' },
    { id: 'equals', label: '等号 =', key: '=', audioPath: 'rawfile/audio/dengyu.ogg' },
    { id: 'decimal', label: '小数点 .', key: '.', audioPath: 'rawfile/audio/dian.ogg' },
    { id: 'shi', label: '十', key: '十', audioPath: 'rawfile/audio/shi.ogg' },
    { id: 'bai', label: '百', key: '百', audioPath: 'rawfile/audio/bai.ogg' },
    { id: 'qian', label: '千', key: '千', audioPath: 'rawfile/audio/qian.ogg' },
    { id: 'wan', label: '万', key: '万', audioPath: 'rawfile/audio/wan.ogg' },
    { id: 'clear', label: '清空', key: 'clear', audioPath: 'rawfile/audio/del.ogg' },
    { id: 'delete', label: '删除', key: 'delete', audioPath: 'rawfile/audio/del.ogg' }
  ]

  private audioManager: AudioManager = AudioManager.getInstance()
  private statusResetTimer: number | null = null
  private audioRecorder: media.AVRecorder | null = null
  private abilityContext: common.UIAbilityContext | null = null
  private isRecording: boolean = false
  private recordingItemId: string = ''
  private recordedAudioPaths: Map<string, Map<string, string>> = new Map()
  private recordingStopTimer: number | null = null
  private currentRecordingFd: number | null = null
  private currentRecordingSchemeId: string | null = null
  private currentRecordingItemKey: string | null = null
  private currentRecordingFilePath: string = ''
  private currentRecordingLabel: string = ''
  private hasAudioPermission: boolean = false
  private currentPlayer: media.AVPlayer | null = null
  private currentPlayerFd: number | null = null
  @State showDeleteDialog: boolean = false
  @State schemeToDelete: VoiceScheme | null = null

  aboutToAppear() {
    this.registerBackHandler(() => this.handleBackNavigation())
    this.ensureAbilityContext()
    void this.initAudioRecorder()
    void this.checkAudioPermissions()
    void this.loadPersistentData()
    // 从AudioManager获取当前语音状态
    this.isAudioEnabled = this.audioManager.getEnabled()
    // 只在语音开启时播报
    if (this.isAudioEnabled) {
      this.audioManager.speakText('选择喜欢的语音方案')
    }
  }

  private ensureAbilityContext(): common.UIAbilityContext | null {
    if (this.abilityContext) {
      return this.abilityContext
    }
    try {
      const context = getContext(this) as common.UIAbilityContext
      if (context) {
        this.abilityContext = context
      } else {
        console.warn('[页面] 获取UIAbilityContext失败: context为空')
      }
    } catch (error) {
      console.error('[页面] 获取UIAbilityContext异常:', error)
      this.abilityContext = null
    }
    return this.abilityContext
  }

  private async checkAudioPermissions() {
    try {
      // 检查音频权限
      const hasAudioPermission = await this.requestAudioPermissions()
      this.hasAudioPermission = hasAudioPermission
      if (!hasAudioPermission) {
        this.setStatus('需要音频权限才能播放和录制声音', false)
        this.audioManager.speakText('需要音频权限才能播放和录制声音')
      } else {
        this.setStatus('音频权限已获取，可以正常使用', true, 2000)
      }
    } catch (error) {
      console.error('检查音频权限失败:', error)
      this.hasAudioPermission = false
      this.setStatus('无法检查音频权限，可能影响功能使用', true, 3000)
    }
  }

  private async requestAudioPermissions(): Promise<boolean> {
    const permission = 'ohos.permission.MICROPHONE'
    try {
      const context = this.ensureAbilityContext()
      if (!context) {
        console.error('[权限] 缺少UIAbilityContext，无法检查权限')
        return false
      }

      const atManager = abilityAccessCtrl.createAtManager()
      const tokenId = context.applicationInfo?.accessTokenId

      if (tokenId !== undefined) {
        const grantStatus = await atManager.checkAccessToken(tokenId, permission)
        if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
          console.log('[权限] 麦克风权限已授予')
          return true
        }
        console.warn(`[权限] 麦克风权限未授予，申请权限... 状态码: ${grantStatus}`)
      } else {
        console.warn('[权限] 无法获取 accessTokenId，将直接申请权限')
      }

      const requestResult = await atManager.requestPermissionsFromUser(
        context,
        [permission]
      ) as PermissionRequestResult

      const authResult = requestResult?.authResults?.[0]
      if (authResult === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        console.log('[权限] 麦克风权限申请成功')
        return true
      }

      console.error(`[权限] 麦克风权限申请被拒绝，结果码: ${authResult}`)
      return false
    } catch (error) {
      console.error('[权限] 请求音频权限失败:', error)
      return false
    }
  }

  async aboutToDisappear() {
    this.registerBackHandler(null)
    this.clearRecordingTimer()
    if (this.statusResetTimer !== null) {
      clearTimeout(this.statusResetTimer)
      this.statusResetTimer = null
    }
    if (this.audioRecorder) {
      try {
        if (this.isRecording) {
          await this.completeRecording()
        }
        this.audioRecorder.release()
      } catch (_) {}
      this.audioRecorder = null
    }
  }


  async initAudioRecorder() {
    try {
      this.audioRecorder = await media.createAVRecorder()
      console.log('AVRecorder初始化成功')
      
      // 绑定录制器事件
      this.bindRecorderEvents()
      
      // 获取应用上下文
      this.ensureAbilityContext()
      
    } catch (error) {
      console.error('AVRecorder初始化失败:', error)
      this.setStatus('当前环境暂不支持音频录制', false)
    }
  }

  private bindRecorderEvents() {
    if (!this.audioRecorder) return
    
    try {
      this.audioRecorder.on?.('error', (err: Error) => {
        console.error('[音频录制] 录制错误:', JSON.stringify(err))
        this.setStatus('录制失败，请检查麦克风权限', true, 3000)
        this.isRecording = false
        this.recordingItemId = ''
        this.currentRecordingLabel = ''
        this.currentRecordingSchemeId = null
        this.currentRecordingItemKey = null
        this.currentRecordingFilePath = ''
        this.clearRecordingTimer()
      })
      
      this.audioRecorder.on?.('stateChange', (state: string) => {
        console.debug(`[音频录制] 录制状态: ${state}`)
        if (state === 'recording') {
          const label = this.currentRecordingLabel || this.recordingItemId
          this.setStatus(`🔴 正在录制「${label}」...`, false)
        } else if (state === 'stopped') {
          this.setStatus('录制完成，正在保存...', false)
        }
      })
      
    } catch (error) {
      console.warn('注册音频录制器事件失败:', error)
    }
  }



  private async playRawResource(resourcePath: string, item: AudioItem) {
    try {
      // 先停止当前播放
      await this.stopCurrentPlayer()

      this.playingItemId = item.id
      this.setStatus(`🔊 正在试听「${item.label}」`, false)

      const context = this.ensureAbilityContext()
      if (!context) {
        throw new Error('无法获取应用上下文')
      }

      // 创建新的AVPlayer
      const player = await media.createAVPlayer()
      this.currentPlayer = player

      // 设置状态机回调
      player.on('stateChange', async (state: string) => {
        switch (state) {
          case 'initialized':
            console.info('[音频] 播放器已初始化')
            // 设置音频输出属性
            player.audioRendererInfo = {
              usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
              rendererFlags: 0,
            }
            // 触发prepare
            player.prepare()
            break
          case 'prepared':
            console.info('[音频] 播放器已准备就绪')
            // 自动播放
            player.play()
            break
          case 'playing':
            console.info('[音频] 开始播放')
            this.setStatus(`🎵 正在播放「${item.label}」`, false)
            break
          case 'completed':
            console.info('[音频] 播放完成')
            this.playingItemId = ''
            this.setStatus('播放完成', true, 1500)
            this.stopCurrentPlayer()
            break
          case 'error':
            console.error('[音频] 播放器错误')
            this.playingItemId = ''
            this.setStatus('❌ 播放失败', true, 3000)
            this.stopCurrentPlayer()
            break
        }
      })

      // 获取文件描述符
      const resourceManager = context.resourceManager
      const fileDescriptor = await resourceManager.getRawFileDescriptor(resourcePath)
      console.info(`[音频] 获取文件描述符成功: fd=${fileDescriptor.fd}, offset=${fileDescriptor.offset}, length=${fileDescriptor.length}`)

      // 设置fdSrc
      player.fdSrc = {
        fd: fileDescriptor.fd,
        offset: fileDescriptor.offset,
        length: fileDescriptor.length,
      }
      this.currentPlayerFd = fileDescriptor.fd

      // 设置url会触发initialized状态
      player.url = `fd://${fileDescriptor.fd}`

    } catch (error) {
      console.error(`[试听] ❌ 播放失败: ${item.label}`, error)
      this.playingItemId = ''
      this.setStatus('❌ 播放失败，请检查音频文件', true, 3000)
      this.stopCurrentPlayer()
    }
  }

  private getTTSForItem(item: AudioItem): string {
    // 根据音频项目返回对应的TTS文本
    switch (item.key) {
      case '0': return '零'
      case '1': return '一'
      case '2': return '二'
      case '3': return '三'
      case '4': return '四'
      case '5': return '五'
      case '6': return '六'
      case '7': return '七'
      case '8': return '八'
      case '9': return '九'
      case '+': return '加'
      case '-': return '减'
      case '×': return '乘'
      case '÷': return '除'
      case '=': return '等于'
      case '.': return '点'
      case '十': return '十'
      case '百': return '百'
      case '千': return '千'
      case '万': return '万'
      case 'clear': return '清空'
      case 'delete': return '删除'
      default: return item.label
    }
  }

  private async playFile(path: string, item: AudioItem) {
    try {
      // 先停止当前播放
      await this.stopCurrentPlayer()

      this.playingItemId = item.id
      this.setStatus(`🎵 正在试听「${item.label}」`, false)

      // 创建新的AVPlayer
      const player = await media.createAVPlayer()
      this.currentPlayer = player

      // 打开文件获取fd
      const file = await fs.open(path)
      console.info(`[音频] 打开文件成功: fd=${file.fd}`)
      this.currentPlayerFd = file.fd

      // 设置状态机回调
      player.on('stateChange', async (state: string) => {
        switch (state) {
          case 'initialized':
            console.info('[音频] 播放器已初始化')
            // 设置音频输出属性
            player.audioRendererInfo = {
              usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
              rendererFlags: 0,
            }
            // 触发prepare
            player.prepare()
            break
          case 'prepared':
            console.info('[音频] 播放器已准备就绪')
            // 自动播放
            player.play()
            break
          case 'playing':
            console.info('[音频] 开始播放')
            this.setStatus(`🎵 正在播放「${item.label}」`, false)
            break
          case 'completed':
            console.info('[音频] 播放完成')
            this.playingItemId = ''
            this.setStatus('播放完成', true, 1500)
            this.stopCurrentPlayer()
            break
          case 'error':
            console.error('[音频] 播放器错误')
            this.playingItemId = ''
            this.setStatus('❌ 播放失败', true, 3000)
            this.stopCurrentPlayer()
            break
        }
      })

      // 设置url会触发initialized状态
      player.url = `fd://${file.fd}`

    } catch (error) {
      console.error(`[试听] ❌ 播放失败: ${item.label}`, error)
      this.playingItemId = ''
      this.setStatus('❌ 播放失败，请检查录音文件', true, 3000)
      this.stopCurrentPlayer()
    }
  }

  private async stopCurrentPlayer() {
    try {
      if (this.currentPlayer) {
        if (this.currentPlayer.state === 'playing' || this.currentPlayer.state === 'paused') {
          this.currentPlayer.stop()
        }
        this.currentPlayer.release()
        this.currentPlayer = null
      }
      if (this.currentPlayerFd !== null) {
        fs.closeSync(this.currentPlayerFd)
        this.currentPlayerFd = null
      }
    } catch (error) {
      console.error('[音频] 停止播放器失败:', error)
    }
  }

  private setStatus(message: string, autoClear: boolean = true, delay: number = 2500) {
    this.statusMessage = message
    if (this.statusResetTimer !== null) {
      clearTimeout(this.statusResetTimer)
      this.statusResetTimer = null
    }
    if (autoClear) {
      const timer: number = setTimeout(() => {
        this.statusMessage = ''
        this.statusResetTimer = null
      }, delay)
      this.statusResetTimer = timer
    }
  }

  private getRecordedItemsForScheme(schemeId: string): string[] {
    const items = this.recordedMap.get(schemeId)
    return items ? items.slice() : []
  }

  private isItemRecorded(itemId: string, schemeId?: string): boolean {
    const targetScheme = schemeId ?? this.selectedScheme?.id
    if (!targetScheme) {
      return false
    }
    const items = this.recordedMap.get(targetScheme)
    return items ? items.includes(itemId) : false
  }

  private getRecordedFilePath(schemeId: string, itemId: string): string | undefined {
    return this.recordedAudioPaths.get(schemeId)?.get(itemId)
  }

  private registerRecordingResult(schemeId: string, itemId: string, filePath: string) {
    const existing = this.recordedMap.get(schemeId) ?? []
    const updated = existing.includes(itemId) ? existing.slice() : existing.concat([itemId])
    this.recordedMap.set(schemeId, updated)

    let schemePaths = this.recordedAudioPaths.get(schemeId)
    if (!schemePaths) {
      schemePaths = new Map()
      this.recordedAudioPaths.set(schemeId, schemePaths)
    }
    if (schemePaths.has(itemId)) {
      console.info(`[录音] 更新录音文件路径: ${schemeId} -> ${itemId}`)
    }
    schemePaths.set(itemId, filePath)

    this.updateSchemeRecordedCount(schemeId, updated.length)
    void this.savePersistentData()
  }

  // 持久化：保存/加载录音记录
  private async getPrefs(): Promise<preferences.Preferences | null> {
    try {
      const ctx = this.ensureAbilityContext()
      if (!ctx) return null
      const pref = await preferences.getPreferences(ctx, 'voice_prefs')
      return pref
    } catch (e) {
      console.error('[持久化] 获取Preferences失败:', e)
      return null
    }
  }

  private async savePersistentData() {
    try {
      const pref = await this.getPrefs()
      if (!pref) return
      const mapArr: PersistedMapEntry[] = []
      this.recordedMap.forEach((arr, sid) => { mapArr.push({ schemeId: sid, items: arr.slice() }) })

      const pathArr: PersistedPathEntry[] = []
      this.recordedAudioPaths.forEach((inner, sid) => {
        const list: PersistedPathItem[] = []
        inner.forEach((p, itemId) => { list.push({ itemId: itemId, path: p }) })
        pathArr.push({ schemeId: sid, paths: list })
      })

      const payload: PersistedData = {
        version: 1,
        recordedMap: mapArr,
        recordedAudioPaths: pathArr,
        voiceSchemes: this.voiceSchemes.slice()
      }
      await pref.put('recordedData', JSON.stringify(payload))
      await pref.flush()
      console.info('[持久化] 录音记录和语音方案已保存')
    } catch (e) {
      console.error('[持久化] 保存失败:', e)
    }
  }

  private async loadPersistentData() {
    try {
      const pref = await this.getPrefs()
      if (!pref) return
      const raw = (await pref.get('recordedData', '')) as string
      if (!raw) return
      const data = JSON.parse(raw) as PersistedData

      const newRecordedMap: Map<string, string[]> = new Map()
      ;(data.recordedMap || []).forEach((entry) => {
        if (entry && entry.schemeId && Array.isArray(entry.items)) {
          newRecordedMap.set(entry.schemeId, entry.items)
        }
      })
      this.recordedMap = newRecordedMap

      const newPaths: Map<string, Map<string, string>> = new Map()
      ;(data.recordedAudioPaths || []).forEach((entry) => {
        if (entry && entry.schemeId && Array.isArray(entry.paths)) {
          const innerMap = new Map<string, string>()
          entry.paths.forEach(p => { if (p && p.itemId && p.path) innerMap.set(p.itemId, p.path) })
          newPaths.set(entry.schemeId, innerMap)
        }
      })
      this.recordedAudioPaths = newPaths

      // 恢复语音方案列表
      if (data.voiceSchemes && Array.isArray(data.voiceSchemes)) {
        this.voiceSchemes = data.voiceSchemes
        console.info('[持久化] 语音方案已恢复')
      }

      // 恢复每个方案的计数
      this.voiceSchemes.forEach((scheme) => {
        const count = this.recordedMap.get(scheme.id)?.length || 0
        this.updateSchemeRecordedCount(scheme.id, count)
      })
      console.info('[持久化] 录音记录已恢复')
    } catch (e) {
      console.error('[持久化] 加载失败:', e)
    }
  }

  private deleteScheme(schemeId: string) {
    try {
      // 删除录音文件
      const schemePaths = this.recordedAudioPaths.get(schemeId)
      if (schemePaths) {
        schemePaths.forEach((filePath) => {
          try {
            if (fs.accessSync(filePath)) {
              fs.unlinkSync(filePath)
              console.info(`[删除] 已删除录音文件: ${filePath}`)
            }
          } catch (error) {
            console.warn(`[删除] 删除文件失败: ${filePath}`, error)
          }
        })
      }

      // 从内存中清理数据
      this.recordedMap.delete(schemeId)
      this.recordedAudioPaths.delete(schemeId)

      // 从方案列表中删除
      this.voiceSchemes = this.voiceSchemes.filter(scheme => scheme.id !== schemeId)

      // 保存到持久化存储
      void this.savePersistentData()

      console.info(`[删除] 方案已删除: ${schemeId}`)
    } catch (error) {
      console.error('[删除] 删除方案失败:', error)
      this.setStatus('删除失败，请重试', true, 3000)
    }
  }

  private updateSchemeRecordedCount(schemeId: string, recordedCount: number) {
    const updatedSchemes: VoiceScheme[] = this.voiceSchemes.map((scheme: VoiceScheme) => {
      if (scheme.id === schemeId) {
        return {
          id: scheme.id,
          name: scheme.name,
          description: scheme.description,
          icon: scheme.icon,
          recordedCount: recordedCount,
          totalCount: scheme.totalCount,
          isDefault: scheme.isDefault
        }
      }
      return scheme
    })

    this.voiceSchemes = updatedSchemes

    if (this.selectedScheme?.id === schemeId) {
      const refreshed = updatedSchemes.find((scheme: VoiceScheme) => scheme.id === schemeId) ?? null
      this.selectedScheme = refreshed
    }
  }

  private async buildRecordingFile(schemeId: string, itemId: string): Promise<RecordingFileInfo> {
    const context = this.ensureAbilityContext()
    const baseDir = context?.filesDir ?? '/data/storage/el2/base/cache'
    const sanitizedScheme = schemeId.replace(/[^a-zA-Z0-9_-]/g, '_')
    const sanitizedItem = itemId.replace(/[^a-zA-Z0-9_-]/g, '_')
    const fileName = `voice_${sanitizedScheme}_${sanitizedItem}_${Date.now()}.m4a`
    const filePath = `${baseDir}/${fileName}`
    
    try {
      // 确保目录存在
      try {
        await fs.mkdir(baseDir, true)
      } catch (mkdirError) {
        // 目录可能已存在，忽略错误
        console.debug(`[录音] 目录创建结果: ${baseDir}`, mkdirError)
      }
      
      // 创建文件并获取文件描述符
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)
      const fd = file.fd
      
      console.info(`[录音] 创建录音文件: ${filePath}, fd: ${fd}`)
      const result: RecordingFileInfo = { fd: fd, path: filePath }
      return result
    } catch (error) {
      console.error(`[录音] 创建录音文件失败: ${filePath}`, error)
      throw new Error(`无法创建录音文件: ${error}`)
    }
  }

  private clearRecordingTimer() {
    if (this.recordingStopTimer !== null) {
      clearTimeout(this.recordingStopTimer)
      this.recordingStopTimer = null
    }
  }

  private setDefaultScheme(schemeId: string) {
    const updated: VoiceScheme[] = []
    for (let i = 0; i < this.voiceSchemes.length; i++) {
      const scheme = this.voiceSchemes[i]
      const refreshed: VoiceScheme = {
        id: scheme.id,
        name: scheme.name,
        description: scheme.description,
        icon: scheme.icon,
        recordedCount: scheme.recordedCount,
        totalCount: scheme.totalCount,
        isDefault: scheme.id === schemeId
      }
      updated.push(refreshed)
    }
    this.voiceSchemes = updated

    const selected = this.voiceSchemes.find(value => value.id === schemeId)
    if (selected) {
      this.audioManager.speakText(`已设为默认：${selected.name}`)
    }
  }

  private enterRecordingView(scheme: VoiceScheme) {
    console.info(`[页面] 进入录制界面: ${scheme.name}`)
    this.selectedScheme = scheme
    this.currentView = 'recording'
    
    // 不清空已录制项目，保留之前的录制记录
    
    if (scheme.id === 'system') {
      this.audioManager.speakText(`进入${scheme.name}试听界面`)
      this.setStatus(`💡 系统方案可以试听，但不支持录音`, true, 4000)
    } else {
      this.audioManager.speakText(`进入${scheme.name}录制界面`)
      const recordedCount = this.getRecordedItemsForScheme(scheme.id).length
      if (recordedCount !== scheme.recordedCount) {
        this.updateSchemeRecordedCount(scheme.id, recordedCount)
      }
      const totalCount = scheme.totalCount || 23
      this.setStatus(`📝 已录制 ${recordedCount}/${totalCount} 个音频`, true, 3000)
    }
  }

  private backToList() {
    this.currentView = 'list'
    this.selectedScheme = null
  }

  private createNewScheme() {
    if (!this.newSchemeName.trim()) {
      this.audioManager.speakText('请输入方案名称')
      return
    }

    const newScheme: VoiceScheme = {
      id: `custom_${Date.now()}`,
      name: this.newSchemeName.trim(),
      description: '自定义录制的语音方案',
      icon: '🎤',
      recordedCount: 0,
      totalCount: 23,
      isDefault: false
    }

    const schemes = this.voiceSchemes.slice()
    schemes.push(newScheme)
    this.voiceSchemes = schemes

    this.showCreateDialog = false
    this.newSchemeName = ''
    
    // 保存到持久化存储
    void this.savePersistentData()
    
    this.enterRecordingView(newScheme)
  }

  private async playAudio(item: AudioItem) {
    console.info(`[试听] ===== 开始试听流程 =====`)
    console.info(`[试听] 项目: ${item.label}, 方案: ${this.selectedScheme?.id}`)
    
    // 检查语音是否开启
    if (!this.isAudioEnabled) {
      console.warn('[试听] 语音播报已关闭')
      this.setStatus('⚠️ 请先开启语音播报开关', true, 3000)
      return
    }
    
    const schemeId = this.selectedScheme?.id

    if (!schemeId) {
      console.warn('[试听] ❌ 未选择语音方案')
      this.setStatus('❌ 请先选择语音方案', true, 3000)
      return
    }

    if (schemeId === 'system') {
      if (item.audioPath) {
        await this.playRawResource(item.audioPath, item)
      } else {
        // 对于没有音频文件的项，使用TTS播报
        console.warn(`[试听] 系统方案缺少音频资源: ${item.label}，使用TTS播报`)
        this.playingItemId = item.id
        this.setStatus(`🔊 正在试听「${item.label}」`, false)
        const ttsText = this.getTTSForItem(item)
        this.audioManager.speakText(ttsText)
        setTimeout(() => {
          this.playingItemId = ''
          this.setStatus('播放完成', true, 1500)
        }, 1500)
      }
      console.info(`[试听] ===== 试听流程完成 =====`)
      return
    }

    const recordedPath = this.getRecordedFilePath(schemeId, item.id)
    if (recordedPath) {
      await this.playFile(recordedPath, item)
      console.info(`[试听] ===== 试听流程完成 =====`)
      return
    }

    console.warn(`[试听] ⚠️ 项目「${item.label}」尚未录制`)
    this.audioManager.speakText('请先录制音频')
    this.setStatus(`⚠️ 请先录制「${item.label}」的音频`, true, 3000)
    console.info(`[试听] ===== 试听流程完成 =====`)
  }

  private async startRecording(itemId: string) {
    console.info(`[录音] ===== 开始录音流程 =====`)
    console.info(`[录音] 项目ID: ${itemId}`)
    console.info(`[录音] 方案: ${this.selectedScheme?.name}`)
    
    const scheme = this.selectedScheme
    if (!scheme) {
      console.warn('[录音] ❌ 未选择语音方案')
      this.audioManager.speakText('请先选择语音方案')
      this.setStatus('❌ 请先选择语音方案', true, 4000)
      return
    }

    // 检查是否为系统方案
    if (scheme.id === 'system') {
      console.warn('[录音] ❌ 系统默认方案不支持录音')
      this.audioManager.speakText('系统默认方案不支持录音')
      this.setStatus('❌ 系统默认方案无法录音，请选择自定义方案', true, 5000)
      return
    }

    // 检查是否正在录制
    if (this.isRecording) {
      console.warn('[录音] ❌ 正在录制中，请等待完成')
      this.audioManager.speakText('正在录制中，请等待完成')
      this.setStatus('❌ 正在录制中，请等待完成', true, 3000)
      return
    }

    const item = this.audioItems.find(i => i.id === itemId)
    if (!item) {
      console.error('[录音] ❌ 未找到录音项目')
      this.setStatus('❌ 录音项目不存在', true, 3000)
      return
    }

    // 检查录制器是否可用
    if (!this.audioRecorder) {
      console.error('[录音] ❌ 音频录制器未初始化')
      this.setStatus('❌ 音频录制器未准备好', true, 3000)
      return
    }

    // 确认权限
    if (!this.hasAudioPermission) {
      const granted = await this.requestAudioPermissions()
      this.hasAudioPermission = granted
      if (!granted) {
        console.warn('[录音] ❌ 缺少麦克风权限')
        this.audioManager.speakText('需要麦克风权限才能录音')
        this.setStatus('❌ 需要麦克风权限才能录音', true, 4000)
        return
      }
    }

    const schemeId = scheme.id
    this.clearRecordingTimer()

    try {
      console.info(`[录音] 开始录制: ${item.label}`)
      
      // 创建录音文件并获取文件描述符
      const recordingFileInfo = await this.buildRecordingFile(schemeId, itemId)
      const fd = recordingFileInfo.fd
      const recordingPath = recordingFileInfo.path
      
      this.currentRecordingSchemeId = schemeId
      this.currentRecordingItemKey = itemId
      this.currentRecordingFilePath = recordingPath
      this.currentRecordingLabel = item.label
      this.recordingItemId = item.id
      this.currentRecordingFd = fd
      this.setStatus(`🎙️ 准备录制「${item.label}」...`, false)
      this.audioManager.speakText(`开始录制 ${item.label}，请清晰地说出`)

      try {
        await this.audioRecorder.reset()
      } catch (resetError) {
        console.warn('[录音] 重置音频录制器失败:', resetError)
      }

      const recorderConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: {
          audioBitrate: 128000,
          audioChannels: 1,
          audioCodec: media.CodecMimeType.AUDIO_AAC,
          audioSampleRate: 44100,
          fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
        },
        url: `fd://${fd}`
      }

      await this.audioRecorder.prepare(recorderConfig)
      await this.audioRecorder.start()
      this.isRecording = true
      this.setStatus(`🔴 正在录音中，请说「${item.key}」...`, false)
      console.info(`[录音] 录音中... 路径: ${recordingPath}`)

      this.clearRecordingTimer()
      this.recordingStopTimer = setTimeout(() => {
        void this.completeRecording()
      }, 3500)
    } catch (error) {
      console.error('[录音] 录制失败:', error)
      this.clearRecordingTimer()
      this.isRecording = false
      this.recordingItemId = ''
      this.currentRecordingSchemeId = null
      this.currentRecordingItemKey = null
      this.currentRecordingFilePath = ''
      this.currentRecordingLabel = ''
      
      // 关闭文件描述符
      if (this.currentRecordingFd !== null) {
        try {
          fs.closeSync(this.currentRecordingFd)
          console.info(`[录音] 错误时关闭文件描述符: ${this.currentRecordingFd}`)
        } catch (closeError) {
          console.warn('[录音] 关闭文件描述符失败:', closeError)
        }
        this.currentRecordingFd = null
      }
      
      const errorMsg = error instanceof Error ? error.message : String(error)
      this.setStatus(`❌ 录制失败: ${errorMsg}`, true, 4000)
    }
  }

  private async completeRecording() {
    if (!this.audioRecorder) {
      return
    }
    if (!this.isRecording) {
      return
    }

    this.clearRecordingTimer()

    try {
      await this.audioRecorder.stop()
      console.info('[录音] 录音完成，保存中...')
    } catch (error) {
      console.error('[录音] 停止录制失败:', error)
      this.isRecording = false
      this.setStatus('❌ 停止录制失败', true, 3000)
      return
    }

    const schemeId = this.currentRecordingSchemeId
    const itemId = this.currentRecordingItemKey
    const label = this.currentRecordingLabel
    const filePath = this.currentRecordingFilePath
    const fd = this.currentRecordingFd

    this.isRecording = false
    this.recordingItemId = ''
    this.currentRecordingSchemeId = null
    this.currentRecordingItemKey = null
    this.currentRecordingFilePath = ''
    this.currentRecordingLabel = ''
    this.currentRecordingFd = null

    // 关闭文件描述符
    if (fd !== null) {
      try {
        fs.closeSync(fd)
        console.info(`[录音] 文件描述符已关闭: ${fd}`)
      } catch (error) {
        console.warn('[录音] 关闭文件描述符失败:', error)
      }
    }

    try {
      await this.audioRecorder.reset()
    } catch (error) {
      console.warn('[录音] 重置录制器失败:', error)
    }

    if (schemeId && itemId && filePath) {
      this.registerRecordingResult(schemeId, itemId, filePath)
      const recordedCount = this.getRecordedItemsForScheme(schemeId).length
      console.info(`[录音] 已标记为录制: ${schemeId} -> ${itemId}`)
      console.info(`[录音] 当前方案已录制数量: ${recordedCount}`)
      this.setStatus(`✅ 录制完成！已保存「${label || itemId}」`, true, 3000)
      this.audioManager.speakText('录制完成')
      console.info('[录音] ===== 录音流程完成 =====')
    } else {
      console.warn('[录音] ⚠️ 缺少录音信息，无法保存记录')
      this.setStatus('⚠️ 录音完成但未能保存记录', true, 4000)
    }
  }

  @Builder
  SchemeCard(scheme: VoiceScheme) {
    Stack() {
      Row({ space: 16 }) {
        Column({ space: 6 }) {
          Row({ space: 8 }) {
            Text(scheme.name)
              .fontSize(17)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')

            if (scheme.id === 'system') {
              Text('可试听')
                .fontSize(11)
                .fontColor('#16a34a')
                .fontWeight(FontWeight.Medium)
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor('#dcfce7')
                .borderRadius(10)
            }
          }

          Text(scheme.description)
            .fontSize(13)
            .fontColor('#6b7280')

          if (scheme.id !== 'system') {
            Row({ space: 8 }) {
              Stack() {
                // 背景条
                Row()
                  .width(200)
                  .height(8)
                  .backgroundColor('#e5e7eb')
                  .borderRadius(4)

                // 进度条
                Row()
                  .width(`${Math.max(4, (scheme.recordedCount / scheme.totalCount) * 200)}`)
                  .height(8)
                  .backgroundColor(scheme.recordedCount === scheme.totalCount ? '#22c55e' : '#3b82f6')
                  .borderRadius(4)
                  .position({ x: 0, y: 0 })
              }
              .alignContent(Alignment.TopStart)
              .width(200)
              .height(8)

              Text(`${scheme.recordedCount}/${scheme.totalCount} 已录制`)
                .fontSize(12)
                .fontColor(scheme.recordedCount === scheme.totalCount ? '#16a34a' : '#2563eb')
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
            .padding({ left: 0, right: 0, top: 8, bottom: 0 })
          }

          if (scheme.isDefault) {
            Row({ space: 4 }) {
              Text('⭐')
                .fontSize(12)
              Text('默认方案')
                .fontSize(12)
                .fontColor('#ca8a04')
            }
            .padding({ top: 4 })
          }
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Text('›')
          .fontSize(28)
          .fontColor('#9ca3af')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 18, bottom: 18 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
      .onClick(() => {
        this.enterRecordingView(scheme)
      })

      Button(scheme.isDefault ? '默认' : '设为默认')
        .fontSize(10)
        .fontColor(scheme.isDefault ? '#ca8a04' : '#1d4ed8')
        .backgroundColor(scheme.isDefault ? '#fef3c7' : '#dbeafe')
        .borderRadius(8)
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .height(22)
        .position({ x: '100%', y: 16 })
        .translate({ x: '-110%' })
        .onClick(() => {
          if (!scheme.isDefault) {
            this.setDefaultScheme(scheme.id)
          }
        })
    }
    .width('100%')
    .alignContent(Alignment.TopEnd)
  }

  @Builder
  SchemeListView() {
    Column({ space: 16 }) {
      Column({ space: 12 }) {
        Row({ space: 12 }) {
          Text('语音播报')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1f2937')
          Blank()
          Toggle({ type: ToggleType.Switch, isOn: this.isAudioEnabled })
            .selectedColor('#fb923c')
            .onChange((isOn: boolean) => {
              this.isAudioEnabled = isOn
              this.audioManager.setEnabled(isOn)
              if (isOn) {
                this.audioManager.speakText('语音播报已开启')
              }
            })
        }
        .width('100%')

        Text('为孩子选择喜欢的语音，或者录制专属声音，让练习更有趣。')
          .fontSize(14)
          .fontColor('#6b7280')
          .lineHeight(20)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .shadow({ radius: 12, color: '#00000012', offsetX: 0, offsetY: 8 })

      Text('录制语音方案')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')
        .width('100%')
        .padding({ left: 4 })

      ForEach(this.voiceSchemes, (scheme: VoiceScheme) => {
        this.SchemeCard(scheme)
      })

      if (this.statusMessage && this.currentView === 'list') {
        Text(this.statusMessage)
          .fontSize(12)
          .fontColor('#2563eb')
          .backgroundColor('#e0f2fe')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(12)
      }

      Row({ space: 12 }) {
        Column() {
          Text('+')
            .fontSize(24)
            .fontColor('#9ca3af')
        }
        .width(48)
        .height(48)
        .backgroundColor('#f3f4f6')
        .borderRadius(16)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)

        Column({ space: 4 }) {
          Text('创建自定义语音方案')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1f2937')
          Text('录制孩子喜欢的声音，让学习更有趣')
            .fontSize(12)
            .fontColor('#6b7280')
        }
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 14, bottom: 14 })
      .backgroundColor('#fff7ed')
      .borderRadius(18)
      .shadow({ radius: 10, color: '#00000008', offsetX: 0, offsetY: 6 })
      .onClick(() => {
        this.showCreateDialog = true
      })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  RecordingView() {
    Column({ space: 16 }) {
      // 标题已在UnifiedHeader中显示，这里不再重复显示

      if (this.selectedScheme && this.selectedScheme.id === 'system') {
        // 系统默认方案：仅提供“试听”，不显示任何录音相关提示/按钮
        if (this.statusMessage) {
          Text(this.statusMessage)
            .fontSize(12)
            .fontColor('#2563eb')
            .backgroundColor('#e0f2fe')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(12)
        }

        Column({ space: 12 }) {
          ForEach(this.audioItems, (item: AudioItem) => {
            Row({ space: 16 }) {
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(item.label)
                    .fontSize(14)
                    .fontColor('#1f2937')
                    .textAlign(TextAlign.Start)
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)

                Text(item.key)
                  .fontSize(12)
                  .fontColor('#6b7280')
                  .textAlign(TextAlign.Start)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Button(this.playingItemId === item.id ? '播放中' : '试听')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor('#3b82f6')
                .borderRadius(10)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .onClick(() => this.playAudio(item))
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 6, color: '#00000008', offsetX: 0, offsetY: 4 })
          })
        }
        .width('100%')
      } else {
        // 非系统方案：保留录音相关提示与按钮
        if (this.selectedScheme) {
          Column({ space: 12 }) {
            Text('录音提示')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')

            Text('点击下方按钮开始录制，保持发音清晰，保持愉快的语调。')
              .fontSize(14)
              .fontColor('#6b7280')
              .lineHeight(20)

          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .backgroundColor('#eff6ff')
          .borderRadius(20)
        }

        if (this.statusMessage && this.statusMessage !== '录制完成') {
          Text(this.statusMessage)
            .fontSize(12)
            .fontColor('#2563eb')
            .backgroundColor('#e0f2fe')
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .borderRadius(12)
        }

        Column({ space: 12 }) {
          ForEach(this.audioItems, (item: AudioItem) => {
            Row({ space: 16 }) {
              Column({ space: 4 }) {
                Row({ space: 8 }) {
                  Text(item.label)
                    .fontSize(14)
                    .fontColor('#1f2937')
                    .textAlign(TextAlign.Start)
                  
                  if (this.isItemRecorded(item.id)) {
                    Text('✓ 已录制')
                      .fontSize(12)
                      .fontColor('#10b981')
                      .fontWeight(FontWeight.Bold)
                  }
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
                
                Text(item.key)
                  .fontSize(12)
                  .fontColor('#6b7280')
                  .textAlign(TextAlign.Start)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              Row({ space: 8 }) {
                Button(this.playingItemId === item.id ? '播放中' : '试听')
                  .fontSize(12)
                  .fontColor(Color.White)
                  .backgroundColor('#3b82f6')
                  .borderRadius(10)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .onClick(() => this.playAudio(item))

                Button(this.getRecordingButtonText(item.id))
                  .fontSize(12)
                  .fontColor(Color.White)
                  .backgroundColor(this.getRecordingButtonColor(item.id))
                  .borderRadius(10)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .enabled(!this.isRecording || this.recordingItemId === item.id)
                  .onClick(() => this.startRecording(item.id))
              }
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12, bottom: 12 })
            .backgroundColor(Color.White)
            .borderRadius(16)
            .shadow({ radius: 6, color: '#00000008', offsetX: 0, offsetY: 4 })
          })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 24 })
  }

  build() {
    Column({ space: 16 }) {
      // 统一标题栏
      UnifiedHeader({
        title: this.currentView === 'recording'
          ? (this.selectedScheme?.id === 'system' ? '系统默认' : `${this.selectedScheme?.name || '语音方案'}`)
          : '语音选择',
        onBack: () => { this.handleBackNavigation() },
      })

      if (this.currentView === 'list') {
        Scroll() {
          this.SchemeListView()
        }
        .layoutWeight(1)
      } else if (this.currentView === 'recording') {
        Scroll() {
          Column() {
            this.RecordingView()
            
            // 删除按钮放在滚动内容的最底部
            if (this.selectedScheme && this.selectedScheme.id !== 'system') {
              Button('删除方案')
                .fontSize(16)
                .fontColor('#dc2626')
                .backgroundColor('#fef2f2')
                .borderRadius(12)
                .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                .margin({ left: 16, right: 16, top: 24, bottom: 24 })
                .onClick(() => {
                  this.schemeToDelete = this.selectedScheme
                  this.showDeleteDialog = true
                })
            }
          }
        }
        .layoutWeight(1)
      }

      if (this.showCreateDialog) {
        Column() {
          Column({ space: 16 }) {
            Text('创建自定义语音方案')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')

            TextInput({ placeholder: '输入方案名称', text: this.newSchemeName })
              .fontSize(14)
              .height(44)
              .backgroundColor('#f9fafb')
              .borderRadius(10)
              .onChange((value: string) => {
                this.newSchemeName = value
              })

            Row({ space: 12 }) {
              Button('取消')
                .fontSize(14)
                .fontColor('#6b7280')
                .backgroundColor(Color.White)
                .borderRadius(12)
                .layoutWeight(1)
                .onClick(() => {
                  this.showCreateDialog = false
                  this.newSchemeName = ''
                })

              Button('创建')
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor('#3b82f6')
                .borderRadius(12)
                .layoutWeight(1)
                .onClick(() => {
                  this.createNewScheme()
                })
            }
          }
          .width(320)
          .padding({ left: 24, right: 24, top: 24, bottom: 24 })
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 20, color: '#00000030', offsetX: 0, offsetY: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.showCreateDialog = false
          this.newSchemeName = ''
        })
      }

      if (this.showDeleteDialog && this.schemeToDelete) {
        // 全屏半透明遮罩，透出下层界面
        Column() {
          Column({ space: 16 }) {
            Text('确认删除')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')

            Text(`确定要删除语音方案"${this.schemeToDelete.name}"吗？\n删除后将无法恢复所有录音文件。`)
              .fontSize(14)
              .fontColor('#6b7280')
              .textAlign(TextAlign.Center)

            Row({ space: 12 }) {
              Button('取消')
                .fontSize(14)
                .fontColor('#6b7280')
                .backgroundColor(Color.White)
                .borderRadius(12)
                .layoutWeight(1)
                .onClick(() => {
                  this.showDeleteDialog = false
                  this.schemeToDelete = null
                })

              Button('删除')
                .fontSize(14)
                .fontColor(Color.White)
                .backgroundColor('#dc2626')
                .borderRadius(12)
                .layoutWeight(1)
                .onClick(() => {
                  if (this.schemeToDelete) {
                    this.deleteScheme(this.schemeToDelete.id)
                    this.showDeleteDialog = false
                    this.schemeToDelete = null
                    // 删除后回到列表页面
                    this.currentView = 'list'
                    this.selectedScheme = null
                  }
                })
            }
          }
          .width(320)
          .padding({ left: 24, right: 24, top: 24, bottom: 24 })
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 20, color: '#00000030', offsetX: 0, offsetY: 10 })
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 })
        .onClick(() => {
          this.showDeleteDialog = false
          this.schemeToDelete = null
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7ff')
  }

  private getRecordingButtonText(itemId: string): string {
    if (this.isRecording && this.recordingItemId === itemId) {
      return '录制中...'
    } else if (this.isItemRecorded(itemId)) {
      return '重新录制'
    } else {
      return '开始录制'
    }
  }

  private getRecordingButtonColor(itemId: string): string {
    if (this.isRecording && this.recordingItemId === itemId) {
      return '#ef4444'
    } else if (this.isItemRecorded(itemId)) {
      return '#f59e0b'
    } else {
      return '#fb7185'
    }
  }
}
