import {
  CSJAdSdk,
  SDKConfigBuilder,
  AdSlotBuilder,
  CSJFullAd,
  FullAdLoadListener,
  FullAdInteractionListener
} from '@csj/openadsdk';
import EntryAbility from '../../entryability/EntryAbility';
import { display } from '@kit.ArkUI';
import common from '@ohos.app.ability.common';

/**
 * 穿山甲鸿蒙广告管理类
 * 应用ID: 5862338 (儿童语音计算器)
 * 新插屏广告位ID: 990665007
 */
export class AdManager {
  private static instance: AdManager;
  private readonly APP_ID: string = '5862338';
  private readonly APP_NAME: string = '儿童语音计算器';
  private readonly CODE_ID: string = '990665007';

  private isInitialized: boolean = false;
  private isInitializing: boolean = false;
  private isAdLoading: boolean = false;
  private isAdShowing: boolean = false;
  private cachedAd: CSJFullAd | null = null;
  private lastShowTime: number = 0;
  private readonly MIN_INTERVAL_MS: number = 60000; // 最小展示间隔 60 秒

  private constructor() {}

  public static getInstance(): AdManager {
    if (!AdManager.instance) {
      AdManager.instance = new AdManager();
    }
    return AdManager.instance;
  }

  /**
   * 仅在用户同意隐私政策后初始化穿山甲 SDK
   */
  public async initIfConsented(context?: common.UIAbilityContext): Promise<boolean> {
    if (this.isInitialized) {
      return true;
    }
    if (this.isInitializing) {
      return false;
    }

    const ctx = context || EntryAbility.context;
    if (!ctx) {
      console.warn('[AdManager] 缺少 Context，暂不初始化穿山甲 SDK');
      return false;
    }

    this.isInitializing = true;
    try {
      console.log('[AdManager] 正在初始化穿山甲 SDK, AppId: ' + this.APP_ID);
      const pangleConfig = new SDKConfigBuilder()
        .appId(this.APP_ID)
        .appName(this.APP_NAME)
        .build();

      CSJAdSdk.init(ctx, pangleConfig);
      const startResult = await CSJAdSdk.start();
      console.log('[AdManager] 穿山甲 SDK 启动完成: ' + JSON.stringify(startResult));
      this.isInitialized = true;
      this.isInitializing = false;

      // 初始化成功后预加载一次插屏广告
      this.preloadInterstitial();
      return true;
    } catch (error) {
      console.error('[AdManager] 穿山甲 SDK 初始化失败: ' + JSON.stringify(error));
      this.isInitializing = false;
      return false;
    }
  }

  /**
   * 预加载插屏广告
   */
  public preloadInterstitial(): void {
    if (!this.isInitialized) {
      void this.initIfConsented().then((ok) => {
        if (ok) {
          this.preloadInterstitial();
        }
      });
      return;
    }

    if (this.cachedAd !== null || this.isAdLoading || this.isAdShowing) {
      return;
    }

    this.isAdLoading = true;
    try {
      let width = 360;
      let height = 640;
      try {
        const disp = display.getDefaultDisplaySync();
        width = px2vp(disp.width);
        height = px2vp(disp.height);
      } catch (err) {
        console.warn('[AdManager] 获取屏幕分辨率失败，使用默认值');
      }

      const adSlot = new AdSlotBuilder()
        .setCodeId(this.CODE_ID)
        .setAcceptSize(width, height)
        .build();

      const listener: FullAdLoadListener = {
        onAdLoaded: (fullAd: CSJFullAd) => {
          console.log('[AdManager] 穿山甲插屏广告加载成功');
          this.isAdLoading = false;
          this.cachedAd = fullAd;
          if (this.pendingShowWhenLoaded) {
            this.pendingShowWhenLoaded = false;
            this.showInterstitial(true);
          }
        },
        onAdCached: (fullAd: CSJFullAd) => {
          console.log('[AdManager] 穿山甲插屏广告缓存完成');
          this.cachedAd = fullAd;
          if (this.pendingShowWhenLoaded) {
            this.pendingShowWhenLoaded = false;
            this.showInterstitial(true);
          }
        },
        onError: (code: number, message: string) => {
          console.error(`[AdManager] 穿山甲插屏广告加载失败 code: ${code}, message: ${message}`);
          this.isAdLoading = false;
          this.pendingShowWhenLoaded = false;
        }
      };

      const adCreator = CSJAdSdk.getAdCreator();
      adCreator.loadFullAd(adSlot, listener);
    } catch (e) {
      console.error('[AdManager] 穿山甲插屏广告加载异常: ' + JSON.stringify(e));
      this.isAdLoading = false;
    }
  }

  private pendingShowWhenLoaded: boolean = false;

  /**
   * 展示插屏广告
   * @param force 是否忽略时间间隔强制尝试展示
   * @param onClosed 广告关闭或跳过的回调
   * @returns boolean 是否触发了展示
   */
  public showInterstitial(force: boolean = false, onClosed?: () => void): boolean {
    if (this.isAdShowing) {
      console.log('[AdManager] 已有广告正在展示中');
      return false;
    }

    const now = Date.now();
    // 首次展示或 force 不受冷却限制，后续展示间隔 45 秒
    if (!force && this.lastShowTime > 0 && (now - this.lastShowTime < 45000)) {
      console.log('[AdManager] 插屏广告处于冷却期，跳过展示');
      return false;
    }

    const windowStage = EntryAbility.windowStage;
    if (!windowStage) {
      console.warn('[AdManager] windowStage 未准备好，无法展示广告');
      return false;
    }

    if (this.cachedAd) {
      const ad = this.cachedAd;
      this.cachedAd = null;
      this.isAdShowing = true;
      this.lastShowTime = now;
      this.pendingShowWhenLoaded = false;

      const interactionListener: FullAdInteractionListener = {
        onShow: () => {
          console.log('[AdManager] 穿山甲插屏广告展示');
          this.isAdShowing = true;
        },
        onSkip: () => {
          console.log('[AdManager] 穿山甲插屏广告跳过');
          this.isAdShowing = false;
          if (onClosed) {
            onClosed();
          }
          this.preloadInterstitial();
        },
        onClick: () => {
          console.log('[AdManager] 穿山甲插屏广告被点击');
        },
        onClose: () => {
          console.log('[AdManager] 穿山甲插屏广告关闭');
          this.isAdShowing = false;
          if (onClosed) {
            onClosed();
          }
          this.preloadInterstitial();
        },
        onComplete: () => {
          console.log('[AdManager] 穿山甲插屏广告播放完成');
        }
      };

      ad.setInteractionListener(interactionListener);
      try {
        ad.showFullAd(windowStage);
        return true;
      } catch (err) {
        console.error('[AdManager] showFullAd 抛出异常: ' + JSON.stringify(err));
        this.isAdShowing = false;
        this.preloadInterstitial();
        return false;
      }
    } else {
      console.log('[AdManager] 无缓存广告，正在请求并将在就绪后展示');
      this.pendingShowWhenLoaded = true;
      this.preloadInterstitial();
      return false;
    }
  }
}
