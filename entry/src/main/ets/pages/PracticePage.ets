import { AudioManager } from '../managers/AudioManager'
import { UnifiedHeader } from '../components/UnifiedHeader'

// 学习统计接口
interface LearningStats {
  totalProblems: number
  correctAnswers: number
  score: number
}

// 数学题目接口
interface MathProblem {
  num1: number
  num2: number
  operator: string
  answer: number
  question: string
}

// 比大小题目
interface ComparisonQuestion {
  left: number
  right: number
}

type PracticeMode = 'menu' | 'comparison' | 'addition' | 'subtraction' | 'multiplication' | 'division'
type ComparisonOperator = '>' | '<' | '='

@Component
export struct PracticePage {
  onNavigate: (page: string) => void = () => {}
  @Prop learningStats: LearningStats
  updateStats: (stats: LearningStats) => void = () => {}

  @State currentMode: PracticeMode = 'menu'
  @State currentProblem: MathProblem | null = null
  @State comparisonQuestion: ComparisonQuestion | null = null
  @State previousComparisonQuestion: ComparisonQuestion | null = null
  @State comparisonFeedback: string = ''
  @State selectedComparisonOperator: ComparisonOperator | null = null
  @State showComparisonResult: boolean = false
  @State userAnswer: string = ''
  @State score: number = 0
  @State totalProblems: number = 0
  @State correctAnswers: number = 0
  @State showResult: boolean = false
  @State isCorrect: boolean = false
  @State questionRefreshKey: number = 0
  @State showCelebration: boolean = false
  @State celebrationScale: number = 1.0
  @State celebrationOpacity: number = 0

  private audioManager: AudioManager = new AudioManager()

  aboutToAppear() {
    this.prepareMode('menu')
  }

  build() {
    Stack() {
      // 主内容
      Column() {
            // 统一标题栏
            UnifiedHeader({
              title: this.getModeTitle(),
              onBack: () => {
                if (this.currentMode === 'menu') {
                  this.onNavigate('home')
                } else {
                  this.prepareMode('menu')
                }
              }
            })

        Scroll() {
          Column({ space: 16 }) {
            if (this.currentMode === 'menu') {
              Text('选择你想要练习的内容吧！')
                .fontSize(16)
                .fontColor('#4b5563')
                .textAlign(TextAlign.Center)
              this.RenderMenu()
            } else if (this.currentMode === 'comparison') {
              this.RenderComparison()
            } else {
              this.RenderPractice()
            }

            if (this.currentMode === 'menu') {
              Row() {
                Text('🐼')
                  .fontSize(20)
                Text('选择一个练习开始学习吧！')
                  .fontSize(14)
                  .fontColor('#4b5563')
                  .fontWeight(FontWeight.Medium)
              }
              .padding({ left: 20, right: 20, top: 12, bottom: 12 })
              .backgroundColor(Color.White)
              .borderRadius(24)
              .shadow({ radius: 10, color: '#00000012', offsetX: 0, offsetY: 6 })
              .margin({ top: 12, bottom: 12 })
            }
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .layoutWeight(1)
        .align(Alignment.TopStart)
        .scrollBar(BarState.Auto)
        .scrollBarColor(Color.Transparent)
        .scrollBarWidth(0)
      }
      .width('100%')
      .height('100%')
      .padding({ left: 20, right: 20, top: 0, bottom: 16 })
      .linearGradient({
        direction: GradientDirection.Bottom,
        colors: [['#fde68a', 0.0], ['#fef9c3', 0.4], ['#bae6fd', 1.0]]
      })
      
      // 庆祝动画层
      if (this.showCelebration) {
        Column() {
          Text('🎉')
            .fontSize(120)
            .scale({ x: this.celebrationScale, y: this.celebrationScale })
            .opacity(this.celebrationOpacity)
          Text('太棒了！')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor('#10b981')
            .opacity(this.celebrationOpacity)
            .margin({ top: 20 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }

  private prepareMode(mode: PracticeMode) {
    this.currentMode = mode
    this.userAnswer = ''
    this.showResult = false
    this.comparisonFeedback = ''

    if (mode === 'menu') {
      return
    }

    if (mode === 'comparison') {
      // 重置比大小模式的统计
      this.totalProblems = 0
      this.correctAnswers = 0
      this.generateComparisonQuestion()
      this.audioManager.speakText('让我们比一比哪一个数字更大吧')
    } else {
      this.score = 0
      this.totalProblems = 0
      this.correctAnswers = 0
      this.generateProblemForMode(mode)
    }
  }

  // ---------------------
  // 菜单渲染
  // ---------------------
  @Builder
  RenderMenu() {
    Column({ space: 20 }) {
      this.MenuCard('⚖️', '比大小', '比较数字大小，训练逻辑思维', ['#60a5fa', '#1d4ed8'], () => {
        this.prepareMode('comparison')
      })

      this.MenuCard('➕', '加法练习', '练习加法运算，提升计算能力', ['#34d399', '#059669'], () => {
        this.prepareMode('addition')
      })

      this.MenuCard('➖', '减法练习', '练习减法运算，掌握计算技巧', ['#f87171', '#dc2626'], () => {
        this.prepareMode('subtraction')
      })

      this.MenuCard('✖️', '乘法练习', '九九乘法表，轻松掌握', ['#c084fc', '#7c3aed'], () => {
        this.prepareMode('multiplication')
      })

      this.MenuCard('➗', '除法练习', '练习除法运算，提高逻辑思维', ['#a5b4fc', '#4338ca'], () => {
        this.prepareMode('division')
      })
    }
    .width('100%')
  }

  @Builder
  MenuCard(icon: string, title: string, description: string, gradientColors: string[], onClick: () => void) {
    Stack() {
      Column({ space: 12 }) {
        Text(icon)
          .fontSize(36)
          .opacity(0.95)

        Text(title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)

        Text(description)
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.85)')
          .lineHeight(20)

        Row() {
          Text('开始练习 →')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('rgba(255,255,255,0.92)')
        }
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        .backgroundColor('rgba(255,255,255,0.25)')
        .borderRadius(20)
        .alignItems(VerticalAlign.Center)
      }
      .padding({ left: 20, right: 20, top: 20, bottom: 20 })
    }
    .width('100%')
    .backgroundColor(Color.Transparent)
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [[gradientColors[0], 0.0], [gradientColors[1], 1.0]]
    })
    .borderRadius(24)
    .shadow({ radius: 16, color: '#00000025', offsetX: 0, offsetY: 8 })
    .onClick(() => { onClick() })
  }

  // ---------------------
  // 比大小模式
  // ---------------------
  @Builder
  RenderComparison() {
    Column({ space: 12 }) {
      // 统计信息卡片
      Row() {
        Row({ space: 12 }) {
          Row({ space: 4 }) {
            Text('⭐')
              .fontSize(18)
            Text(this.correctAnswers.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#eab308')
          }
          
          Text(`正确率: ${this.totalProblems > 0 ? Math.round((this.correctAnswers / this.totalProblems) * 100) : 0}%`)
            .fontSize(14)
            .fontColor('#6b7280')
          
          Text(`已完成: ${this.totalProblems} 题`)
            .fontSize(14)
            .fontColor('#6b7280')
        }
        
        Blank()
        
        Button('换一题')
          .fontSize(14)
          .fontColor('#3b82f6')
          .backgroundColor('#dbeafe')
          .borderRadius(20)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(() => { this.generateComparisonQuestion() })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
      
      // 操作说明
      Text('拖拽或点击符号到中间，比较两个数字的大小关系')
        .fontSize(14)
        .fontColor('#6b7280')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 4 })

      if (this.comparisonQuestion) {
        Column({ space: 12 }) {
          Row({ space: 12 }) {
            this.ComparisonNumber(this.comparisonQuestion.left)
            this.ComparisonNumber(this.comparisonQuestion.right)
          }
          .justifyContent(FlexAlign.Center)

          Row({ space: 12 }) {
            ForEach(this.createOperatorArray(), (operator: ComparisonOperator) => {
              Button(operator)
                .fontSize(18)
                .fontColor(this.getOperatorForeground(operator))
                .backgroundColor(this.getOperatorBackground(operator))
                .borderRadius(18)
                .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                .onClick(() => { this.handleComparisonOperator(operator) })
            })
          }
          .justifyContent(FlexAlign.SpaceAround)

          if (this.showComparisonResult) {
            Text(this.comparisonFeedback)
              .fontSize(16)
              .fontColor(this.comparisonFeedback.indexOf('闯关成功') >= 0 ? '#10b981' : '#ef4444')
              .fontWeight(FontWeight.Medium)
              .textAlign(TextAlign.Center)
              .margin({ top: 4 })
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .shadow({ radius: 12, color: '#00000015', offsetX: 0, offsetY: 8 })
      }

      // 操作提示卡片
      Row() {
        Row({ space: 8 }) {
          Text('👆')
            .fontSize(20)
          Text('点击符号')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3b82f6')
        }
        
        Text('或')
          .fontSize(14)
          .fontColor('#93c5fd')
          .margin({ left: 8, right: 8 })
        
        Row({ space: 8 }) {
          Text('🖱️')
            .fontSize(20)
          Text('拖拽到中间')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3b82f6')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#eff6ff')
      .borderRadius(16)
      
      // 鼓励话语
      Row() {
        Text('❤️')
          .fontSize(18)
          .margin({ right: 8 })
        Text(this.getEncouragementMessage())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6b7280')
      }
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
  }
  
  private getEncouragementMessage(): string {
    if (this.correctAnswers === 0) {
      return '仔细观察，你一定可以的！'
    } else if (this.correctAnswers < 5) {
      return '做得不错，继续努力！'
    } else if (this.correctAnswers < 10) {
      return '太棒了！你的观察力很强！'
    } else {
      return '哇！你是比较大师！'
    }
  }

  @Builder
  ComparisonNumber(value: number) {
    Column() {
      Text(value.toString())
        .fontSize(40)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')
        .textAlign(TextAlign.Center)
    }
    .width('44%')
    .padding({ top: 24, bottom: 24 })
    .backgroundColor('#f1f5f9')
    .borderRadius(20)
    .shadow({ radius: 10, color: '#00000010', offsetX: 0, offsetY: 6 })
  }

  private generateComparisonQuestion() {
    // 先置空，强制触发状态更新
    this.comparisonQuestion = null
    this.comparisonFeedback = ''
    this.selectedComparisonOperator = null
    this.showComparisonResult = false
    
    // 强制刷新计数器
    this.questionRefreshKey++

    let left = Math.floor(Math.random() * 90) + 10
    let right = Math.floor(Math.random() * 90) + 10

    if (this.previousComparisonQuestion) {
      let guard = 0
      while (left === this.previousComparisonQuestion.left &&
        right === this.previousComparisonQuestion.right &&
        guard < 5) {
        left = Math.floor(Math.random() * 90) + 10
        right = Math.floor(Math.random() * 90) + 10
        guard++
      }
    }

    // 使用 setTimeout 确保状态更新分离
    setTimeout(() => {
      // 创建新对象以触发响应式更新
      this.comparisonQuestion = { left: left, right: right }
      this.previousComparisonQuestion = { left: left, right: right }
      this.audioManager.speakText(`左边是${left}，右边是${right}，哪个更大呢？`)
    }, 50)
  }

  private createOperatorArray(): ComparisonOperator[] {
    return ['>' as ComparisonOperator, '<' as ComparisonOperator, '=' as ComparisonOperator]
  }

  private handleComparisonOperator(operator: ComparisonOperator) {
    if (this.showComparisonResult || this.comparisonQuestion === null) {
      return
    }
    this.selectedComparisonOperator = operator
    if (operator === '>') {
      this.checkComparison('left')
    } else if (operator === '<') {
      this.checkComparison('right')
    } else {
      this.checkComparison('equal')
    }
    this.showComparisonResult = true
  }

  private getCorrectOperator(): ComparisonOperator | null {
    if (!this.comparisonQuestion) {
      return null
    }
    if (this.comparisonQuestion.left > this.comparisonQuestion.right) {
      return '>'
    }
    if (this.comparisonQuestion.left < this.comparisonQuestion.right) {
      return '<'
    }
    return '='
  }

  private getOperatorBackground(operator: ComparisonOperator): string {
    if (!this.showComparisonResult) {
      return this.selectedComparisonOperator === operator ? '#2563eb' : '#f1f5f9'
    }
    const correct: ComparisonOperator | null = this.getCorrectOperator()
    if (operator === correct) {
      return '#22c55e'
    }
    if (this.selectedComparisonOperator === operator && operator !== correct) {
      return '#ef4444'
    }
    return '#f1f5f9'
  }

  private getOperatorForeground(operator: ComparisonOperator): string | ResourceColor {
    if (!this.showComparisonResult) {
      return this.selectedComparisonOperator === operator ? Color.White : '#1f2937'
    }
    const correct: ComparisonOperator | null = this.getCorrectOperator()
    if (operator === correct) {
      return Color.White
    }
    if (this.selectedComparisonOperator === operator && operator !== correct) {
      return Color.White
    }
    return '#1f2937'
  }

  private checkComparison(selection: 'left' | 'right' | 'equal') {
    if (!this.comparisonQuestion) {
      return
    }

    const left = this.comparisonQuestion.left
    const right = this.comparisonQuestion.right
    let isCorrect = false

    switch (selection) {
      case 'left':
        isCorrect = left > right
        break
      case 'right':
        isCorrect = right > left
        break
      case 'equal':
        isCorrect = left === right
        break
    }

    // 更新统计数据
    this.totalProblems++
    if (isCorrect) {
      this.correctAnswers++
      this.comparisonFeedback = '闯关成功！你真棒！'
      this.audioManager.speakText('回答正确，太棒了！')
    } else {
      const relation = left > right ? '左边更大' : (right > left ? '右边更大' : '它们一样大')
      this.comparisonFeedback = `答错了，${relation}。`
      this.audioManager.speakText(`答错了，${relation}`)
    }
  }

  // ---------------------
  // 四则运算模式
  // ---------------------
  @Builder
  RenderPractice() {
    Column({ space: 12 }) {
      // 统计信息卡片（顶部）
      Row() {
        Row({ space: 12 }) {
          Row({ space: 4 }) {
            Text('⭐')
              .fontSize(18)
            Text(this.score.toString())
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#eab308')
          }
          
          Text(`正确率: ${this.totalProblems > 0 ? Math.round((this.correctAnswers / this.totalProblems) * 100) : 0}%`)
            .fontSize(14)
            .fontColor('#6b7280')
          
          Text(`已完成: ${this.totalProblems} 题`)
            .fontSize(14)
            .fontColor('#6b7280')
        }
        
        Blank()
        
        Button('换一题')
          .fontSize(14)
          .fontColor('#3b82f6')
          .backgroundColor('#dbeafe')
          .borderRadius(20)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .onClick(() => { this.generateProblemForMode(this.currentMode) })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius(16)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
      
      // 操作说明
      Text('输入正确答案，点击检查按钮或按回车提交')
        .fontSize(14)
        .fontColor('#6b7280')
        .textAlign(TextAlign.Center)
        .width('100%')
        .margin({ top: 4 })

      if (this.currentProblem) {
        Column({ space: 16 }) {
          Text(this.currentProblem.question)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1f2937')
            .textAlign(TextAlign.Center)

          TextInput({ placeholder: '输入答案', text: this.userAnswer })
            .type(InputType.Number)
            .fontSize(24)
            .textAlign(TextAlign.Center)
            .width(200)
            .height(60)
            .backgroundColor('#f8fafc')
            .borderRadius(16)
            .border({ width: 2, color: '#e2e8f0' })
            .onChange((value: string) => {
              this.userAnswer = value
            })
            .onSubmit(() => {
              this.checkAnswer()
            })

          Row({ space: 12 }) {
            Button('检查答案')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#34d399')
              .borderRadius(18)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .onClick(() => { this.checkAnswer() })

            Button('下一题')
              .fontSize(16)
              .fontColor(Color.White)
              .backgroundColor('#3b82f6')
              .borderRadius(18)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
              .onClick(() => { this.nextProblem() })
          }

          if (this.showResult) {
            Column({ space: 8 }) {
              Text(this.isCorrect ? '🎉 回答正确！太棒了！' : '❌ 回答错误')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.isCorrect ? '#10b981' : '#ef4444')
                .textAlign(TextAlign.Center)

              if (!this.isCorrect && this.currentProblem) {
                Text(`正确答案是: ${this.currentProblem.answer}`)
                  .fontSize(18)
                  .fontColor('#6b7280')
                  .textAlign(TextAlign.Center)
              }
            }
            .width('100%')
            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
            .backgroundColor(this.isCorrect ? '#dcfce7' : '#fee2e2')
            .borderRadius(16)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 24, bottom: 24 })
        .backgroundColor(Color.White)
        .borderRadius(24)
        .shadow({ radius: 16, color: '#00000015', offsetX: 0, offsetY: 10 })
      }

      // 操作提示卡片
      Row() {
        Row({ space: 8 }) {
          Text('⌨️')
            .fontSize(20)
          Text('输入答案')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3b82f6')
        }
        
        Text('然后')
          .fontSize(14)
          .fontColor('#93c5fd')
          .margin({ left: 8, right: 8 })
        
        Row({ space: 8 }) {
          Text('✅')
            .fontSize(20)
          Text('点击检查')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#3b82f6')
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#eff6ff')
      .borderRadius(16)
      
      // 鼓励话语
      Row() {
        Text('❤️')
          .fontSize(18)
          .margin({ right: 8 })
        Text(this.getPracticeEncouragementMessage())
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#6b7280')
      }
      .padding({ left: 20, right: 20, top: 12, bottom: 12 })
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({ radius: 8, color: '#00000010', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
  }
  
  private getPracticeEncouragementMessage(): string {
    if (this.correctAnswers === 0) {
      return '加油！认真计算，你一定可以的！'
    } else if (this.correctAnswers < 5) {
      return '做得不错，继续保持！'
    } else if (this.correctAnswers < 10) {
      return '太棒了！你的计算能力很强！'
    } else {
      return '哇！你是计算小天才！'
    }
  }

  @Builder
  StatItem(value: string, label: string, color: string) {
    Column() {
      Text(value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(12)
        .fontColor('#6b7280')
        .opacity(0.9)
    }
    .alignItems(HorizontalAlign.Center)
  }

  private getModeTitle(): string {
    switch (this.currentMode) {
      case 'menu':
        return '数学练习'
      case 'comparison':
        return '比大小游戏'
      case 'addition':
        return '加法练习'
      case 'subtraction':
        return '减法练习'
      case 'multiplication':
        return '乘法练习'
      case 'division':
        return '除法练习'
      default:
        return '数学练习'
    }
  }

  private generateProblemForMode(mode: PracticeMode) {
    let num1 = 0
    let num2 = 0
    let answer = 0
    let operator = '+'

    switch (mode) {
      case 'addition':
        operator = '+'
        num1 = Math.floor(Math.random() * 50) + 1
        num2 = Math.floor(Math.random() * 50) + 1
        answer = num1 + num2
        break
      case 'subtraction':
        operator = '-'
        num1 = Math.floor(Math.random() * 80) + 20
        num2 = Math.floor(Math.random() * num1) + 1
        answer = num1 - num2
        break
      case 'multiplication':
        operator = '×'
        num1 = Math.floor(Math.random() * 9) + 2
        num2 = Math.floor(Math.random() * 9) + 2
        answer = num1 * num2
        break
      case 'division':
        operator = '÷'
        answer = Math.floor(Math.random() * 9) + 2
        num2 = Math.floor(Math.random() * 9) + 2
        num1 = answer * num2
        break
      default:
        operator = '+'
        num1 = Math.floor(Math.random() * 50) + 1
        num2 = Math.floor(Math.random() * 50) + 1
        answer = num1 + num2
        break
    }

    this.currentProblem = {
      question: `${num1} ${operator} ${num2} = ?`,
      answer,
      num1,
      num2,
      operator
    }

    this.userAnswer = ''
    this.showResult = false
    
    // 使用speakQuestion方法播报题目
    setTimeout(() => {
      this.audioManager.speakQuestion(this.currentProblem!.question)
    }, 500)
  }

  private getOperationText(operator: string): string {
    switch (operator) {
      case '+':
        return '加'
      case '-':
        return '减'
      case '×':
        return '乘以'
      case '÷':
        return '除以'
      default:
        return operator
    }
  }

  private checkAnswer() {
    if (!this.currentProblem || this.userAnswer.trim() === '') {
      return
    }

    const numericAnswer = parseFloat(this.userAnswer)
    this.isCorrect = Math.abs(numericAnswer - this.currentProblem.answer) < 0.0001
    this.showResult = true

    if (this.isCorrect) {
      this.correctAnswers++
      this.score += 10
      // 播放鼓励语音
      this.audioManager.speakEncouragement(true)
      // 触发庆祝动画
      this.triggerCelebration()
    } else {
      // 先播放鼓励语音，然后播报正确答案
      this.audioManager.speakEncouragement(false)
      setTimeout(() => {
        this.audioManager.speakText(`正确答案是 ${this.currentProblem!.answer}`)
      }, 2000)
    }

    this.totalProblems++

    const updatedStats: LearningStats = {
      totalProblems: this.learningStats.totalProblems + 1,
      correctAnswers: this.learningStats.correctAnswers + (this.isCorrect ? 1 : 0),
      score: this.learningStats.score + (this.isCorrect ? 10 : 0)
    }
    this.updateStats(updatedStats)
  }
  
  // 触发庆祝动画
  private triggerCelebration() {
    this.showCelebration = true
    this.celebrationOpacity = 1
    this.celebrationScale = 0.5
    
    animateTo({
      duration: 600,
      curve: Curve.EaseOut,
      onFinish: () => {
        animateTo({
          duration: 300,
          onFinish: () => {
            this.showCelebration = false
            this.celebrationOpacity = 0
          }
        }, () => {
          this.celebrationOpacity = 0
        })
      }
    }, () => {
      this.celebrationScale = 1.5
    })
  }

  private nextProblem() {
    if (this.currentMode === 'comparison') {
      this.generateComparisonQuestion()
    } else if (this.currentMode !== 'menu') {
      this.generateProblemForMode(this.currentMode)
    }
  }
}
