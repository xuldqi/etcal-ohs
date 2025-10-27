import { AudioManager } from '../managers/AudioManager'
import { UnifiedHeader } from '../components/UnifiedHeader'

type QuestionType = 'addition' | 'subtraction'

interface VisualTemplate {
  object: string
  emoji: string
  quantifier: string
}

interface VisualQuestion {
  id: number
  type: QuestionType
  object: string
  emoji: string
  quantifier: string
  num1: number
  num2: number
  answer: number
}

interface VisualStats {
  correct: number
  total: number
  stars: number
}

@Component
export struct VisualLearningPage {
  onNavigate: (page: string) => void = () => {}

  @State currentQuestion: VisualQuestion | null = null
  @State options: number[] = []
  @State selectedAnswer: number = -1
  @State showResult: boolean = false
  @State isCorrect: boolean = false
  @State stats: VisualStats = { correct: 0, total: 0, stars: 0 }
  @State showCelebration: boolean = false

  private audioManager: AudioManager = new AudioManager()
  private nextQuestionTimer?: number
  private questionTemplates: VisualTemplate[] = [
    { object: '小猫', emoji: '🐱', quantifier: '只' },
    { object: '苹果', emoji: '🍎', quantifier: '个' },
    { object: '香蕉', emoji: '🍌', quantifier: '根' },
    { object: '气球', emoji: '🎈', quantifier: '个' },
    { object: '小汽车', emoji: '🚗', quantifier: '辆' },
    { object: '星星', emoji: '⭐', quantifier: '颗' },
    { object: '蝴蝶', emoji: '🦋', quantifier: '只' },
    { object: '花朵', emoji: '🌸', quantifier: '朵' }
  ]

  aboutToAppear() {
    this.prepareQuestion()
  }

  aboutToDisappear() {
    this.clearNextQuestionTimer()
  }

  private clearNextQuestionTimer() {
    if (this.nextQuestionTimer !== undefined) {
      clearTimeout(this.nextQuestionTimer)
      this.nextQuestionTimer = undefined
    }
  }

  private scheduleNextQuestion(delayMs: number, beforeNext?: () => void) {
    this.clearNextQuestionTimer()
    this.nextQuestionTimer = setTimeout(() => {
      if (beforeNext) {
        beforeNext()
      }
      this.prepareQuestion()
      this.nextQuestionTimer = undefined
    }, delayMs)
  }

  private prepareQuestion() {
    this.clearNextQuestionTimer()
    
    // 确保每次换题时，emoji和运算符号都会变化
    let templateIndex: number
    let randomType: 'addition' | 'subtraction'
    
    if (this.currentQuestion) {
      // 强制选择不同的模板 - 基于object而不是emoji
      let currentTemplateIndex = this.questionTemplates.findIndex(t => t.object === this.currentQuestion!.object)
      if (currentTemplateIndex === -1) {
        // 如果找不到当前模板，随机选择
        templateIndex = Math.floor(Math.random() * this.questionTemplates.length)
      } else {
        templateIndex = (currentTemplateIndex + 1) % this.questionTemplates.length
      }
      
      // 强制选择不同的运算类型
      randomType = this.currentQuestion.type === 'addition' ? 'subtraction' : 'addition'
    } else {
      // 第一次生成，随机选择
      templateIndex = Math.floor(Math.random() * this.questionTemplates.length)
      randomType = Math.random() > 0.3 ? 'addition' : 'subtraction'
    }
    
    const template = this.questionTemplates[templateIndex]

    let num1 = 0
    let num2 = 0
    let answer = 0

    if (randomType === 'addition') {
      num1 = Math.floor(Math.random() * 5) + 1
      num2 = Math.floor(Math.random() * 5) + 1
      answer = num1 + num2
    } else {
      num1 = Math.floor(Math.random() * 8) + 3
      num2 = Math.floor(Math.random() * num1) + 1
      if (num2 > num1) {
        num2 = num1
      }
      answer = num1 - num2
    }

    const newQuestion: VisualQuestion = {
      id: Date.now(),
      type: randomType,
      object: template.object,
      emoji: template.emoji,
      quantifier: template.quantifier,
      num1: num1,
      num2: num2,
      answer: answer
    }

    console.log(`[学数学] 新题目: ${newQuestion.emoji} ${newQuestion.num1} ${newQuestion.type === 'addition' ? '+' : '-'} ${newQuestion.num2} = ${newQuestion.answer}`)
    console.log(`[学数学] 模板: ${template.object} ${template.emoji} ${template.quantifier}`)
    console.log(`[学数学] 运算类型: ${randomType}`)
    console.log(`[学数学] 当前题目类型: ${this.currentQuestion?.type}`)
    console.log(`[学数学] 新题目类型: ${newQuestion.type}`)
    console.log(`[学数学] 新题目object: ${newQuestion.object}`)
    console.log(`[学数学] 新题目emoji: ${newQuestion.emoji}`)

    const generatedOptions = this.generateOptions(newQuestion.answer)

    // 强制状态更新，确保UI重新渲染
    this.currentQuestion = newQuestion
    this.options = generatedOptions
    this.selectedAnswer = -1
    this.showResult = false
    this.isCorrect = false
    this.showCelebration = false

    const description = newQuestion.type === 'addition'
      ? `${newQuestion.num1}${newQuestion.quantifier}${newQuestion.object}加上${newQuestion.num2}${newQuestion.quantifier}${newQuestion.object}等于多少`
      : `${newQuestion.num1}${newQuestion.quantifier}${newQuestion.object}减去${newQuestion.num2}${newQuestion.quantifier}${newQuestion.object}等于多少`
    this.audioManager.speakText(description)
  }

  private generateOptions(correctAnswer: number): number[] {
    const optionList: number[] = [correctAnswer]
    let attempts = 0
    const maxAttempts = 20 // 防止无限循环

    while (optionList.length < 4 && attempts < maxAttempts) {
      attempts++
      const randomOffset = Math.floor(Math.random() * 6) - 3
      let candidate = correctAnswer + randomOffset
      if (candidate < 0) {
        candidate = correctAnswer + 1
      }
      let duplicated = false
      for (let i = 0; i < optionList.length; i++) {
        if (optionList[i] === candidate) {
          duplicated = true
          break
        }
      }
      if (!duplicated) {
        optionList.push(candidate)
      }
    }

    // 如果仍然不够4个选项，用简单的方式补充
    while (optionList.length < 4) {
      const candidate = correctAnswer + optionList.length
      optionList.push(candidate)
    }

    for (let i = optionList.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1))
      const temp = optionList[i]
      optionList[i] = optionList[j]
      optionList[j] = temp
    }

    return optionList
  }

  private handleAnswerSelect(answer: number) {
    if (this.showResult || this.currentQuestion === null) {
      return
    }

    this.selectedAnswer = answer
    this.showResult = true
    const correct = answer === this.currentQuestion.answer
    this.isCorrect = correct

    const updatedStats: VisualStats = {
      correct: this.stats.correct + (correct ? 1 : 0),
      total: this.stats.total + 1,
      stars: this.stats.stars + (correct ? 1 : 0)
    }
    this.stats = updatedStats

    if (correct) {
      this.audioManager.speakText('回答正确，真棒！')
      this.showCelebration = true
      this.scheduleNextQuestion(2000, () => {
        this.showCelebration = false
      })
    } else {
      this.audioManager.speakText(`答错了，正确答案是 ${this.currentQuestion.answer}`)
      this.scheduleNextQuestion(2000)
    }
  }

  private getProgressPercentage(): number {
    if (this.stats.total === 0) {
      return 0
    }
    const rate = (this.stats.correct * 100.0) / this.stats.total
    return Math.round(rate)
  }

  private createIndexArray(count: number): number[] {
    const indices: number[] = []
    for (let i = 0; i < count; i++) {
      indices.push(i)
    }
    return indices
  }

  @Builder
  RenderEmojiRow(questionId: number, count: number, emoji: string) {
    Row({ space: 8 }) {
      ForEach(this.createIndexArray(count), (index: number) => {
        Text(emoji)
          .fontSize(32)
      }, (index: number) => `${questionId}-${emoji}-${index}`)
    }
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  RenderQuestionContent() {
    if (!this.currentQuestion) {
      Column() {
        Text('加载中...')
          .fontSize(16)
          .fontColor(Color.White)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
    } else {
      Column({ space: 16 }) {
        // 第一组emoji
        Row({ space: 8 }) {
          ForEach(this.createIndexArray(this.currentQuestion!.num1), (index: number) => {
            Text(this.currentQuestion!.emoji)
              .fontSize(32)
          }, (index: number) => `${this.currentQuestion!.id}-first-${this.currentQuestion!.emoji}-${index}`)
        }
        .justifyContent(FlexAlign.Center)

        // 运算符号
        if (this.currentQuestion!.type === 'addition') {
          Text('+')
            .fontSize(24)
            .fontColor('#475569')
            .textAlign(TextAlign.Center)
        } else {
          Text('-')
            .fontSize(24)
            .fontColor('#475569')
            .textAlign(TextAlign.Center)
        }

        // 第二组emoji
        Row({ space: 8 }) {
          ForEach(this.createIndexArray(this.currentQuestion!.num2), (index: number) => {
            Text(this.currentQuestion!.emoji)
              .fontSize(32)
          }, (index: number) => `${this.currentQuestion!.id}-second-${this.currentQuestion!.emoji}-${index}`)
        }
        .justifyContent(FlexAlign.Center)

        // 问题文本
        Text(`一共有多少${this.currentQuestion!.quantifier}${this.currentQuestion!.object}？`)
          .fontSize(16)
          .fontColor('#1f2937')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
    }
  }

  build() {
    Column() {
      // 统一标题栏
      UnifiedHeader({
        title: '学数学',
        onBack: () => { this.onNavigate('home') }
      })

      Column({ space: 12 }) {
          Row() {
            Row() {
              Text('⭐')
                .fontSize(22)
              Text(this.stats.stars.toString())
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#f59e0b')
              Blank()
              Text(`正确率：${this.getProgressPercentage()}%`)
                .fontSize(14)
                .fontColor('#4b5563')
              Blank()
              Text(`已完成：${this.stats.total} 题`)
                .fontSize(14)
                .fontColor('#4b5563')
            }
            .alignItems(VerticalAlign.Center)
            .layoutWeight(1)

            Button('换一题')
              .fontSize(12)
              .fontColor('#2563eb')
              .backgroundColor('#dbeafe')
              .borderRadius(16)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .onClick(() => { this.prepareQuestion() })
          }
          .width('100%')
          .alignItems(VerticalAlign.Center)
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor(Color.White)
          .borderRadius(24)
          .shadow({ radius: 12, color: '#00000012', offsetX: 0, offsetY: 8 })

          Column({ space: 24 }) {
            this.RenderQuestionContent()

            Column({ space: 12 }) {
              // 第一行：前两个选项
              Row({ space: 12 }) {
                ForEach(this.options.slice(0, 2), (optionValue: number) => {
                  Button(`${optionValue}`)
                    .fontSize(16)
                    .fontColor(this.showResult && optionValue === this.currentQuestion?.answer ? Color.White : '#1f2937')
                    .backgroundColor(this.getOptionBackground(optionValue))
                    .borderRadius(18)
                    .padding({ left: 24, right: 24, top: 14, bottom: 14 })
                    .onClick(() => { this.handleAnswerSelect(optionValue) })
                    .layoutWeight(1)
                })
              }
              .width('100%')

              // 第二行：后两个选项
              Row({ space: 12 }) {
                ForEach(this.options.slice(2, 4), (optionValue: number) => {
                  Button(`${optionValue}`)
                    .fontSize(16)
                    .fontColor(this.showResult && optionValue === this.currentQuestion?.answer ? Color.White : '#1f2937')
                    .backgroundColor(this.getOptionBackground(optionValue))
                    .borderRadius(18)
                    .padding({ left: 24, right: 24, top: 14, bottom: 14 })
                    .onClick(() => { this.handleAnswerSelect(optionValue) })
                    .layoutWeight(1)
                })
              }
              .width('100%')
            }
            .width('100%')

            if (this.showResult && this.currentQuestion) {
              Column() {
                Text(this.isCorrect ? '回答正确！' : `正确答案是 ${this.currentQuestion.answer}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(this.isCorrect ? '#16a34a' : '#dc2626')
              }
              .width('100%')
              .margin({ top: 8 })
            }

            if (this.showCelebration) {
              Text('🎉 太棒了！继续保持！')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2563eb')
                .textAlign(TextAlign.Center)
            }
          }
          .width('100%')
          .padding({ left: 20, right: 20, top: 20, bottom: 20 })
          .backgroundColor(Color.White)
          .borderRadius(32)
          .shadow({ radius: 18, color: '#00000020', offsetX: 0, offsetY: 12 })
        }
        .width('100%')
      }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 0, bottom: 24 })
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#bbf7d0', 0.0], ['#bfdbfe', 0.4], ['#ddd6fe', 1.0]]
    })
  }

  private getOptionBackground(optionValue: number): string | ResourceColor {
    if (!this.showResult) {
      return '#f8fafc'
    }
    if (this.currentQuestion && optionValue === this.currentQuestion.answer) {
      return '#22c55e'
    }
    if (optionValue === this.selectedAnswer && optionValue !== this.currentQuestion?.answer) {
      return '#ef4444'
    }
    return '#f8fafc'
  }
}
