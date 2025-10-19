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

@Component
export struct LearningReportPage {
  onNavigate: (page: string) => void = () => {}

  @State activeTab: ReportTab = 'progress'
  @State progress: ProgressSummary = {
    studyMinutes: 126,
    correctRate: 92,
    totalQuestions: 134,
    streak: 5
  }
  @State wrongQuestions: WrongQuestionItem[] = [
    { id: 'w1', question: '17 + 9 = ?', userAnswer: '24', correctAnswer: '26', type: 'addition', date: '2024-03-01' },
    { id: 'w2', question: '45 - 19 = ?', userAnswer: '24', correctAnswer: '26', type: 'subtraction', date: '2024-03-03' },
    { id: 'w3', question: '8 × 7 = ?', userAnswer: '48', correctAnswer: '56', type: 'multiplication', date: '2024-03-05' }
  ]
  @State achievements: AchievementCard[] = []
  
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

  private audioManager: AudioManager = new AudioManager()
  private storageManager: StorageManager = StorageManager.getInstance()

  async aboutToAppear() {
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
  }

  private setTab(tab: ReportTab) {
    this.activeTab = tab
    // 播放切换提示音而不是随机数字
    this.audioManager.speakText('切换到' + this.getTabLabel(tab))
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

      // 本周学习趋势
      Column({ space: 8 }) {
        Text('本周学习趋势')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#374151')

        Row({ space: 6 }) {
          ForEach([1, 2, 3, 4, 5, 6, 7], (day: number) => {
            Column({ space: 4 }) {
              Text(day.toString())
                .fontSize(11)
                .fontColor('#6b7280')
              
              Column()
                .width(16)
                .height(Math.random() * 30 + 15)
                .backgroundColor('#3b82f6')
                .borderRadius(3)
            }
            .alignItems(HorizontalAlign.Center)
          })
        }
        .justifyContent(FlexAlign.SpaceEvenly)
        .width('100%')
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
    Column({ space: 12 }) {
      // 错题统计
      Row({ space: 12 }) {
        this.MetricCard('错题总数', `${this.wrongQuestions.length} 道`, '#ef4444')
        this.MetricCard('已复习', '2 道', '#22c55e')
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
                
                Button('复习')
                  .fontSize(12)
                  .fontColor('#3b82f6')
                  .backgroundColor('#dbeafe')
                  .borderRadius(12)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .onClick(() => {
                    this.audioManager.speakText(`复习题目：${item.question}`)
                  })
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
        this.MetricCard('本周学习', `${this.dailyProgress.reduce((sum, item) => sum + item.minutes, 0)} 分钟`, '#3b82f6')
        this.MetricCard('本周题目', `${this.dailyProgress.reduce((sum, item) => sum + item.questions, 0)} 道`, '#22c55e')
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
        onBack: () => { this.onNavigate('home') }
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
