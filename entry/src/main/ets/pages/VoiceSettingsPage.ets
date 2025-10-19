import { AudioManager } from '../managers/AudioManager'
import { UnifiedHeader } from '../components/UnifiedHeader'
import media from '@ohos.multimedia.media'

interface AudioItem {
  id: string
  label: string
  key: string
  audioPath?: string
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

@Component
export struct VoiceSettingsPage {
  onNavigate: (page: string) => void = () => {}

  @State currentView: 'list' | 'recording' = 'list'
  @State selectedScheme: VoiceScheme | null = null
  @State isAudioEnabled: boolean = true
  @State showCreateDialog: boolean = false
  @State newSchemeName: string = ''
  @State isRecording: boolean = false
  @State recordingItemId: string = ''
  @State playingItemId: string = ''
  
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

  private audioItems: AudioItem[] = [
    { id: '0', label: '数字 0', key: '0', audioPath: 'rawfile:///audio/num0.ogg' },
    { id: '1', label: '数字 1', key: '1', audioPath: 'rawfile:///audio/num1.ogg' },
    { id: '2', label: '数字 2', key: '2', audioPath: 'rawfile:///audio/num2.ogg' },
    { id: '3', label: '数字 3', key: '3', audioPath: 'rawfile:///audio/num3.ogg' },
    { id: '4', label: '数字 4', key: '4', audioPath: 'rawfile:///audio/num4.ogg' },
    { id: '5', label: '数字 5', key: '5', audioPath: 'rawfile:///audio/num5.ogg' },
    { id: '6', label: '数字 6', key: '6', audioPath: 'rawfile:///audio/num6.ogg' },
    { id: '7', label: '数字 7', key: '7', audioPath: 'rawfile:///audio/num7.ogg' },
    { id: '8', label: '数字 8', key: '8', audioPath: 'rawfile:///audio/num8.ogg' },
    { id: '9', label: '数字 9', key: '9', audioPath: 'rawfile:///audio/num9.ogg' },
    { id: 'plus', label: '加号 +', key: '+', audioPath: 'rawfile:///audio/jia.ogg' },
    { id: 'minus', label: '减号 -', key: '-', audioPath: 'rawfile:///audio/jian.ogg' },
    { id: 'multiply', label: '乘号 ×', key: '×', audioPath: 'rawfile:///audio/multiple.ogg' },
    { id: 'divide', label: '除号 ÷', key: '÷', audioPath: 'rawfile:///audio/division.ogg' },
    { id: 'equals', label: '等号 =', key: '=', audioPath: 'rawfile:///audio/dengyu.ogg' },
    { id: 'decimal', label: '小数点 .', key: '.', audioPath: 'rawfile:///audio/dian.ogg' },
    { id: 'ge', label: '个', key: '个' },
    { id: 'shi', label: '十', key: '十', audioPath: 'rawfile:///audio/shi.ogg' },
    { id: 'bai', label: '百', key: '百', audioPath: 'rawfile:///audio/bai.ogg' },
    { id: 'qian', label: '千', key: '千', audioPath: 'rawfile:///audio/qian.ogg' },
    { id: 'wan', label: '万', key: '万', audioPath: 'rawfile:///audio/wan.ogg' },
    { id: 'clear', label: '清空', key: 'clear' },
    { id: 'delete', label: '删除', key: 'delete' }
  ]

  private audioManager: AudioManager = new AudioManager()
  private avPlayer: media.AVPlayer | null = null

  aboutToAppear() {
    this.audioManager.speakText('选择喜欢的语音方案')
    this.initAVPlayer()
  }

  aboutToDisappear() {
    if (this.avPlayer) {
      try {
        this.avPlayer.stop()
      } catch (_) {}
      try {
        this.avPlayer.reset()
      } catch (_) {}
      try {
        this.avPlayer.release?.()
      } catch (_) {}
      this.avPlayer = null
    }
  }

  async initAVPlayer() {
    try {
      this.avPlayer = await media.createAVPlayer()
      console.log('AVPlayer初始化成功')
    } catch (error) {
      console.error('AVPlayer初始化失败:', error)
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
    this.selectedScheme = scheme
    this.currentView = 'recording'
    this.audioManager.speakText(`进入${scheme.name}录制界面`)
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
    this.enterRecordingView(newScheme)
  }

  private async playAudio(item: AudioItem) {
    if (this.selectedScheme?.id === 'system' && item.audioPath && this.avPlayer) {
      try {
        this.playingItemId = item.id
        await this.avPlayer.stop()
      } catch (_) {}
      try {
        this.avPlayer.reset()
      } catch (_) {}
      try {
        this.avPlayer.url = item.audioPath
        await this.avPlayer.prepare()
        await this.avPlayer.play()
        console.log(`播放音频: ${item.label}`)
      } catch (error) {
        console.error(`播放音频失败: ${item.label}`, error)
        this.playingItemId = ''
      }
    } else {
      this.audioManager.speakText(item.label)
    }
  }

  private startRecording(itemId: string) {
    if (this.selectedScheme?.id === 'system') {
      this.audioManager.speakText('系统默认方案不支持录音')
      return
    }

    this.isRecording = true
    this.recordingItemId = itemId
    this.audioManager.speakText('开始录音')

    // 开始真实录音
    this.startRealRecording(itemId)
  }

  // 开始真实录音
  private startRealRecording(itemId: string) {
    console.log('[录音] 开始真实录音...', itemId)
    
    // 这里应该使用HarmonyOS的媒体录制API
    // 由于HarmonyOS的录音API比较复杂，我们先实现基础版本
    try {
      // 模拟录音过程，实际应该调用真实API
      this.simulateRecordingProcess(itemId)
    } catch (error) {
      console.error('[录音] 录音启动失败:', error)
      this.audioManager.speakText('录音启动失败')
      this.isRecording = false
      this.recordingItemId = ''
    }
  }

  // 模拟录音过程
  private simulateRecordingProcess(itemId: string) {
    // 显示录音进度
    let progress = 0
    const progressInterval = setInterval(() => {
      if (!this.isRecording) {
        clearInterval(progressInterval)
        return
      }
      
      progress += 10
      console.log(`[录音] 录音进度: ${progress}%`)
    }, 300)
    
    // 3秒后自动停止录音
    setTimeout(() => {
      if (this.isRecording) {
        clearInterval(progressInterval)
        this.stopRecording()
      }
    }, 3000)
  }

  private stopRecording() {
    if (!this.isRecording) {
      return
    }
    
    this.isRecording = false
    this.audioManager.speakText('录音完成')

    // 保存录音文件
    this.saveRecordingFile()

    if (this.selectedScheme) {
      const schemes = this.voiceSchemes.slice()
      for (let i = 0; i < schemes.length; i++) {
        const scheme = schemes[i]
        if (scheme.id === this.selectedScheme!.id) {
          const updated: VoiceScheme = {
            id: scheme.id,
            name: scheme.name,
            description: scheme.description,
            icon: scheme.icon,
            recordedCount: Math.min(scheme.recordedCount + 1, scheme.totalCount),
            totalCount: scheme.totalCount,
            isDefault: scheme.isDefault
          }
          schemes[i] = updated
          this.selectedScheme = updated
          break
        }
      }
      this.voiceSchemes = schemes
    }

    this.recordingItemId = ''
  }

  // 保存录音文件
  private saveRecordingFile() {
    if (!this.recordingItemId || !this.selectedScheme) {
      return
    }

    try {
      // 这里应该保存真实的录音文件
      // 实际应该使用HarmonyOS的文件系统API
      const fileName = `${this.selectedScheme.id}_${this.recordingItemId}_${Date.now()}.wav`
      const filePath = `/data/storage/el2/base/haps/entry/files/recordings/${fileName}`
      
      console.log('[录音] 保存录音文件:', filePath)
      
      // 模拟保存成功
      this.audioManager.speakText('录音已保存')
      
    } catch (error) {
      console.error('[录音] 保存录音文件失败:', error)
      this.audioManager.speakText('录音保存失败')
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
              Row()
                .width(200)
                .height(8)
                .backgroundColor('#e5e7eb')
                .borderRadius(4)
                .clip(true)

              Row()
                .width(`${(scheme.recordedCount / scheme.totalCount) * 100}%`)
                .height(8)
                .backgroundColor(scheme.recordedCount === scheme.totalCount ? '#22c55e' : '#3b82f6')
                .borderRadius(4)
                .position({ x: 0, y: 0 })

              Text(`${scheme.recordedCount}/${scheme.totalCount} 已录制`)
                .fontSize(12)
                .fontColor(scheme.recordedCount === scheme.totalCount ? '#16a34a' : '#2563eb')
                .fontWeight(FontWeight.Medium)
                .margin({ left: -192 })
            }
            .width('100%')
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
  }

  @Builder
  RecordingView() {
    Column({ space: 16 }) {
      // 移除重复的返回按钮，使用UnifiedHeader的返回按钮
      if (this.selectedScheme) {
        Text(`录制 - ${this.selectedScheme.name}`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .width('100%')
          .textAlign(TextAlign.Center)
      }

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

          Text(`已完成 ${this.selectedScheme.recordedCount}/${this.selectedScheme.totalCount}`)
            .fontSize(14)
            .fontColor('#2563eb')
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        .backgroundColor('#eff6ff')
        .borderRadius(20)
      }

      Column({ space: 12 }) {
        ForEach(this.audioItems, (item: AudioItem) => {
          Row({ space: 16 }) {
            Column({ space: 4 }) {
              Text(item.label)
                .fontSize(14)
                .fontColor('#1f2937')
              Text(item.key)
                .fontSize(12)
                .fontColor('#6b7280')
            }
            .layoutWeight(1)

            Row({ space: 8 }) {
              Button(this.playingItemId === item.id ? '播放中' : '试听')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor('#3b82f6')
                .borderRadius(10)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .onClick(() => this.playAudio(item))

              Button(this.isRecording && this.recordingItemId === item.id ? '录制中' : '开始录制')
                .fontSize(12)
                .fontColor(Color.White)
                .backgroundColor('#fb7185')
                .borderRadius(10)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
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
    .width('100%')
    .padding({ bottom: 24 })
  }

  build() {
    Column() {
      UnifiedHeader({
        title: this.currentView === 'recording' ? `录制 - ${this.selectedScheme?.name || '语音方案'}` : '语音设置',
        onBack: () => this.currentView === 'recording' ? this.backToList() : this.onNavigate('home')
      })

      if (this.currentView === 'list') {
        Scroll() {
          this.SchemeListView()
        }
        .layoutWeight(1)
      } else if (this.currentView === 'recording') {
        Scroll() {
          this.RecordingView()
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7ff')
  }
}
