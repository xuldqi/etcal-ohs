import { webview } from '@kit.ArkWeb';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import { router } from '@kit.ArkUI';
import JSBridge from '../common/bridge/JSBridge';

@Entry
@Component
struct WebContainer {
  webviewController: webview.WebviewController = new webview.WebviewController();
  private jsBridge: JSBridge = new JSBridge();
  @State currentRoute: string = '/';

  aboutToAppear() {
    console.info('WebContainer aboutToAppear');
  }

  build() {
    Column() {
      // 纯净的全屏WebView，不添加任何额外UI元素
      Web({ 
        src: $rawfile('react-app/index.html'),
        controller: this.webviewController 
      })
        .width('100%')
        .height('100%')
        .javaScriptProxy({
          object: this.jsBridge,
          name: "HarmonyBridgeNative",
          methodList: ["postMessage"],
          controller: this.webviewController
        })
        .onPageBegin(() => {
          console.info('Web页面开始加载');
          // 初始化JSBridge，异常只记录不阻断页面生命周期
          try {
            this.jsBridge.init(this.webviewController, getContext(this) as common.UIAbilityContext);
          } catch (error) {
            console.error('JSBridge初始化异常:', JSON.stringify(error));
          }
        })
        .onPageEnd(() => {
          console.info('Web页面加载完成');
          // 页面加载完成后设置桥接，异常只记录不阻断页面生命周期
          try {
            this.setupBridge();
            if (this.currentRoute !== '/') {
              console.info('onPageEnd: navigating to ' + this.currentRoute);
              this.webviewController.runJavaScript(`
                (function() {
                  window.location.hash = '${this.currentRoute}';
                  console.log('onPageEnd: navigated to hash ${this.currentRoute}');
                })();
              `).catch((err: Error) => {
                console.error('onPageEnd navigate runJavaScript failed:', JSON.stringify(err));
              });
            }
          } catch (error) {
            console.error('桥接设置异常:', JSON.stringify(error));
          }
        })
        .onErrorReceive((event) => {
          console.error('Web页面加载错误:', JSON.stringify(event));
        })
        .onPermissionRequest((event) => {
          if (event) {
            console.info('[WebContainer] 权限请求: ' + JSON.stringify(event.request.getAccessibleResource()));
            event.request.grant(event.request.getAccessibleResource());
          }
        })
        .onLoadIntercept((event) => {
          // 拦截 mailto: 链接，避免 WebView 导航走导致白屏
          if (event) {
            const url = event.data.getRequestUrl();
            if (url.startsWith('mailto:')) {
              console.info('[WebContainer] 拦截 mailto 跳转: ' + url);
              try {
                const context = getContext(this) as common.UIAbilityContext;
                const want: Want = {
                  action: 'ohos.want.action.sendEmail',
                  type: 'text/plain',
                  entities: ['entity.system.default'],
                  uri: url,
                };
                context.startAbility(want).catch((err: Error) => {
                  console.warn('[WebContainer] 启动邮件应用失败:', JSON.stringify(err));
                });
              } catch (e) {
                console.error('[WebContainer] startAbility error:', JSON.stringify(e));
              }
              return true; // 拦截，不让 WebView 自己处理
            }
          }
          return false; // 其他 URL 正常加载
        })
        .mediaPlayGestureAccess(false)
        .javaScriptAccess(true)
        .zoomAccess(true)
        .domStorageAccess(true)
        .fileAccess(true)
        .imageAccess(true)
        .onlineImageAccess(true)
        .mixedMode(MixedMode.All)
        .cacheMode(CacheMode.Default)
    }
    .width('100%')
    .height('100%')
  }

  private setupBridge(): void {
    // 注入HarmonyOS桥接对象到Web环境
    const bridgeScript = `
      (function() {
        // 确保HarmonyBridge对象存在
        if (!window.HarmonyBridge) {
          window.HarmonyBridge = {};
        }
        
        // 音频播放代理
        window.HarmonyBridge.audio = {
          playNumber: function(num) {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('audio_playNumber', JSON.stringify({ number: num }));
            }
          },
          playOperator: function(op) {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('audio_playOperator', JSON.stringify({ operator: op }));
            }
          },
          playDelete: function() {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('audio_playDelete', '{}');
            }
          },
          setVolume: function(vol) {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('audio_setVolume', JSON.stringify({ volume: vol }));
            }
          },
          speakText: function(text) {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('audio_speakText', JSON.stringify({ text: text }));
            }
          }
        };

        // 存储持久化代理
        var pendingStorageRequests = {};
        window.HarmonyBridge.storage = {
          getItem: function(key) {
            return new Promise(function(resolve, reject) {
              var requestId = 'req_store_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
              pendingStorageRequests[requestId] = { resolve: resolve, reject: reject };
              if (window.HarmonyBridgeNative) {
                window.HarmonyBridgeNative.postMessage('storage_getItem', JSON.stringify({ key: key, requestId: requestId }));
              } else {
                reject(new Error('HarmonyBridgeNative not available'));
              }
            });
          },
          setItem: function(key, val) {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('storage_setItem', JSON.stringify({ key: key, value: val }));
            }
          },
          removeItem: function(key) {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('storage_removeItem', JSON.stringify({ key: key }));
            }
          }
        };

        // 语音识别代理
        window.HarmonyBridge.voice = {
          startRecognition: function() {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('voice_startRecognition', '{}');
            }
          },
          stopRecognition: function() {
            if (window.HarmonyBridgeNative) {
              window.HarmonyBridgeNative.postMessage('voice_stopRecognition', '{}');
            }
          }
        };

        // 设备与权限代理
        var pendingDeviceRequests = {};
        window.HarmonyBridge.device = {
          getPlatform: function() {
            return 'harmony';
          },
          getVersion: function() {
            return '1.0.0';
          },
          requestPermission: function(permission) {
            return new Promise(function(resolve, reject) {
              var requestId = 'req_perm_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
              pendingDeviceRequests[requestId] = { resolve: resolve, reject: reject };
              if (window.HarmonyBridgeNative) {
                window.HarmonyBridgeNative.postMessage('device_requestPermission', JSON.stringify({ permission: permission, requestId: requestId }));
              } else {
                reject(new Error('HarmonyBridgeNative not available'));
              }
            });
          }
        };

        // 设置桥接回调处理函数
        window.HarmonyBridge._handleNativeCallback = function(data) {
          console.log('收到原生回调:', JSON.stringify(data));
          
          // 处理 storageCallback 类型的 Promise 回调
          if (data.event === 'storageCallback' && data.requestId && pendingStorageRequests[data.requestId]) {
            pendingStorageRequests[data.requestId].resolve(data.result);
            delete pendingStorageRequests[data.requestId];
          }

          // 处理 permissionResult 类型的 Promise 回调
          if (data.event === 'permissionResult' && data.requestId && pendingDeviceRequests[data.requestId]) {
            pendingDeviceRequests[data.requestId].resolve(data.result);
            delete pendingDeviceRequests[data.requestId];
          }

          // 触发自定义事件供 React App 适配层监听
          var event = new CustomEvent('HarmonyBridge_' + data.event, {
            detail: data
          });
          window.dispatchEvent(event);
        };
        
        // 发送桥接就绪事件
        var readyEvent = new CustomEvent('HarmonyBridge_ready');
        window.dispatchEvent(readyEvent);
        
        console.log('HarmonyOS桥接代理已就绪');
      })();
    `;
    
    this.webviewController.runJavaScript(bridgeScript)
      .then(() => {
        console.info('桥接脚本注入成功');
      })
      .catch((error: Error) => {
        console.error('桥接脚本注入失败:', JSON.stringify(error));
      });
  }

  onPageShow() {
    try {
      const params = router.getParams() as Record<string, string>;
      if (params && params.url) {
        this.currentRoute = params.url;
        console.info('WebContainer onPageShow, currentRoute = ' + this.currentRoute);
        // 路由设置已在 onPageEnd 中处理，这里只记录日志
      }
    } catch (error) {
      console.error('onPageShow error:', JSON.stringify(error));
    }
  }

  aboutToDisappear(): void {
    // 清理资源
    this.jsBridge.destroy();
  }

  onBackPress(): boolean {
    if (this.webviewController.accessBackward()) {
      console.info('onBackPress: webview goes backward');
      this.webviewController.backward();
      return true; // 拦截系统返回事件
    }
    console.info('onBackPress: exiting container');
    return false; // 不拦截，交由系统处理（退出当前页面/应用）
  }
}
