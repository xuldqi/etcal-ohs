// 简化的存储管理器：使用内存 Map 模拟持久化能力

import common from '@ohos.app.ability.common'
import preferences from '@ohos.data.preferences'

interface StorageEntry {
  key: string
  value: string
}

export interface StudyStats {
  totalTime: number
  totalQuestions: number
  correctAnswers: number
  correctRate: number
  currentStreak: number
  bestStreak: number
  lastStudyDate: string
  studyDays: number
}

export interface AnswerRecord {
  id: string
  question: string
  userAnswer: string
  correctAnswer: string
  isCorrect: boolean
  type: string
  timeSpent: number
  timestamp: string
}

export interface StudySession {
  id: string
  startTime: string
  endTime: string
  duration: number
  questionsAnswered: number
  correctAnswers: number
  source: string
  answers: AnswerRecord[]
}

export interface DailyProgress {
  date: string
  questionsAnswered: number
  correctRate: number
  timeSpent: number
  sessions: number
}

export interface WrongQuestion {
  id: string
  question: string
  userAnswer: string
  correctAnswer: string
  type: string
  date: string
  reviewCount: number
  mastered: boolean
}

const CALCULATION_HISTORY_KEY = 'calculation_history'
const STUDY_STATS_KEY = 'study_stats'
const STUDY_SESSIONS_KEY = 'study_sessions'
const DAILY_PROGRESS_KEY = 'daily_progress'
const WRONG_QUESTIONS_KEY = 'wrong_questions'
const CURRENT_SESSION_KEY = 'current_session'

export class StorageManager {
  private static instance: StorageManager | null = null
  private store: Map<string, string> = new Map()
  private context: common.UIAbilityContext | null = null
  private preferencesStore: preferences.Preferences | null = null

  private constructor() {}

  static getInstance(): StorageManager {
    if (!StorageManager.instance) {
      StorageManager.instance = new StorageManager()
    }
    return StorageManager.instance
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context
    try {
      // 初始化持久化存储
      this.preferencesStore = await preferences.getPreferences(context, 'chmath_storage')
      console.log('[存储] 持久化存储初始化成功')
    } catch (error) {
      console.error('[存储] 持久化存储初始化失败:', error)
    }
  }

  async setItem(key: string, value: string): Promise<void> {
    // 同时保存到内存和持久化存储
    this.store.set(key, value)
    if (this.preferencesStore) {
      try {
        await this.preferencesStore.put(key, value)
        await this.preferencesStore.flush()
        console.log(`[存储] 持久化保存: ${key} = ${value}`)
      } catch (error) {
        console.error(`[存储] 持久化保存失败: ${key}`, error)
      }
    }
  }

  async getItem(key: string): Promise<string | null> {
    // 优先从持久化存储读取
    if (this.preferencesStore) {
      try {
        const value = await this.preferencesStore.get(key, '') as string
        if (value !== '') {
          // 同步到内存
          this.store.set(key, value)
          console.log(`[存储] 从持久化存储读取: ${key} = ${value}`)
          return value
        }
      } catch (error) {
        console.error(`[存储] 从持久化存储读取失败: ${key}`, error)
      }
    }
    
    // 如果持久化存储失败，从内存读取
    if (this.store.has(key)) {
      return this.store.get(key) as string
    }
    return null
  }

  async hasKey(key: string): Promise<boolean> {
    return this.store.has(key)
  }

  async getAllKeys(): Promise<string[]> {
    return Array.from(this.store.keys())
  }

  async getSize(): Promise<number> {
    return this.store.size
  }

  async removeItem(key: string): Promise<void> {
    // 同时从内存和持久化存储删除
    this.store.delete(key)
    if (this.preferencesStore) {
      try {
        await this.preferencesStore.delete(key)
        await this.preferencesStore.flush()
        console.log(`[存储] 持久化删除: ${key}`)
      } catch (error) {
        console.error(`[存储] 持久化删除失败: ${key}`, error)
      }
    }
  }

  async clear(): Promise<void> {
    // 同时清空内存和持久化存储
    this.store.clear()
    if (this.preferencesStore) {
      try {
        await this.preferencesStore.clear()
        await this.preferencesStore.flush()
        console.log('[存储] 持久化清空完成')
      } catch (error) {
        console.error('[存储] 持久化清空失败:', error)
      }
    }
  }

  async setBatch(entries: StorageEntry[]): Promise<void> {
    // 同时保存到内存和持久化存储
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i]
      this.store.set(entry.key, entry.value)
    }
    
    if (this.preferencesStore) {
      try {
        for (let i = 0; i < entries.length; i++) {
          const entry = entries[i]
          await this.preferencesStore.put(entry.key, entry.value)
        }
        await this.preferencesStore.flush()
        console.log(`[存储] 批量持久化保存: ${entries.length} 项`)
      } catch (error) {
        console.error('[存储] 批量持久化保存失败:', error)
      }
    }
  }

  async getBatch(keys: string[]): Promise<StorageEntry[]> {
    const result: StorageEntry[] = []
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i]
      const value = this.store.get(key)
      if (value !== undefined) {
        result.push({ key, value })
      }
    }
    return result
  }

  async exportData(): Promise<StorageEntry[]> {
    const snapshot: StorageEntry[] = []
    const iterator = this.store.entries()
    for (const entry of iterator) {
      const key = entry[0]
      const value = entry[1]
      snapshot.push({ key, value })
    }
    return snapshot
  }

  async saveCalculationHistory(history: string[]): Promise<boolean> {
    await this.setItem(CALCULATION_HISTORY_KEY, JSON.stringify(history))
    return true
  }

  async loadCalculationHistory(): Promise<string[]> {
    const stored = await this.getItem(CALCULATION_HISTORY_KEY)
    if (!stored) {
      return []
    }
    try {
      return JSON.parse(stored) as string[]
    } catch (error) {
      console.error('[存储] 解析计算历史失败:', error)
      return []
    }
  }

  private getDefaultStats(): StudyStats {
    return {
      totalTime: 0,
      totalQuestions: 0,
      correctAnswers: 0,
      correctRate: 0,
      currentStreak: 0,
      bestStreak: 0,
      lastStudyDate: '',
      studyDays: 0
    }
  }

  async loadStudyStats(): Promise<StudyStats> {
    const stored = await this.getItem(STUDY_STATS_KEY)
    if (!stored) {
      return this.getDefaultStats()
    }
    try {
      return JSON.parse(stored) as StudyStats
    } catch (error) {
      console.error('[存储] 解析学习统计失败:', error)
      return this.getDefaultStats()
    }
  }

  async saveStudyStats(stats: StudyStats): Promise<void> {
    await this.setItem(STUDY_STATS_KEY, JSON.stringify(stats))
  }

  async updateStudyStats(questionsAnswered: number, correctAnswers: number, timeSpent: number): Promise<void> {
    const stats = await this.loadStudyStats()
    stats.totalQuestions += questionsAnswered
    stats.correctAnswers += correctAnswers
    if (stats.totalQuestions > 0) {
      stats.correctRate = Math.round((stats.correctAnswers / stats.totalQuestions) * 10000) / 100
    } else {
      stats.correctRate = 0
    }
    stats.totalTime += timeSpent

    const today = this.getDateString(0)
    const yesterday = this.getDateString(-1)

    if (stats.lastStudyDate === today) {
      // 同一天重复学习，不改变连续天数
    } else if (stats.lastStudyDate === yesterday) {
      stats.currentStreak += 1
    } else {
      stats.currentStreak = stats.totalQuestions > 0 ? 1 : 0
    }

    if (stats.currentStreak > stats.bestStreak) {
      stats.bestStreak = stats.currentStreak
    }

    if (stats.lastStudyDate !== today) {
      stats.lastStudyDate = today
      stats.studyDays += 1
    }

    await this.saveStudyStats(stats)
    
    // 同时更新每日进度
    await this.updateDailyProgress(questionsAnswered, correctAnswers, timeSpent)
  }

  private getDateString(offset: number): string {
    const date = new Date()
    date.setDate(date.getDate() + offset)
    return date.toISOString().split('T')[0]
  }

  async startSession(source: string): Promise<string> {
    const sessionId = `session_${Date.now()}`
    const session: StudySession = {
      id: sessionId,
      startTime: new Date().toISOString(),
      endTime: '',
      duration: 0,
      questionsAnswered: 0,
      correctAnswers: 0,
      source,
      answers: []
    }
    await this.setItem(CURRENT_SESSION_KEY, JSON.stringify(session))
    return sessionId
  }

  async endSession(sessionId: string, duration: number, questionsAnswered: number, correctAnswers: number): Promise<void> {
    const stored = await this.getItem(CURRENT_SESSION_KEY)
    if (!stored) {
      return
    }
    try {
      const session = JSON.parse(stored) as StudySession
      if (session.id !== sessionId) {
        return
      }
      session.endTime = new Date().toISOString()
      session.duration = duration
      session.questionsAnswered = questionsAnswered
      session.correctAnswers = correctAnswers

      const sessions = await this.loadStudySessions()
      sessions.push(session)
      await this.saveStudySessions(sessions)
      await this.removeItem(CURRENT_SESSION_KEY)
    } catch (error) {
      console.error('[存储] 结束学习会话失败:', error)
    }
  }

  async addAnswerRecord(sessionId: string, record: AnswerRecord): Promise<void> {
    const stored = await this.getItem(CURRENT_SESSION_KEY)
    if (!stored) {
      return
    }
    try {
      const session = JSON.parse(stored) as StudySession
      if (session.id !== sessionId) {
        return
      }
      session.answers.push(record)
      await this.setItem(CURRENT_SESSION_KEY, JSON.stringify(session))
    } catch (error) {
      console.error('[存储] 添加答题记录失败:', error)
    }
  }

  async loadStudySessions(): Promise<StudySession[]> {
    const stored = await this.getItem(STUDY_SESSIONS_KEY)
    if (!stored) {
      return []
    }
    try {
      return JSON.parse(stored) as StudySession[]
    } catch (error) {
      console.error('[存储] 解析学习会话失败:', error)
      return []
    }
  }

  async saveStudySessions(sessions: StudySession[]): Promise<void> {
    await this.setItem(STUDY_SESSIONS_KEY, JSON.stringify(sessions))
  }

  async loadDailyProgress(): Promise<DailyProgress[]> {
    const stored = await this.getItem(DAILY_PROGRESS_KEY)
    if (!stored) {
      return []
    }
    try {
      return JSON.parse(stored) as DailyProgress[]
    } catch (error) {
      console.error('[存储] 解析每日进度失败:', error)
      return []
    }
  }

  async saveDailyProgress(progress: DailyProgress[]): Promise<void> {
    await this.setItem(DAILY_PROGRESS_KEY, JSON.stringify(progress))
  }
  
  // 更新每日进度，在每次答题后自动调用
  async updateDailyProgress(questionsAnswered: number, correctAnswers: number, timeSpent: number): Promise<void> {
    const today = this.getDateString(0)
    const progress = await this.loadDailyProgress()
    
    // 查找今天的记录
    let todayProgress = progress.find(p => p.date === today)
    
    if (todayProgress) {
      // 更新今天的记录
      todayProgress.questionsAnswered += questionsAnswered
      const totalCorrect = Math.round(todayProgress.correctRate * todayProgress.questionsAnswered / 100) + correctAnswers
      todayProgress.correctRate = Math.round((totalCorrect / todayProgress.questionsAnswered) * 100)
      todayProgress.timeSpent += timeSpent
      todayProgress.sessions += 1
    } else {
      // 创建今天的记录
      const correctRate = questionsAnswered > 0 ? Math.round((correctAnswers / questionsAnswered) * 100) : 0
      todayProgress = {
        date: today,
        questionsAnswered: questionsAnswered,
        correctRate: correctRate,
        timeSpent: timeSpent,
        sessions: 1
      }
      progress.push(todayProgress)
    }
    
    await this.saveDailyProgress(progress)
    console.log(`[存储] 更新每日进度: ${today}, 题目: ${todayProgress.questionsAnswered}, 正确率: ${todayProgress.correctRate}%`)
  }

  async loadWrongQuestions(): Promise<WrongQuestion[]> {
    const stored = await this.getItem(WRONG_QUESTIONS_KEY)
    if (!stored) {
      return []
    }
    try {
      return JSON.parse(stored) as WrongQuestion[]
    } catch (error) {
      console.error('[存储] 解析错题本失败:', error)
      return []
    }
  }

  async saveWrongQuestions(questions: WrongQuestion[]): Promise<void> {
    await this.setItem(WRONG_QUESTIONS_KEY, JSON.stringify(questions))
  }

  async setPrivacyAgreement(agreed: boolean): Promise<void> {
    await this.setItem('privacy_agreement', JSON.stringify(agreed))
    console.log('隐私说明同意状态已保存:', agreed)
  }

  async getPrivacyAgreement(): Promise<boolean> {
    try {
      const stored = await this.getItem('privacy_agreement')
      if (!stored) {
        return false
      }
      return JSON.parse(stored) as boolean
    } catch (error) {
      console.error('获取隐私说明同意状态失败:', error)
      return false
    }
  }
}
