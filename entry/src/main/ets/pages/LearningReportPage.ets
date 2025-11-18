import { AudioManager } from '../managers/AudioManager'
import { UnifiedHeader } from '../components/UnifiedHeader'
import { StorageManager } from '../managers/StorageManager'
import common from '@ohos.app.ability.common'

type ReportTab = 'progress' | 'mistakes' | 'achievements' | 'calendar'

interface ProgressSummary {
  studyMinutes: number
  correctRate: number
  totalQuestions: number
  streak: number
}

interface WrongQuestionItem {
  id: string
  question: string
  userAnswer: string
  correctAnswer: string
  type: string
  date: string
}

interface AchievementCard {
  id: string
  name: string
  description: string
  icon: string
  earned: boolean
  rarity: string
}

interface DailyProgressItem {
  date: string
  questions: number
  correctRate: number
  minutes: number
}

interface WrongQuestionStats {
  addition: number
  subtraction: number
  multiplication: number
  division: number
  reviewed: number
}

@Component
export struct LearningReportPage {
  onNavigate: (page: string) => void = () => {}
  registerBackHandler: (handler: (() => boolean) | null) => void = () => {}

  @State activeTab: ReportTab = 'progress'
  @State progress: ProgressSummary = {
    studyMinutes: 0,
    correctRate: 0,
    totalQuestions: 0,
    streak: 0
  }
  @State wrongQuestions: WrongQuestionItem[] = []
  @State achievements: AchievementCard[] = []
  @State wrongQuestionStats: WrongQuestionStats = {
    addition: 0,
    subtraction: 0,
    multiplication: 0,
    division: 0,
    reviewed: 0
  }
  
  // 错题重练模式状态
  @State practiceMode: boolean = false
  @State currentQuestionIndex: number = 0
  @State userInput: string = ''
  @State showResult: boolean = false
  @State isAnswerCorrect: boolean = false
  
  // 生成成就列表
  private generateAchievements() {
    const totalQuestions = this.progress.totalQuestions
    const correctRate = this.progress.correctRate
    const streak = this.progress.streak
    const studyMinutes = this.progress.studyMinutes
    
    this.achievements = [
      // 普通成就
      { id: 'a1', name: '初出茅庐', description: '完成 10 道题目', icon: '🌱', earned: totalQuestions >= 10, rarity: 'common' },
      { id: 'a2', name: '小试牛刀', description: '完成 50 道题目', icon: '📝', earned: totalQuestions >= 50, rarity: 'common' },
      { id: 'a3', name: '勤学苦练', description: '完成 100 道题目', icon: '📚', earned: totalQuestions >= 100, rarity: 'common' },
      { id: 'a4', name: '学习达人', description: '完成 200 道题目', icon: '🎓', earned: totalQuestions >= 200, rarity: 'rare' },
      
      // 稀有成就
      { id: 'a5', name: '坚持不懈', description: '连续学习 3 天', icon: '📅', earned: streak >= 3, rarity: 'rare' },
      { id: 'a6', name: '持之以恒', description: '连续学习 7 天', icon: '🔥', earned: streak >= 7, rarity: 'rare' },
      { id: 'a7', name: '百折不挠', description: '连续学习 30 天', icon: '💪', earned: streak >= 30, rarity: 'epic' },
      
      // 史诗成就
      { id: 'a8', name: '精准答题', description: '正确率达到 80%', icon: '🎯', earned: correctRate >= 80, rarity: 'epic' },
      { id: 'a9', name: '完美主义', description: '正确率达到 90%', icon: '💯', earned: correctRate >= 90, rarity: 'epic' },
      { id: 'a10', name: '神级选手', description: '正确率达到 95%', icon: '👑', earned: correctRate >= 95, rarity: 'legendary' },
      
      // 传说成就
      { id: 'a11', name: '时间管理', description: '累计学习 60 分钟', icon: '⏰', earned: studyMinutes >= 60, rarity: 'rare' },
      { id: 'a12', name: '刻苦钻研', description: '累计学习 120 分钟', icon: '📖', earned: studyMinutes >= 120, rarity: 'epic' },
      { id: 'a13', name: '学霸之路', description: '累计学习 300 分钟', icon: '🌟', earned: studyMinutes >= 300, rarity: 'legendary' },
      
      // 特殊成就
      { id: 'a14', name: '全勤之星', description: '完成所有练习模式', icon: '⭐', earned: false, rarity: 'epic' },
      { id: 'a15', name: '挑战高手', description: '完成 10 次游戏挑战', icon: '🏆', earned: false, rarity: 'legendary' }
    ]
  }
  @State dailyProgress: DailyProgressItem[] = []

  // 生成最近7天的学习数据（已删除模拟数据）
  private generateDailyProgress() {
    // 此方法已不再使用，现在使用真实的存储数据
    // 模拟数据已完全移除
    this.dailyProgress = []
  }

  private audioManager: AudioManager = AudioManager.getInstance()
  private storageManager: StorageManager = StorageManager.getInstance()

  private handleBackNavigation(): boolean {
    this.onNavigate('home')
    return true
  }
  
  

  async aboutToAppear() {
    this.registerBackHandler(() => this.handleBackNavigation())
    try {
      const abilityContext = getContext(this) as common.UIAbilityContext
      if (abilityContext) {
        await this.storageManager.init(abilityContext)
      }
    } catch (error) {
      console.error('学习报告页面初始化存储失败:', error)
    }
    await this.loadRealData()
    this.generateAchievements()
    this.audioManager.speakText('这里是你的学习报告，看看今天的表现吧')
  }

  aboutToDisappear() {
    this.registerBackHandler(null)
  }
  
  // 加载真实学习数据
  private async loadRealData() {
    // 加载学习统计
    const stats = await this.storageManager.loadStudyStats()
    this.progress = {
      studyMinutes: stats.totalTime,
      correctRate: Math.round(stats.correctRate),
      totalQuestions: stats.totalQuestions,
      streak: stats.currentStreak
    }
    
    // 加载错题列表
    const wrongQuestions = await this.storageManager.loadWrongQuestions()
    this.wrongQuestions = wrongQuestions
      .filter(q => !q.mastered)
      .slice(0, 10) // 只显示前10个未掌握的错题
      .map(q => {
        const item: WrongQuestionItem = {
          id: q.id,
          question: q.question,
          userAnswer: q.userAnswer,
          correctAnswer: q.correctAnswer,
          type: q.type,
          date: q.date
        }
        return item
      })
    
    // 加载每日进度
    const dailyProgress = await this.storageManager.loadDailyProgress()
    if (dailyProgress.length > 0) {
      // 使用真实的每日进度数据
      this.dailyProgress = dailyProgress.slice(-7).map(p => {
        const item: DailyProgressItem = {
          date: p.date.substring(5), // 只保留 MM-DD
          questions: p.questionsAnswered,
          correctRate: Math.round(p.correctRate),
          minutes: Math.round(p.timeSpent)
        }
        return item
      })
    } else {
      // 如果没有数据，显示空状态而不是模拟数据
      this.dailyProgress = []
    }
    
    // 加载错题统计
    const allWrongQuestions = await this.storageManager.loadWrongQuestions()
    this.wrongQuestionStats = {
      addition: allWrongQuestions.filter((q) => q.type === 'addition').length,
      subtraction: allWrongQuestions.filter((q) => q.type === 'subtraction').length,
      multiplication: allWrongQuestions.filter((q) => q.type === 'multiplication').length,
      division: allWrongQuestions.filter((q) => q.type === 'division').length,
      reviewed: allWrongQuestions.filter((q) => q.mastered).length
    }
  }

  private setTab(tab: ReportTab) {
    this.activeTab = tab
    // 播放切换提示音而不是随机数字
    this.audioManager.speakText('切换到' + this.getTabLabel(tab))
  }
  
  // 开始错题重练
  private async startWrongQuestionReview(item: WrongQuestionItem) {
    try {
      // 找到错题在列表中的索引
      const index = this.wrongQuestions.findIndex(q => q.id === item.id)
      if (index >= 0) {
        this.currentQuestionIndex = index
        this.practiceMode = true
        this.userInput = ''
        this.showResult = false
        this.isAnswerCorrect = false
        this.audioManager.speakText(`开始重练：${item.question}`)
      }
    } catch (error) {
      console.error('启动重练失败:', error)
      this.audioManager.speakText('启动失败，请稍后重试')
    }
  }
  
  // 提交答案
  private submitAnswer() {
    const currentQuestion = this.wrongQuestions[this.currentQuestionIndex]
    const correct = this.userInput.trim() === currentQuestion.correctAnswer.trim()
    this.isAnswerCorrect = correct
    this.showResult = true
    
    if (correct) {
      this.audioManager.speakText('答对了，太棒了')
    } else {
      this.audioManager.speakText(`答错了，正确答案是${currentQuestion.correctAnswer}`)
    }
  }
  
  // 下一题
  private nextQuestion() {
    if (this.currentQuestionIndex < this.wrongQuestions.length - 1) {
      this.currentQuestionIndex += 1
      this.userInput = ''
      this.showResult = false
      this.isAnswerCorrect = false
      const nextQ = this.wrongQuestions[this.currentQuestionIndex]
      this.audioManager.speakText(`下一题：${nextQ.question}`)
    } else {
      this.exitPractice()
      this.audioManager.speakText('重练完成，继续加油')
    }
  }
  
  // 退出重练
  private exitPractice() {
    this.practiceMode = false
    this.currentQuestionIndex = 0
    this.userInput = ''
    this.showResult = false
    this.isAnswerCorrect = false
  }

  private getTabLabel(tab: ReportTab): string {
    switch (tab) {
      case 'progress': return '进度'
      case 'mistakes': return '错题'
      case 'achievements': return '成就'
      case 'calendar': return '日历'
      default: return '报告'
    }
  }

  private calculateBarHeight(questions: number): number {
    return Math.max(8, Math.min(30, questions * 2))
  }

  private calculateBarHeightFromMinutes(minutes: number): number {
    return Math.max(8, Math.min(30, minutes * 3))
  }

  private getAvgCorrectRate(): number {
    if (this.dailyProgress.length === 0) {
      return 0
    }
    return Math.round(this.dailyProgress.reduce((sum, item) => sum + item.correctRate, 0) / this.dailyProgress.length)
  }

  private getTotalMinutes(): number {
    return this.dailyProgress.reduce((sum, item) => sum + item.minutes, 0)
  }

  private getTotalQuestions(): number {
    return this.dailyProgress.reduce((sum, item) => sum + item.questions, 0)
  }
  
  // 获取趋势指示器
  private getTrendIndicator(): string {
    const avgRate = this.getAvgCorrectRate()
    if (avgRate > 80) return '📈 进步中'
    if (avgRate > 60) return '📊 稳定'
    return '📉 需加油'
  }
  
  // 获取趋势颜色
  private getTrendColor(): string {
    const avgRate = this.getAvgCorrectRate()
    if (avgRate > 80) return '#16a34a'
    if (avgRate > 60) return '#ca8a04'
    return '#dc2626'
  }
  
  // 获取趋势背景色
  private getTrendBgColor(): string {
    const avgRate = this.getAvgCorrectRate()
    if (avgRate > 80) return '#dcfce7'
    if (avgRate > 60) return '#fef3c7'
    return '#fee2e2'
  }

  @Builder
  TabButton(tab: ReportTab, label: string) {
    Button(label)
      .fontSize(12)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.activeTab === tab ? Color.White : '#1f2937')
      .backgroundColor(this.activeTab === tab ? '#a855f7' : Color.White)
      .borderRadius(16)
      .padding({ left: 8, right: 8, top: 6, bottom: 6 })
      .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
      .onClick(() => { this.setTab(tab) })
  }

  @Builder
  ProgressTab() {
    Column({ space: 8 }) {
      // 总体统计卡片
      Column({ space: 8 }) {
        Text('总体表现')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
          .width('100%')

        Row({ space: 12 }) {
          this.MetricCard('学习时长', `${this.progress.studyMinutes} 分钟`, '#38bdf8')
          this.MetricCard('正确率', `${this.progress.correctRate}%`, '#f97316')
        }
        .width('100%')

        Row({ space: 12 }) {
          this.MetricCard('完成题目', `${this.progress.totalQuestions} 道`, '#22c55e')
          this.MetricCard('连续学习', `${this.progress.streak} 天`, '#facc15')
        }
        .width('100%')
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })

      // 学习建议卡片
      Column({ space: 8 }) {
        Text('学习建议')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#374151')

        Text('保持良好的学习节奏，尝试挑战难度更高的题目，巩固计算能力。')
          .fontSize(13)
          .fontColor('#4b5563')
          .lineHeight(18)
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
      
      // 学习趋势指示器
      Column({ space: 8 }) {
        Row() {
          Text('学习趋势')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#374151')
          
          Blank()
          
          // 趋势指示
          Row({ space: 6 }) {
            Text(this.getTrendIndicator())
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getTrendColor())
              .padding({ left: 12, right: 12, top: 4, bottom: 4 })
              .backgroundColor(this.getTrendBgColor())
              .borderRadius(12)
          }
        }
        .width('100%')
        
        Text(`最近7天平均正确率: ${this.getAvgCorrectRate()}%`)
          .fontSize(13)
          .fontColor('#6b7280')
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })

      // 本周学习趋势 - 每日答题数量
      Column({ space: 8 }) {
        Text('每日答题数量')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#374151')

        if (this.dailyProgress.length > 0) {
          Row({ space: 6 }) {
            ForEach(this.dailyProgress, (item: DailyProgressItem, index: number) => {
              Column({ space: 4 }) {
                Text(item.date.substring(3))
                  .fontSize(11)
                  .fontColor('#6b7280')
                
                Column()
                  .width(16)
                  .height(this.calculateBarHeight(item.questions))
                  .backgroundColor('#3b82f6')
                  .borderRadius(3)
              }
              .alignItems(HorizontalAlign.Center)
            })
          }
          .justifyContent(FlexAlign.SpaceEvenly)
          .width('100%')
        } else {
          Text('暂无学习数据')
            .fontSize(13)
            .fontColor('#9ca3af')
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 20, bottom: 20 })
        }
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
      
      // 每日学习时长分布
      Column({ space: 8 }) {
        Text('每日学习时长分布')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#374151')

        if (this.dailyProgress.length > 0) {
          Row({ space: 6 }) {
            ForEach(this.dailyProgress, (item: DailyProgressItem, index: number) => {
              Column({ space: 4 }) {
                Text(item.date.substring(3))
                  .fontSize(11)
                  .fontColor('#6b7280')
                
                Column()
                  .width(16)
                  .height(this.calculateBarHeightFromMinutes(item.minutes))
                  .backgroundColor('#22c55e')
                  .borderRadius(3)
              }
              .alignItems(HorizontalAlign.Center)
            })
          }
          .justifyContent(FlexAlign.SpaceEvenly)
          .width('100%')
        } else {
          Text('暂无学习数据')
            .fontSize(13)
            .fontColor('#9ca3af')
            .textAlign(TextAlign.Center)
            .width('100%')
            .padding({ top: 20, bottom: 20 })
        }
      }
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
    }
  }

  @Builder
  MetricCard(title: string, value: string, color: string) {
    Column({ space: 6 }) {
      Text(value)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')
      Text(title)
        .fontSize(11)
        .fontColor('#6b7280')
    }
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 8, color: '#00000008', offsetX: 0, offsetY: 4 })
    .border({ width: 2, color })
    .layoutWeight(1)
  }

  @Builder
  MistakeTab() {
    // 如果处于重练模式，显示重练界面
    if (this.practiceMode) {
      this.PracticeModeView()
      return
    }
    
    Column({ space: 12 }) {
      // 错题统计
      Row({ space: 12 }) {
        this.MetricCard('错题总数', `${this.wrongQuestions.length} 道`, '#ef4444')
        this.MetricCard('已复习', `${this.wrongQuestionStats.reviewed} 道`, '#22c55e')
      }
      .width('100%')
      
      // 错题类型统计
      Row({ space: 8 }) {
        this.MetricCard('加法', `${this.wrongQuestionStats.addition}`, '#f59e0b')
        this.MetricCard('减法', `${this.wrongQuestionStats.subtraction}`, '#10b981')
        this.MetricCard('乘法', `${this.wrongQuestionStats.multiplication}`, '#a855f7')
        this.MetricCard('除法', `${this.wrongQuestionStats.division}`, '#ef4444')
      }
      .width('100%')

      // 错题列表
      Column({ space: 8 }) {
        Text('错题回顾')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
          .width('100%')

        if (this.wrongQuestions.length === 0) {
          Column({ space: 8 }) {
            Text('🎉')
              .fontSize(40)
              .textAlign(TextAlign.Center)
              .width('100%')
            Text('太棒了！没有错题')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#22c55e')
              .textAlign(TextAlign.Center)
              .width('100%')
            Text('继续保持，继续努力！')
              .fontSize(12)
              .fontColor('#6b7280')
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .padding({ left: 16, right: 16, top: 20, bottom: 20 })
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
        } else {
          ForEach(this.wrongQuestions, (item: WrongQuestionItem) => {
            Column({ space: 12 }) {
              Row({ space: 8 }) {
                Text(item.question)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1f2937')
                  .layoutWeight(1)
                
                Row({ space: 8 }) {
                  Button('复习')
                    .fontSize(12)
                    .fontColor('#3b82f6')
                    .backgroundColor('#dbeafe')
                    .borderRadius(12)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => {
                      this.audioManager.speakText(`复习题目：${item.question}`)
                    })
                  Button('重练')
                    .fontSize(12)
                    .fontColor('#22c55e')
                    .backgroundColor('#dcfce7')
                    .borderRadius(12)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(async () => {
                      await this.startWrongQuestionReview(item)
                    })
                }
              }
              .width('100%')

              Row({ space: 12 }) {
                Column({ space: 4 }) {
                  Text('我的答案')
                    .fontSize(12)
                    .fontColor('#6b7280')
                  Text(item.userAnswer)
                    .fontSize(14)
                    .fontColor('#ef4444')
                    .fontWeight(FontWeight.Medium)
                }
                .layoutWeight(1)

                Column({ space: 4 }) {
                  Text('正确答案')
                    .fontSize(12)
                    .fontColor('#6b7280')
                  Text(item.correctAnswer)
                    .fontSize(14)
                    .fontColor('#22c55e')
                    .fontWeight(FontWeight.Medium)
                }
                .layoutWeight(1)
              }
              .width('100%')

              Text(`题型：${item.type} · 日期：${item.date}`)
                .fontSize(12)
                .fontColor('#6b7280')
            }
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor(Color.White)
            .borderRadius(20)
            .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
          })
        }
      }
    }
  }
  
  @Builder
  PracticeModeView() {
    const currentQuestion = this.wrongQuestions[this.currentQuestionIndex]
    
    Column({ space: 16 }) {
      // 头部
      Row() {
        Button('退出练习')
          .fontSize(14)
          .fontColor('#ef4444')
          .backgroundColor('#fee2e2')
          .borderRadius(16)
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .onClick(() => this.exitPractice())
        
        Blank()
        
        Column({ space: 4 }) {
          Text('错题重练')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
          Text(`第 ${this.currentQuestionIndex + 1} 题 / 共 ${this.wrongQuestions.length} 题`)
            .fontSize(12)
            .fontColor('#6b7280')
        }
        .alignItems(HorizontalAlign.Center)
        
        Blank()
        
        Column().width(80) // 占位元素，保持居中
      }
      .width('100%')
      
      // 题目卡片
      Column({ space: 20 }) {
        Text(currentQuestion.question)
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
        
        Text('=')
          .fontSize(32)
          .fontColor('#6b7280')
          .textAlign(TextAlign.Center)
        
        // 输入框
        TextInput({ placeholder: '?', text: this.userInput })
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Center)
          .width(150)
          .height(60)
          .borderRadius(16)
          .borderWidth(2)
          .borderColor(this.showResult ? (this.isAnswerCorrect ? '#22c55e' : '#ef4444') : '#d1d5db')
          .backgroundColor(Color.White)
          .enabled(!this.showResult)
          .onChange((value: string) => {
            this.userInput = value
          })
        
        // 按钮区
        if (!this.showResult) {
          Button('提交答案')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .backgroundColor(this.userInput ? '#a855f7' : '#d1d5db')
            .borderRadius(20)
            .padding({ left: 32, right: 32, top: 12, bottom: 12 })
            .enabled(this.userInput.length > 0)
            .onClick(() => this.submitAnswer())
        } else {
          Column({ space: 12 }) {
            Text(this.isAnswerCorrect ? '🎉 答对了！' : '❌ 答错了')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isAnswerCorrect ? '#22c55e' : '#ef4444')
            
            if (!this.isAnswerCorrect) {
              Text(`正确答案是: ${currentQuestion.correctAnswer}`)
                .fontSize(18)
                .fontColor('#6b7280')
            }
            
            Button(this.currentQuestionIndex < this.wrongQuestions.length - 1 ? '下一题' : '完成练习')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#3b82f6')
              .borderRadius(20)
              .padding({ left: 32, right: 32, top: 12, bottom: 12 })
              .onClick(() => this.nextQuestion())
          }
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 40, bottom: 40 })
      .backgroundColor(Color.White)
      .borderRadius(24)
      .shadow({ radius: 12, color: '#00000012', offsetX: 0, offsetY: 8 })
    }
  }
  
  @Builder
  AchievementTab() {
    Column({ space: 8 }) {
      // 成就统计
      Row({ space: 12 }) {
        this.MetricCard('已获得', `${this.achievements.filter(a => a.earned).length} 个`, '#22c55e')
        this.MetricCard('总成就', `${this.achievements.length} 个`, '#6b7280')
      }
      .width('100%')

      // 成就列表
      Column({ space: 8 }) {
        Text('成就展示')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
          .width('100%')

        ForEach(this.achievements, (achievement: AchievementCard) => {
          Row({ space: 12 }) {
            Text(achievement.icon)
              .fontSize(26)

            Column({ space: 4 }) {
              Text(achievement.name)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1f2937')
              Text(achievement.description)
                .fontSize(13)
                .fontColor('#6b7280')
              
              // 稀有度标签
              Text(this.getRarityLabel(achievement.rarity))
                .fontSize(10)
                .fontColor(this.getRarityColor(achievement.rarity))
                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                .backgroundColor(this.getRarityBackground(achievement.rarity))
                .borderRadius(8)
            }
            .layoutWeight(1)

            Column({ space: 4 }) {
              Text(achievement.earned ? '已获得' : '待解锁')
                .fontSize(12)
                .fontColor(achievement.earned ? '#22c55e' : '#9ca3af')
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .backgroundColor(achievement.earned ? '#dcfce7' : '#f3f4f6')
                .borderRadius(12)
              
              if (achievement.earned) {
                Text('🎉')
                  .fontSize(16)
              }
            }
            .alignItems(HorizontalAlign.End)
          }
          .padding({ left: 16, right: 16, top: 16, bottom: 16 })
          .backgroundColor(achievement.earned ? '#fef3c7' : Color.White)
          .borderRadius(20)
          .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
          .opacity(achievement.earned ? 1.0 : 0.6)
        })
      }
    }
  }

  private getRarityLabel(rarity: string): string {
    switch (rarity) {
      case 'common': return '普通'
      case 'rare': return '稀有'
      case 'epic': return '史诗'
      case 'legendary': return '传说'
      default: return '普通'
    }
  }

  private getRarityColor(rarity: string): string {
    switch (rarity) {
      case 'common': return '#6b7280'
      case 'rare': return '#3b82f6'
      case 'epic': return '#8b5cf6'
      case 'legendary': return '#f59e0b'
      default: return '#6b7280'
    }
  }

  private getRarityBackground(rarity: string): string {
    switch (rarity) {
      case 'common': return '#f3f4f6'
      case 'rare': return '#dbeafe'
      case 'epic': return '#ede9fe'
      case 'legendary': return '#fef3c7'
      default: return '#f3f4f6'
    }
  }

  @Builder
  CalendarTab() {
    Column({ space: 8 }) {
      // 本周学习统计
      Row({ space: 12 }) {
        this.MetricCard('学习天数', `${this.dailyProgress.length} 天`, '#3b82f6')
        this.MetricCard('答题总数', `${this.getTotalQuestions()} 道`, '#22c55e')
      }
      .width('100%')
      
      Row({ space: 12 }) {
        this.MetricCard('平均正确率', `${this.getAvgCorrectRate()}%`, '#f59e0b')
        this.MetricCard('学习时长', `${this.getTotalMinutes()} 分钟`, '#a855f7')
      }
      .width('100%')

      // 学习日历
      Column({ space: 12 }) {
        Text('学习日历')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
          .width('100%')

        if (this.dailyProgress.length === 0) {
          Column({ space: 8 }) {
            Text('📅')
              .fontSize(48)
              .textAlign(TextAlign.Center)
              .width('100%')
            Text('还没有学习记录')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#6b7280')
              .textAlign(TextAlign.Center)
              .width('100%')
            Text('开始学习，记录你的进步吧！')
              .fontSize(14)
              .fontColor('#9ca3af')
              .textAlign(TextAlign.Center)
              .width('100%')
          }
          .padding({ left: 20, right: 20, top: 30, bottom: 30 })
          .backgroundColor(Color.White)
          .borderRadius(24)
          .shadow({ radius: 12, color: '#00000012', offsetX: 0, offsetY: 8 })
        } else {
          // 学习日历 - 简化版本
          Column({ space: 12 }) {
            // 每日学习记录
            ForEach(this.dailyProgress, (item: DailyProgressItem) => {
              Row({ space: 12 }) {
                // 日期
                Column({ space: 4 }) {
                  Text(item.date)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#1f2937')
                  Text('学习')
                    .fontSize(12)
                    .fontColor('#6b7280')
                }
                .width(60)
                .alignItems(HorizontalAlign.Start)

                // 学习时长条
                Column()
                  .width(Math.max(60, item.minutes * 2))
                  .height(20)
                  .backgroundColor(item.correctRate >= 90 ? '#22c55e' : item.correctRate >= 70 ? '#f59e0b' : '#ef4444')
                  .borderRadius(10)

                // 学习数据
                Column({ space: 4 }) {
                  Text(`${item.minutes} 分钟`)
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1f2937')
                  Text(`${item.questions} 道题 · ${item.correctRate}%`)
                    .fontSize(12)
                    .fontColor('#6b7280')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.End)
              }
              .padding({ left: 12, right: 12, top: 10, bottom: 10 })
              .backgroundColor(Color.White)
              .borderRadius(12)
              .shadow({ radius: 4, color: '#00000008', offsetX: 0, offsetY: 2 })
            })
          }
          .width('100%')
        }
      }
    }
  }

  build() {
    Column() {
      // 统一标题栏
      UnifiedHeader({
        title: '学习报告',
        onBack: () => { this.handleBackNavigation() },
        
      })

      // 标签按钮
      Row({ space: 8 }) {
        this.TabButton('progress', '进度统计')
        this.TabButton('mistakes', '错题回顾')
        this.TabButton('achievements', '成就展示')
        this.TabButton('calendar', '学习日历')
      }
      .margin({ bottom: 16 })

          Scroll() {
            Column() {
              Column() {
                if (this.activeTab === 'progress') {
                  this.ProgressTab()
                } else if (this.activeTab === 'mistakes') {
                  this.MistakeTab()
                } else if (this.activeTab === 'achievements') {
                  this.AchievementTab()
                } else {
                  this.CalendarTab()
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 16, bottom: 16 })
              .backgroundColor('rgba(255,255,255,0.85)')
              .borderRadius(24)
              .shadow({ radius: 12, color: '#00000015', offsetX: 0, offsetY: 8 })
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
          }
          .scrollBar(BarState.Auto)
          .scrollBarColor(Color.Transparent)
          .scrollBarWidth(0)
          .width('100%')
          .layoutWeight(1)
          .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 0, bottom: 24 })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#ede9fe', 0.0], ['#fef3c7', 0.5], ['#bfdbfe', 1.0]]
    })
  }
}
