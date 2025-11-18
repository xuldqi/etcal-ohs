import { AudioManager } from '../managers/AudioManager'

// 题目类型
interface Question {
  id: number
  question: string
  options: number[]
  correctAnswer: number
  difficulty: string
}

// 关卡信息
interface LevelInfo {
  id: number
  name: string
  difficulty: string
  timeLimit: number // 秒
  questionsCount: number
  starsToUnlock: number
}

@Component
export struct GameChallengePage {
  onComplete: (stars: number, coins: number, timeUsed: number) => void = () => {}
  onExit: () => void = () => {}
  
  @Prop level: LevelInfo = {
    id: 1,
    name: '数字认知',
    difficulty: 'easy',
    timeLimit: 120,
    questionsCount: 5,
    starsToUnlock: 1
  }

  @State currentQuestionIndex: number = 0
  @State score: number = 0
  @State timeLeft: number = 120
  @State gameState: string = 'ready' // 'ready' | 'playing' | 'completed' | 'failed'
  @State selectedAnswer: number | -1 = -1
  @State showResult: boolean = false
  @State hearts: number = 3
  @State coins: number = 0
  @State combo: number = 0
  @State questions: Question[] = []
  @State currentQuestion: Question | null = null
  @State characterEmotion: string = 'thinking' // 'happy' | 'excited' | 'thinking' | 'sad' | 'celebrating'
  @State characterMessage: string = ''
  @State showCharacterMessage: boolean = false

  private audioManager: AudioManager = AudioManager.getInstance()
  private timer: number = -1

  aboutToAppear() {
    this.timeLeft = this.level.timeLimit
    this.hearts = Math.max(1, 4 - Math.floor(this.level.id / 2))
    this.generateQuestions()
    this.currentQuestion = this.questions[0]
  }

  aboutToDisappear() {
    if (this.timer !== -1) {
      clearInterval(this.timer)
    }
  }

  // 生成题目
  private generateQuestions() {
    const questions: Question[] = []
    const difficultyLevel = Math.min(5, Math.floor((this.level.id - 1) / 3) + 1)
    
    for (let i = 0; i < this.level.questionsCount; i++) {
      let question: Question
      
      if (difficultyLevel === 1) {
        // 简单加减法
        const a = Math.floor(Math.random() * 10) + 1
        const b = Math.floor(Math.random() * 10) + 1
        const isAddition = Math.random() > 0.5
        
        if (isAddition) {
          const answer = a + b
          question = {
            id: i + 1,
            question: `${a} + ${b} = ?`,
            options: [answer, answer + 1, answer - 1, answer + 2].sort(() => Math.random() - 0.5),
            correctAnswer: answer,
            difficulty: this.level.difficulty
          }
        } else {
          const answer = Math.max(a, b) - Math.min(a, b)
          question = {
            id: i + 1,
            question: `${Math.max(a, b)} - ${Math.min(a, b)} = ?`,
            options: [answer, answer + 1, answer - 1, answer + 2].filter(x => x >= 0).sort(() => Math.random() - 0.5),
            correctAnswer: answer,
            difficulty: this.level.difficulty
          }
        }
      } else if (difficultyLevel === 2) {
        // 乘法
        const a = Math.floor(Math.random() * 9) + 1
        const b = Math.floor(Math.random() * 9) + 1
        const answer = a * b
        question = {
          id: i + 1,
          question: `${a} × ${b} = ?`,
          options: [answer, answer + a, answer - a, answer + b].sort(() => Math.random() - 0.5),
          correctAnswer: answer,
          difficulty: this.level.difficulty
        }
      } else {
        // 复杂运算
        const a = Math.floor(Math.random() * 20) + 1
        const b = Math.floor(Math.random() * 20) + 1
        const answer = a + b
        question = {
          id: i + 1,
          question: `${a} + ${b} = ?`,
          options: [answer, answer + 1, answer - 1, answer + 2].sort(() => Math.random() - 0.5),
          correctAnswer: answer,
          difficulty: this.level.difficulty
        }
      }
      
      questions.push(question)
    }
    
    this.questions = questions
  }

  // 开始游戏
  private startGame() {
    this.gameState = 'playing'
    this.characterEmotion = 'excited'
    this.characterMessage = '开始挑战！'
    this.showCharacterMessage = true
    this.audioManager.speakText('游戏开始！准备好了吗？')
    
    setTimeout(() => {
      this.characterEmotion = 'thinking'
      this.showCharacterMessage = false
    }, 1500)
    
    this.startTimer()
  }

  // 选择答案
  private selectAnswer(answer: number) {
    if (this.gameState !== 'playing' || this.showResult) return
    
    this.selectedAnswer = answer
    this.showResult = true
    
    setTimeout(() => {
      const isCorrect = answer === this.currentQuestion!.correctAnswer
      
      if (isCorrect) {
        this.score += 1
        this.combo += 1
        this.audioManager.speakText('回答正确！')
        
        // 角色庆祝
        if (this.combo >= 2) {
          this.characterEmotion = 'excited'
          this.characterMessage = `太棒了！连击 x${this.combo}`
        } else {
          this.characterEmotion = 'happy'
          this.characterMessage = '答对了！'
        }
        this.showCharacterMessage = true
        
        // 奖励金币
        const coinReward = 10 + this.combo * 2
        this.coins += coinReward
        
        // 下一题或完成
        if (this.currentQuestionIndex < this.questions.length - 1) {
          setTimeout(() => {
            this.currentQuestionIndex++
            this.currentQuestion = this.questions[this.currentQuestionIndex]
            this.selectedAnswer = -1
            this.showResult = false
            this.characterEmotion = 'thinking'
            this.showCharacterMessage = false
          }, 1500)
        } else {
          setTimeout(() => {
            this.characterEmotion = 'celebrating'
            this.characterMessage = '恭喜完成！'
            this.showCharacterMessage = true
            setTimeout(() => {
              this.completeGame()
            }, 1000)
          }, 1500)
        }
      } else {
        this.combo = 0
        this.audioManager.speakText('回答错误，再想想')
        
        // 角色难过
        this.characterEmotion = 'sad'
        this.characterMessage = '再想想看...'
        this.showCharacterMessage = true
        
        this.hearts -= 1
        if (this.hearts <= 0) {
          this.gameState = 'failed'
        } else {
          // 继续下一题
          setTimeout(() => {
            if (this.currentQuestionIndex < this.questions.length - 1) {
              this.currentQuestionIndex++
              this.currentQuestion = this.questions[this.currentQuestionIndex]
              this.selectedAnswer = -1
              this.showResult = false
              this.characterEmotion = 'thinking'
              this.showCharacterMessage = false
            } else {
              this.completeGame()
            }
          }, 1500)
        }
      }
    }, 500)
  }

  // 完成游戏
  private completeGame() {
    this.gameState = 'completed'
    const stars = this.calculateStars()
    const timeUsed = this.level.timeLimit - this.timeLeft
    this.audioManager.speakText(`游戏完成！获得${stars}颗星星！`)
    this.onComplete(stars, this.coins, timeUsed)
  }

  // 计算星星
  private calculateStars(): number {
    const accuracy = this.score / this.questions.length
    const timeBonus = this.timeLeft > this.level.timeLimit * 0.5 ? 1 : 0
    
    if (accuracy >= 0.9 && timeBonus) return 3
    if (accuracy >= 0.7) return 2
    if (accuracy >= 0.5) return 1
    return 0
  }

  // 倒计时
  private startTimer() {
    if (this.gameState !== 'playing') return
    
    this.timer = setInterval(() => {
      this.timeLeft--
      if (this.timeLeft <= 0) {
        this.gameState = 'failed'
        this.audioManager.speakText('时间到了！')
        clearInterval(this.timer)
      }
    }, 1000)
  }

  // 获取答案按钮样式
  private getAnswerButtonStyle(answer: number): string {
    if (!this.showResult) {
      return 'normal'
    }
    
    if (answer === this.currentQuestion!.correctAnswer) {
      return 'correct'
    }
    
    if (answer === this.selectedAnswer && answer !== this.currentQuestion!.correctAnswer) {
      return 'wrong'
    }
    
    return 'disabled'
  }

  build() {
    if (this.gameState === 'ready') {
      // 准备界面 - 完全按照React版本，不显示标题
      Column() {
        Column({ space: 20 }) {
          Text('🎯')
            .fontSize(60)
            .textAlign(TextAlign.Center)
          
          Text(this.level.name)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Center)
          
          Text('准备好挑战了吗？\n你有 ' + this.level.timeLimit + ' 秒时间完成 ' + this.level.questionsCount + ' 道题目！')
            .fontSize(16)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Center)
            .lineHeight(24)
          
          // 难度和时间信息卡片
          Row({ space: 16 }) {
            Column({ space: 8 }) {
              Text('难度')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#3b82f6')
              Text(this.level.difficulty === 'easy' ? '简单' : this.level.difficulty === 'medium' ? '中等' : '困难')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1e40af')
            }
            .layoutWeight(1)
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#dbeafe')
            .borderRadius(12)
            
            Column({ space: 8 }) {
              Text('时间限制')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#d97706')
              Text(this.level.timeLimit + 's')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#92400e')
            }
            .layoutWeight(1)
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#fef3c7')
            .borderRadius(12)
          }
          .width('100%')
          
          // 按钮
          Row({ space: 16 }) {
            Button('返回')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#9ca3af')
              .borderRadius(12)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .layoutWeight(1)
              .onClick(() => { this.onExit() })
            
            Button('开始挑战')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [['#10b981', 0.0], ['#3b82f6', 1.0]]
              })
              .borderRadius(12)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .layoutWeight(1)
              .onClick(() => { this.startGame() })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: 32, bottom: 32 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .shadow({ radius: 16, color: '#00000020', offsetX: 0, offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16 })
    } else if (this.gameState === 'completed') {
      // 完成界面 - 完全按照React版本
      Column() {
        Column({ space: 20 }) {
          Text('🎉')
            .fontSize(60)
            .textAlign(TextAlign.Center)
          
          Text('关卡完成！')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Center)
          
          // 星星显示
          Row({ space: 8 }) {
            ForEach([0, 1, 2], (index: number) => {
              Text(index < this.calculateStars() ? '★' : '☆')
                .fontSize(32)
                .fontColor(index < this.calculateStars() ? '#fbbf24' : '#d1d5db')
            })
          }
          .justifyContent(FlexAlign.Center)
          
          // 统计信息
          Row({ space: 16 }) {
            Column({ space: 8 }) {
              Text('正确率')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#3b82f6')
              Text(Math.round((this.score / this.questions.length) * 100) + '%')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#1e40af')
            }
            .layoutWeight(1)
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#dbeafe')
            .borderRadius(12)
            
            Column({ space: 8 }) {
              Text('获得金币')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#d97706')
              Row({ space: 4 }) {
                Text('💰')
                  .fontSize(16)
                Text(this.coins.toString())
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#92400e')
              }
            }
            .layoutWeight(1)
            .padding({ left: 12, right: 12, top: 12, bottom: 12 })
            .backgroundColor('#fef3c7')
            .borderRadius(12)
          }
          .width('100%')
          
          Button('继续冒险')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .linearGradient({
              direction: GradientDirection.Right,
              colors: [['#10b981', 0.0], ['#3b82f6', 1.0]]
            })
            .borderRadius(12)
            .padding({ left: 24, right: 24, top: 12, bottom: 12 })
            .width('100%')
            .onClick(() => { this.onComplete(this.calculateStars(), this.coins, this.level.timeLimit - this.timeLeft) })
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: 32, bottom: 32 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .shadow({ radius: 16, color: '#00000020', offsetX: 0, offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#f8fafc')
    } else if (this.gameState === 'failed') {
      // 失败界面 - 完全按照React版本
      Column() {
        Column({ space: 20 }) {
          Text('😢')
            .fontSize(60)
            .textAlign(TextAlign.Center)
          
          Text('挑战失败')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Center)
          
          Text((this.hearts <= 0 ? '生命值耗尽了！' : '时间到了！') + '\n不要灰心，再试一次吧！')
            .fontSize(16)
            .fontColor('#6b7280')
            .textAlign(TextAlign.Center)
            .lineHeight(24)
          
          Row({ space: 16 }) {
            Button('返回')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('#9ca3af')
              .borderRadius(12)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .layoutWeight(1)
              .onClick(() => { this.onExit() })
            
            Button('重试')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [['#3b82f6', 0.0], ['#8b5cf6', 1.0]]
              })
              .borderRadius(12)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .layoutWeight(1)
              .onClick(() => { 
                this.gameState = 'ready'
                this.timeLeft = this.level.timeLimit
                this.score = 0
                this.hearts = Math.max(1, 4 - Math.floor(this.level.id / 2))
                this.currentQuestionIndex = 0
                this.currentQuestion = this.questions[0]
                this.selectedAnswer = -1
                this.showResult = false
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 32, right: 32, top: 32, bottom: 32 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .shadow({ radius: 16, color: '#00000020', offsetX: 0, offsetY: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16 })
    } else {
      // 游戏进行中界面 - 完全按照React版本
      Column() {
        // 顶部状态栏 - 简化版本，不显示标题
        Column({ space: 50 }) {
          // 第一行：退出按钮和状态信息
          Row() {
            Button('退出')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(20)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .onClick(() => { this.onExit() })
            
            Blank()
            
            Row({ space: 12 }) {
              // 生命值
              Row({ space: 4 }) {
                ForEach(Array.from({ length: this.hearts }), (item: number, index: number) => {
                  Text('❤️')
                    .fontSize(20)
                    .fontColor(index < this.hearts ? '#ef4444' : 'rgba(255,255,255,0.3)')
                })
              }
              
              // 难度等级
              Text('L' + this.level.id)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
                .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                .backgroundColor('rgba(34, 197, 94, 0.8)')
                .borderRadius(12)
              
            }
          }
          .width('100%')
          
          // 第二行：时间居中显示
          Row() {
            Blank()
            Row({ space: 8 }) {
              Text('⏰')
                .fontSize(20)
              Text(this.timeLeft + 's')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('rgba(255,255,255,0.2)')
            .borderRadius(20)
            Blank()
          }
          .width('100%')
        }
        .margin({ bottom: 20 })
        
        // 进度条
        Column({ space: 8 }) {
          Row() {
            Column()
              .width((this.currentQuestionIndex / this.questions.length) * 100 + '%')
              .height('100%')
              .linearGradient({
                direction: GradientDirection.Right,
                colors: [['#10b981', 0.0], ['#3b82f6', 1.0]]
              })
          }
          .width('100%')
          .height(12)
          .backgroundColor('rgba(255,255,255,0.2)')
          .borderRadius(6)
          .clip(true)
          
          Text('第 ' + (this.currentQuestionIndex + 1) + ' 题 / 共 ' + this.questions.length + ' 题')
            .fontSize(14)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 连击显示
        if (this.combo > 1) {
          Row() {
            Row({ space: 8 }) {
              Text('⚡')
                .fontSize(20)
              Text('连击 x' + this.combo)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(Color.White)
            }
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            .backgroundColor('#f97316')
            .borderRadius(20)
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 16 })
        }
        
        // 游戏角色消息
        if (this.showCharacterMessage) {
          Column() {
            Text(this.characterMessage)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .textAlign(TextAlign.Center)
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
              .backgroundColor('rgba(255,255,255,0.2)')
              .borderRadius(16)
          }
          .width('100%')
          .margin({ bottom: 16 })
        }
        
        // 题目区域
        if (this.currentQuestion) {
          Column({ space: 12 }) {
            Text(this.currentQuestion.question)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1f2937')
              .textAlign(TextAlign.Center)
            
            Grid() {
              ForEach(this.currentQuestion.options, (option: number, index: number) => {
                GridItem() {
                  Button(option.toString())
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor(this.getAnswerButtonStyle(option) === 'normal' ? Color.White :
                              this.getAnswerButtonStyle(option) === 'correct' ? Color.White :
                              this.getAnswerButtonStyle(option) === 'wrong' ? Color.White : '#6b7280')
                    .backgroundColor(this.getAnswerButtonStyle(option) === 'normal' ? '#3b82f6' :
                                    this.getAnswerButtonStyle(option) === 'correct' ? '#10b981' :
                                    this.getAnswerButtonStyle(option) === 'wrong' ? '#ef4444' : '#d1d5db')
                    .borderRadius(12)
                    .width('100%')
                    .height(45)
                    .onClick(() => { this.selectAnswer(option) })
                }
              })
            }
            .columnsTemplate('1fr 1fr')
            .columnsGap(12)
            .rowsGap(12)
            .width('100%')
          }
          .width('100%')
          .height(200) // 固定高度，防止拉伸
          .padding({ left: 20, right: 20, top: 16, bottom: 16 })
          .backgroundColor(Color.White)
          .borderRadius(20)
          .shadow({ radius: 12, color: '#00000020', offsetX: 0, offsetY: 6 })
        }
      }
      .width('100%')
      .height('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    }
  }
}
