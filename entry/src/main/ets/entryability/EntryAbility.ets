import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

import common from '@ohos.app.ability.common';

export default class EntryAbility extends UIAbility {
  public static context: common.UIAbilityContext;
  public static windowStage: window.WindowStage;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    EntryAbility.context = this.context as common.UIAbilityContext;
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageCreate');
    EntryAbility.windowStage = windowStage;
    this.loadPageWithFallback(windowStage, 'pages/WebContainer', 'pages/SimulatorHome');
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(0x0000, 'testTag', '%{public}s', 'Ability onBackground');
  }

  private loadPageWithFallback(windowStage: window.WindowStage, page: string, fallback: string): void {
    hilog.info(0x0000, 'testTag', 'Try load page: %{public}s', page);
    windowStage.loadContent(page, (err) => {
      if (!err.code) {
        hilog.info(0x0000, 'testTag', 'Loaded page success: %{public}s', page);
        return;
      }

      hilog.error(0x0000, 'testTag', 'Load page failed: %{public}s, error=%{public}s', page, JSON.stringify(err) ?? '');
      hilog.info(0x0000, 'testTag', 'Try fallback page: %{public}s', fallback);
      windowStage.loadContent(fallback, (fallbackErr) => {
        if (fallbackErr.code) {
          hilog.error(0x0000, 'testTag', 'Fallback page failed: %{public}s, error=%{public}s', fallback, JSON.stringify(fallbackErr) ?? '');
          return;
        }
        hilog.info(0x0000, 'testTag', 'Fallback page loaded: %{public}s', fallback);
      });
    });
  }
}
