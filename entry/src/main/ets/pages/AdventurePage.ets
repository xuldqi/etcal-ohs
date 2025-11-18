import { AudioManager } from '../managers/AudioManager'
import { GameChallengePage } from './GameChallengePage'

type GameView = 'levelSelect' | 'playing' | 'achievements'
type Difficulty = 'easy' | 'medium' | 'hard'

interface LevelCard {
  id: number
  name: string
  difficulty: Difficulty
  difficultyLevel: number
  unlocked: boolean
  completed: boolean
  stars: number
  maxStars: number
  bestTime: number
}

interface AchievementItem {
  id: string
  name: string
  description: string
  icon: string
  earned: boolean
}

@Component
export struct AdventurePage {
  onNavigate: (page: string) => void = () => {}
  registerBackHandler: (handler: (() => boolean) | null) => void = () => {}

  @State gameView: GameView = 'levelSelect'
  @State levels: LevelCard[] = [
    { id: 1, name: '数字认知', difficulty: 'easy', difficultyLevel: 1, unlocked: true, completed: false, stars: 0, maxStars: 3, bestTime: 0 },
    { id: 2, name: '简单加法', difficulty: 'easy', difficultyLevel: 1, unlocked: false, completed: false, stars: 0, maxStars: 3, bestTime: 0 },
    { id: 3, name: '减法练习', difficulty: 'easy', difficultyLevel: 1, unlocked: false, completed: false, stars: 0, maxStars: 3, bestTime: 0 },
    { id: 4, name: '乘法入门', difficulty: 'medium', difficultyLevel: 2, unlocked: false, completed: false, stars: 0, maxStars: 3, bestTime: 0 },
    { id: 5, name: '除法基础', difficulty: 'medium', difficultyLevel: 2, unlocked: false, completed: false, stars: 0, maxStars: 3, bestTime: 0 },
    { id: 6, name: '混合运算', difficulty: 'hard', difficultyLevel: 3, unlocked: false, completed: false, stars: 0, maxStars: 3, bestTime: 0 }
  ]
  @State achievements: AchievementItem[] = [
    { id: 'first_win', name: '初次胜利', description: '完成第一个关卡', icon: '🏆', earned: false },
    { id: 'star_collector', name: '星星达人', description: '累计获得 9 颗星星', icon: '⭐', earned: false },
    { id: 'speed_master', name: '速度达人', description: '以超快速度完成一次挑战', icon: '⚡', earned: false },
    { id: 'all_clear', name: '冒险大师', description: '完成所有关卡', icon: '🎓', earned: false },
    { id: 'perfect_score', name: '完美得分', description: '获得满星评价', icon: '💯', earned: false },
    { id: 'math_genius', name: '数学天才', description: '连续答对20道题', icon: '🧠', earned: false },
    { id: 'time_master', name: '时间大师', description: '在30秒内完成关卡', icon: '⏰', earned: false },
    { id: 'streak_king', name: '连击之王', description: '达到10连击', icon: '🔥', earned: false },
    { id: 'coin_collector', name: '金币收集者', description: '累计获得1000金币', icon: '💰', earned: false },
    { id: 'daily_learner', name: '每日学习者', description: '连续学习7天', icon: '📚', earned: false },
    { id: 'challenge_master', name: '挑战大师', description: '完成所有难度挑战', icon: '🎯', earned: false },
    { id: 'legendary_player', name: '传奇玩家', description: '获得所有成就', icon: '👑', earned: false }
  ]
  @State currentLevel: LevelCard | null = null
  @State totalStars: number = 0
  @State totalCoins: number = 0
  @State characterMessage: string = '选择一个关卡开始挑战吧！'
  @State showCharacterMessage: boolean = true
  @State highlightAchievement: AchievementItem | null = null

  private audioManager: AudioManager = AudioManager.getInstance()

  private handleBackNavigation(): boolean {
    if (this.gameView === 'achievements') {
      this.gameView = 'levelSelect'
    } else {
      this.onNavigate('home')
    }
    return true
  }

  aboutToAppear() {
    this.registerBackHandler(() => this.handleBackNavigation())
    this.audioManager.speakText('欢迎来到数学大冒险，选择一个关卡开始吧')
  }

  aboutToDisappear() {
    this.registerBackHandler(null)
  }

  private cloneLevel(level: LevelCard): LevelCard {
    return {
      id: level.id,
      name: level.name,
      difficulty: level.difficulty,
      difficultyLevel: level.difficultyLevel,
      unlocked: level.unlocked,
      completed: level.completed,
      stars: level.stars,
      maxStars: level.maxStars,
      bestTime: level.bestTime
    }
  }

  private createIndexArray(count: number): number[] {
    const result: number[] = []
    for (let i = 0; i < count; i++) {
      result.push(i)
    }
    return result
  }

  private resetCharacterMessage() {
    this.characterMessage = '选择一个关卡开始挑战吧！'
    this.showCharacterMessage = true
  }

  private getDifficultyLabel(difficulty: Difficulty): string {
    if (difficulty === 'easy') {
      return '简单'
    }
    if (difficulty === 'medium') {
      return '中等'
    }
    return '困难'
  }

  private getDifficultyColor(difficulty: Difficulty): string {
    if (difficulty === 'easy') {
      return '#86efac'
    }
    if (difficulty === 'medium') {
      return '#fde68a'
    }
    return '#fca5a5'
  }

  private handleLevelClick(level: LevelCard) {
    if (!level.unlocked) {
      this.characterMessage = '这个关卡暂时还没有解锁哦'
      this.showCharacterMessage = true
      this.audioManager.speakText('这个关卡还没解锁，先完成前面的挑战吧')
      return
    }

    this.currentLevel = level
    this.gameView = 'playing'
    this.characterMessage = `加油，我们开始挑战 ${level.name}！`
    this.showCharacterMessage = true
    this.audioManager.speakText(`准备好了吗？我们一起挑战${level.name}`)
  }

  private finishLevel(success: boolean, starsEarned: number = 0, coinsEarned: number = 0, timeUsed: number = 0) {
    if (!this.currentLevel) {
      return
    }

    if (starsEarned === 0) {
      starsEarned = success ? 3 : 1
    }
    if (coinsEarned === 0) {
      coinsEarned = success ? 150 : 50
    }
    
    if (!success) {
      this.audioManager.speakText('差一点点，再试一次吧')
    } else {
      this.audioManager.speakText('太棒了，关卡完成！')
    }

    const updatedLevels: LevelCard[] = []
    let unlockNext = false
    for (let i = 0; i < this.levels.length; i++) {
      const item = this.levels[i]
      if (item.id === this.currentLevel.id) {
        const bestStars = starsEarned > item.stars ? starsEarned : item.stars
        const bestTime = success ? Math.floor(Math.random() * 60) + 30 : item.bestTime
        const updatedLevel = this.cloneLevel(item)
        updatedLevel.completed = success || item.completed
        updatedLevel.stars = bestStars
        updatedLevel.bestTime = success ? bestTime : item.bestTime
        updatedLevels.push(updatedLevel)
        unlockNext = success
      } else if (unlockNext && !item.unlocked) {
        const unlockedLevel = this.cloneLevel(item)
        unlockedLevel.unlocked = true
        updatedLevels.push(unlockedLevel)
        unlockNext = false
      } else {
        updatedLevels.push(this.cloneLevel(item))
      }
    }

    this.levels = updatedLevels
    this.totalStars = this.totalStars + starsEarned
    this.totalCoins = this.totalCoins + coinsEarned
    this.currentLevel = null
    this.gameView = 'levelSelect'

    this.evaluateAchievements()
    this.characterMessage = success ? '太棒了！挑战完成！' : '没关系，再试一次一定可以！'
    this.showCharacterMessage = true
  }

  private evaluateAchievements() {
    const updatedAchievements: AchievementItem[] = []
    const allCompleted = this.levels.every(level => level.completed)

    for (let i = 0; i < this.achievements.length; i++) {
      const achievement = this.achievements[i]
      let earned = achievement.earned

      if (!earned) {
        if (achievement.id === 'first_win') {
          for (let j = 0; j < this.levels.length; j++) {
            if (this.levels[j].completed) {
              earned = true
              break
            }
          }
        } else if (achievement.id === 'star_collector') {
          if (this.totalStars >= 9) {
            earned = true
          }
        } else if (achievement.id === 'speed_master') {
          for (let j = 0; j < this.levels.length; j++) {
            if (this.levels[j].bestTime !== 0 && this.levels[j].bestTime <= 45) {
              earned = true
              break
            }
          }
        } else if (achievement.id === 'all_clear') {
          if (allCompleted) {
            earned = true
          }
        }

        if (earned) {
          this.highlightAchievement = {
            id: achievement.id,
            name: achievement.name,
            description: achievement.description,
            icon: achievement.icon,
            earned: true
          }
          this.audioManager.speakText(`恭喜获得${achievement.name}成就`)
        }
      }

      const updatedAchievement: AchievementItem = {
        id: achievement.id,
        name: achievement.name,
        description: achievement.description,
        icon: achievement.icon,
        earned: earned
      }
      updatedAchievements.push(updatedAchievement)
    }

    this.achievements = updatedAchievements
  }

  @Builder
  CharacterPanel() {
    Column({ space: 16 }) {
      Text('选择关卡开始你的数学之旅！')
        .fontSize(18)
        .fontColor('rgba(255,255,255,0.8)')
        .textAlign(TextAlign.Center)
      
      Text(this.characterMessage)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .lineHeight(24)
        .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .margin({ top: 12, bottom: 20 })
  }

  @Builder
  LevelCardView(level: LevelCard) {
    Stack() {
      Column({ space: 8 }) {
        // 关卡编号
        Text(level.id.toString())
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        
        // 关卡名称
        Text(level.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
        
        // 星星评价和难度等级
        Row({ space: 12 }) {
          Row({ space: 2 }) {
            ForEach(this.createIndexArray(level.maxStars), (starIndex: number) => {
              Text(starIndex < level.stars ? '★' : '☆')
                .fontSize(16)
                .fontColor(starIndex < level.stars ? '#fde047' : 'rgba(255,255,255,0.3)')
            })
          }
          
          Text(`L${level.difficultyLevel}`)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .backgroundColor('rgba(255,255,255,0.2)')
            .borderRadius(12)
        }
        .justifyContent(FlexAlign.Center)
        
        // 难度标识
        Text(this.getDifficultyLabel(level.difficulty))
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(level.difficulty === 'easy' ? '#166534' : 
                     level.difficulty === 'medium' ? '#854d0e' : '#991b1b')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor(level.difficulty === 'easy' ? '#bbf7d0' : 
                           level.difficulty === 'medium' ? '#fef08a' : '#fecaca')
          .borderRadius(12)
      }
      .width('100%')
      .aspectRatio(1.0)
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
      .justifyContent(FlexAlign.Center)
      .linearGradient(level.unlocked ?
        (level.completed ? 
          { direction: GradientDirection.Bottom, colors: [['#4ade80', 0.0], ['#10b981', 1.0]] } :
          { direction: GradientDirection.Bottom, colors: [['#60a5fa', 0.0], ['#3b82f6', 1.0]] }
        ) :
        { direction: GradientDirection.Bottom, colors: [['#d1d5db', 0.0], ['#9ca3af', 1.0]] }
      )
      .borderRadius(24)
      .border({ width: 4, color: 'rgba(255,255,255,0.3)' })
      .shadow({ radius: 16, color: '#00000020', offsetX: 0, offsetY: 8 })
      .onClick(() => { this.handleLevelClick(level) })
      
      // 锁定状态 - 只显示锁图标，不要黑色遮罩
      if (!level.unlocked) {
        Text('🔒')
          .fontSize(48)
          .position({ x: '50%', y: '50%' })
          .translate({ x: '-50%', y: '-50%' })
      }
    }
    .width('100%')
    .aspectRatio(1.0)
  }

  @Builder
  LevelSelectView() {
    Column({ space: 20 }) {
      this.CharacterPanel()

      Grid() {
        ForEach(this.levels, (level: LevelCard) => {
          GridItem() {
            this.LevelCardView(level)
          }
        })
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(16)
      .rowsGap(16)
      .width('100%')
    }
    .width('100%')
  }

        @Builder
        PlayingView() {
          if (!this.currentLevel) {
            Column() {
              Text('加载关卡中...')
                .fontSize(16)
                .fontColor(Color.White)
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          } else {
            GameChallengePage({
              level: {
                id: this.currentLevel.id,
                name: this.currentLevel.name,
                difficulty: this.currentLevel.difficulty,
                timeLimit: 120,
                questionsCount: 5,
                starsToUnlock: 1
              },
              onComplete: (stars: number, coins: number, timeUsed: number) => {
                this.finishLevel(true, stars, coins, timeUsed)
              },
              onExit: () => {
                this.currentLevel = null
                this.gameView = 'levelSelect'
                this.resetCharacterMessage()
              }
            })
          }
        }

  @Builder
  AchievementsView() {
    Column({ space: 16 }) {
      ForEach(this.achievements, (achievement: AchievementItem) => {
        Row({ space: 12 }) {
          // 图标区域 - 固定大小
          Column() {
            Text(achievement.icon)
              .fontSize(28)
          }
          .width(50)
          .height(50)
          .justifyContent(FlexAlign.Center)

          // 内容区域
          Column({ space: 4 }) {
            Text(achievement.name)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')
            Text(achievement.description)
              .fontSize(13)
              .fontColor('#6b7280')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          // 状态区域 - 固定大小
          Column() {
            Text(achievement.earned ? '已获得' : '待解锁')
              .fontSize(12)
              .fontColor(achievement.earned ? '#22c55e' : '#9ca3af')
          }
          .width(60)
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .height(80) // 固定高度
        .padding({ left: 20, right: 20, top: 16, bottom: 16 })
        .backgroundColor(achievement.earned ? '#fef3c7' : Color.White) // 已达成用黄色背景
        .borderRadius(16)
        .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
        .opacity(1.0) // 所有卡片都完全显示
      })
    }
  }

  build() {
    Column() {
            // 顶部导航栏 (仅在非游戏挑战模式下显示)
            if (this.gameView !== 'playing') {
              Stack() {
                // 居中标题
                Text(this.gameView === 'achievements' ? '成就殿堂' : '数学大冒险')
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(Color.White)
                  .textAlign(TextAlign.Center)
                  .width('100%')

                // 左侧返回按钮 和 右侧成就按钮
                Row() {
                  Button() {
                    Row({ space: 8 }) {
                      Text('👈')
                        .fontSize(16)
                      Text('返回')
                        .fontSize(14)
                        .fontColor(Color.White)
                    }
                  }
                  .backgroundColor('rgba(255,255,255,0.2)')
                  .borderRadius(20)
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .onClick(() => { this.handleBackNavigation() })

                  Blank()

                  // 只在关卡选择页面显示成就按钮
                  if (this.gameView === 'levelSelect') {
                    Button() {
                      Row({ space: 8 }) {
                        Text('🏆')
                          .fontSize(16)
                        Text('成就')
                          .fontSize(14)
                          .fontColor('#78350f')
                          .fontWeight(FontWeight.Bold)
                      }
                    }
                    .backgroundColor('#fbbf24')
                    .borderRadius(20)
                    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                    .onClick(() => { this.gameView = 'achievements' })
                  }
                }
                .width('100%')
              }
              .width('100%')
              .height(48)
              .margin({ top: 8, bottom: 16 })
            }

      Scroll() {
        Column({ space: 20 }) {
          if (this.gameView === 'levelSelect') {
            this.LevelSelectView()
          } else if (this.gameView === 'playing') {
            this.PlayingView()
          } else {
            this.AchievementsView()
          }

          if (this.highlightAchievement) {
            Column() {
              Text(`${this.highlightAchievement.icon} 获得新成就：${this.highlightAchievement.name}`)
                .fontSize(14)
                .fontColor(Color.White)
            }
            .padding({ left: 16, right: 16, top: 12, bottom: 12 })
            .backgroundColor('rgba(255,255,255,0.25)')
            .borderRadius(20)
            .onClick(() => { this.highlightAchievement = null })
          }
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .scrollBarColor(Color.Transparent)
      .scrollBarWidth(0)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#a78bfa', 0.0], ['#f472b6', 0.5], ['#fb923c', 1.0]]
    })
  }
}
