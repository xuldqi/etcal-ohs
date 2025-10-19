import { webview } from '@kit.ArkWeb';

@Entry
@Component
struct TestWebView {
  webviewController: webview.WebviewController = new webview.WebviewController();
  @State private isLoading: boolean = true;
  @State private hasError: boolean = false;
  @State private errorMessage: string = '';
  @State private testResults: string[] = [];

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('WebView功能测试')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
        
        Blank()
        
        Button('返回')
          .onClick(() => {
            // 返回主页面的逻辑
          })
          .backgroundColor('#007AFF')
          .fontColor(Color.White)
          .borderRadius(4)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor('#f8f9fa')
      
      // 测试结果显示区域
      if (this.testResults.length > 0) {
        Column() {
          Text('测试结果:')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 8 })
          
          ForEach(this.testResults, (result: string, index: number) => {
            Text(result)
              .fontSize(12)
              .fontColor(result.includes('✅') ? '#28a745' : result.includes('❌') ? '#dc3545' : '#6c757d')
              .margin({ bottom: 4 })
          })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#ffffff')
        .margin({ bottom: 8 })
      }
      
      // WebView容器
      Stack() {
        Web({ 
          src: $rawfile('test_webview.html'),
          controller: this.webviewController 
        })
          .width('100%')
          .height('100%')
          .onPageBegin(() => {
            console.info('启动 测试WebView开始加载');
            this.isLoading = true;
            this.hasError = false;
            this.errorMessage = '';
            this.addTestResult('启动 开始加载测试页面...');
          })
          .onPageEnd(() => {
            console.info('✅ 测试WebView页面加载完成');
            this.isLoading = false;
            this.addTestResult('✅ 测试页面加载完成');
            
            // 注入测试脚本
            this.runTests();
          })
          .onErrorReceive((event) => {
            console.error('❌ 测试WebView加载错误:', JSON.stringify(event));
            this.isLoading = false;
            this.hasError = true;
            
            if (event?.error?.getErrorInfo) {
              this.errorMessage = '页面加载失败: ' + event.error.getErrorInfo();
            } else {
              this.errorMessage = '测试页面加载失败，请检查配置';
            }
            this.addTestResult('❌ ' + this.errorMessage);
          })
          .onHttpErrorReceive((event) => {
            if (event) {
              const errorMsg = 'HTTP错误: ' + event.response.getResponseCode();
              this.errorMessage = errorMsg;
              this.hasError = true;
              this.addTestResult('❌ ' + errorMsg);
            }
          })
          .javaScriptAccess(true)
          .zoomAccess(true)
          .domStorageAccess(true)
          .fileAccess(true)
          .imageAccess(true)
          .onlineImageAccess(true)
          .mixedMode(MixedMode.All)
          .cacheMode(CacheMode.Default)
          .visibility(this.hasError ? Visibility.Hidden : Visibility.Visible)

        // 加载状态指示器
        if (this.isLoading && !this.hasError) {
          Column() {
            LoadingProgress()
              .width(40)
              .height(40)
              .color('#007AFF')
            
            Text('正在加载测试页面...')
              .fontSize(14)
              .fontColor('#666666')
              .margin({ top: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('rgba(255, 255, 255, 0.9)')
          .zIndex(100)
        }

        // 错误状态显示
        if (this.hasError) {
          Column() {
            Text('⚠️')
              .fontSize(48)
              .margin({ bottom: 16 })
            
            Text('测试页面加载失败')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 8 })
            
            Text(this.errorMessage)
              .fontSize(14)
              .fontColor('#666666')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 24 })
            
            Button('重新测试')
              .onClick(() => {
                this.reloadTest();
              })
              .backgroundColor('#007AFF')
              .fontColor(Color.White)
              .borderRadius(8)
              .padding({ left: 24, right: 24, top: 12, bottom: 12 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(Color.White)
          .zIndex(200)
        }
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
  
  private addTestResult(result: string): void {
    this.testResults.push(result);
    // 限制结果数量，避免界面过长
    if (this.testResults.length > 10) {
      this.testResults.shift();
    }
  }
  
  private runTests(): void {
    // 测试JavaScript执行
    const testScript = `
      try {
        // 测试基本功能
        const test1 = [1,2,3].map(x => x*2);
        console.log('JavaScript基本功能测试通过');
        
        // 测试DOM操作
        const testDiv = document.createElement('div');
        testDiv.textContent = 'DOM测试';
        console.log('DOM操作测试通过');
        
        // 测试Promise
        Promise.resolve('Promise测试').then(result => {
          console.log('Promise功能测试通过: ' + result);
        });
        
        // 返回测试结果
        'WebView功能测试完成';
      } catch (error) {
        'WebView功能测试失败: ' + error.message;
      }
    `;
    
    this.webviewController.runJavaScript(testScript)
      .then((result) => {
        console.info('✅ JavaScript测试结果:', result);
        this.addTestResult('✅ JavaScript执行测试: ' + result);
      })
      .catch((error: Error) => {
        console.error('❌ JavaScript测试失败:', JSON.stringify(error));
        this.addTestResult('❌ JavaScript执行失败: ' + error.message);
      });
  }
  
  private reloadTest(): void {
    console.info('刷新 重新加载测试页面');
    this.hasError = false;
    this.isLoading = true;
    this.errorMessage = '';
    this.testResults = [];
    
    try {
      this.webviewController.refresh();
    } catch (error) {
      console.error('❌ 测试页面重新加载失败:', JSON.stringify(error));
      this.hasError = true;
      this.errorMessage = '重新加载失败';
      this.addTestResult('❌ 重新加载失败');
    }
  }
  
  aboutToDisappear(): void {
    console.info('清理 TestWebView组件销毁');
  }
}