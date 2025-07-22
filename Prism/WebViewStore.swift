import WebKit
import Combine
import Foundation

/// 各サービスごとの WKWebView をキャッシュ
class WebViewStore: NSObject, ObservableObject {
    @Published var webViews: [String: WKWebView] = [:]
    @Published var loadingStates: [String: Bool] = [:] // WebViewの読み込み状況を追跡
    private let customServiceManager: CustomAIServiceManager
    private var cancellables: Set<AnyCancellable> = []
    private var webViewDelegates: [String: WebViewNavigationDelegate] = [:]
    private var settingsStore: SettingsStore?
    
    override init() {
        fatalError("Use init(customServiceManager:) instead")
    }
    
    init(customServiceManager: CustomAIServiceManager) {
        self.customServiceManager = customServiceManager
        super.init()
        
        // Built-in services
        for service in AIService.allCases {
            let config = createWebViewConfiguration()
            let wv = WKWebView(frame: .zero, configuration: config)
            let delegate = WebViewNavigationDelegate(serviceId: service.id) { [weak self] serviceId, isLoading in
                DispatchQueue.main.async {
                    self?.loadingStates[serviceId] = isLoading
                    if !isLoading {
                        print("✅ WebView loaded for service: \(serviceId)")
                        // WebView読み込み完了後に保存された拡大率を適用
                        self?.applyInitialZoomScale(for: serviceId)
                    }
                }
            }
            configureWebView(wv)
            wv.navigationDelegate = delegate
            webViewDelegates[service.id] = delegate
            loadingStates[service.id] = true // 初期状態は読み込み中
            wv.load(URLRequest(url: service.url))
            webViews[service.id] = wv
        }
        
        // Custom services の変更を監視
        customServiceManager.$customServices
            .sink { [weak self] _ in
                self?.updateCustomWebViews()
            }
            .store(in: &cancellables)
        
        // 初期カスタムサービスの設定
        updateCustomWebViews()
    }
    
    private func updateCustomWebViews() {
        // 既存のカスタムWebViewを削除
        let builtInServiceIds = Set(AIService.allCases.map { $0.id })
        let validCustomServiceIds = Set(customServiceManager.validServices.map { $0.id.uuidString })
        let keysToRemove = webViews.keys.filter { serviceId in
            // ビルトインサービスでも、有効なカスタムサービスでもない場合は削除
            !builtInServiceIds.contains(serviceId) && !validCustomServiceIds.contains(serviceId)
        }
        
        if !keysToRemove.isEmpty {
            print("🗑️ Removing WebViews for deleted custom services: \(keysToRemove)")
        }
        
        keysToRemove.forEach { 
            webViews.removeValue(forKey: $0)
            loadingStates.removeValue(forKey: $0)
            webViewDelegates.removeValue(forKey: $0)
        }
        
        // 新しいカスタムWebViewを追加
        for customService in customServiceManager.validServices {
            let serviceId = customService.id.uuidString
            
            // 既にWebViewが存在する場合はスキップ
            if webViews[serviceId] != nil {
                continue
            }
            
            print("➕ Creating WebView for custom service: \(customService.name) (\(serviceId))")
            let config = createWebViewConfiguration()
            let wv = WKWebView(frame: .zero, configuration: config)
            let delegate = WebViewNavigationDelegate(serviceId: serviceId) { [weak self] serviceId, isLoading in
                DispatchQueue.main.async {
                    self?.loadingStates[serviceId] = isLoading
                    if !isLoading {
                        print("✅ WebView loaded for custom service: \(serviceId)")
                        // WebView読み込み完了後に保存された拡大率を適用
                        self?.applyInitialZoomScale(for: serviceId)
                    }
                }
            }
            configureWebView(wv)
            wv.navigationDelegate = delegate
            webViewDelegates[serviceId] = delegate
            loadingStates[serviceId] = true // 初期状態は読み込み中
            
            if let url = customService.serviceURL {
                let request = URLRequest(url: url)
                wv.load(request)
            }
            
            webViews[serviceId] = wv
        }
    }
    
    // MARK: - WebView Configuration
    private func createWebViewConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        
        // セキュリティ設定
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // User Agent設定
        config.applicationNameForUserAgent = "Prism/1.0"
        
        // JavaScriptはmacOS 11以降でデフォルト有効
        // オートフィル機能で必要な場合は個別ページで制御
        
        return config
    }
    
    private func configureWebView(_ webView: WKWebView) {
        // WebViewの追加設定
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = "Prism/1.0 (macOS)"
        
        // バックグラウンド実行を維持するための設定
        if #available(macOS 11.0, *) {
            // macOS 11以降はdefaultWebpagePreferencesで制御
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = false
        
        // メディア再生の設定（macOSのWKWebViewでは利用可能なプロパティのみ使用）
        if #available(macOS 10.12, *) {
            webView.configuration.mediaTypesRequiringUserActionForPlayback = []
        }
        
        // メモリとパフォーマンス設定
        // macOS 12.0以降では WKProcessPool は非推奨のため削除（効果なし）
        
        // オートフィル機能のためのJavaScript確認
        if #available(macOS 11.0, *) {
            // macOS 11以降はデフォルトでJavaScript有効
            // 必要に応じて個別ナビゲーションで制御
        }
    }
    
    /// WebViewのズーム倍率を設定
    func setZoomScale(_ scale: Double, for serviceId: String) {
        guard let webView = webViews[serviceId] else { return }
        
        let javascript = "document.body.style.zoom = '\(scale)'"
        webView.evaluateJavaScript(javascript) { _, error in
            if let error = error {
                print("Zoom scale error: \(error)")
            }
        }
    }
    
    /// SettingsStoreの参照を設定
    func setSettingsStore(_ settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        
        // 既に読み込み完了しているWebViewに拡大率を適用
        for serviceId in webViews.keys {
            if loadingStates[serviceId] == false {
                applyInitialZoomScale(for: serviceId)
            }
        }
    }
    
    /// WebView初期化時に保存されたズーム倍率を適用
    private func applyInitialZoomScale(for serviceId: String) {
        guard let settingsStore = settingsStore else { return }
        let savedZoomScale = settingsStore.webViewZoomScale
        if savedZoomScale != 1.0 {
            print("🔍 Applying initial zoom scale \(savedZoomScale) to \(serviceId)")
            setZoomScale(savedZoomScale, for: serviceId)
        }
    }
    
    /// 全WebViewのズーム倍率を設定
    func setZoomScaleForAll(_ scale: Double) {
        for serviceId in webViews.keys {
            setZoomScale(scale, for: serviceId)
        }
    }
    
    /// WebViewが完全に読み込まれているかチェック
    func isWebViewReady(for serviceId: String) -> Bool {
        return loadingStates[serviceId] == false
    }
    
    /// 全ての組み込みAIサービスが読み込み完了しているかチェック
    func areAllBuiltInServicesReady() -> Bool {
        for service in AIService.allCases {
            if loadingStates[service.id] != false {
                return false
            }
        }
        return true
    }
    
    /// WebView読み込み完了を待つ（非同期）
    func waitForWebViewReady(serviceId: String, timeout: TimeInterval = 10.0) async -> Bool {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if isWebViewReady(for: serviceId) {
                return true
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
        }
        
        print("⚠️ WebView timeout for service: \(serviceId)")
        return false
    }
    
    // MARK: - Background State Management
    
    /// WebViewをバックグラウンドで継続実行可能な状態にする
    func enableBackgroundExecution(for serviceId: String) {
        guard let webView = webViews[serviceId] else { return }
        
        print("🔄 Enabling background execution for: \(serviceId)")
        
        let backgroundScript = """
        (function() {
            console.log('🔄 Enabling background execution for AI service...');
            
            // Page Visibility APIの監視を無効化（バックグラウンドでも動作継続）
            const originalAddEventListener = document.addEventListener;
            document.addEventListener = function(type, listener, options) {
                if (type === 'visibilitychange') {
                    console.log('🚫 Blocked visibilitychange listener to maintain background execution');
                    return; // visibilitychangeイベントリスナーの追加をブロック
                }
                return originalAddEventListener.call(this, type, listener, options);
            };
            
            // window.onfocusとwindow.onblurを無効化
            const originalWindowFocus = window.onfocus;
            const originalWindowBlur = window.onblur;
            
            window.onfocus = null;
            window.onblur = null;
            
            // documentのvisibilityStateを強制的に'visible'に維持
            Object.defineProperty(document, 'visibilityState', {
                value: 'visible',
                writable: false,
                configurable: false
            });
            
            Object.defineProperty(document, 'hidden', {
                value: false,
                writable: false,
                configurable: false
            });
            
            // WebSocketやEventSourceの接続維持
            const originalWebSocket = window.WebSocket;
            if (originalWebSocket) {
                window.WebSocket = function(url, protocols) {
                    const ws = new originalWebSocket(url, protocols);
                    
                    // 接続の維持を強化
                    const originalClose = ws.close;
                    ws.close = function() {
                        console.log('🔌 WebSocket close prevented for background execution');
                        // クローズを遅延または無効化
                    };
                    
                    return ws;
                };
            }
            
            // setTimeoutとsetIntervalの動作を保持
            const originalSetTimeout = window.setTimeout;
            const originalSetInterval = window.setInterval;
            
            window.setTimeout = function(callback, delay, ...args) {
                return originalSetTimeout.call(this, callback, Math.max(delay, 16), ...args);
            };
            
            window.setInterval = function(callback, delay, ...args) {
                return originalSetInterval.call(this, callback, Math.max(delay, 16), ...args);
            };
            
            console.log('✅ Background execution enabled for AI service');
            
            return {
                backgroundExecutionEnabled: true,
                timestamp: Date.now()
            };
        })();
        """
        
        webView.evaluateJavaScript(backgroundScript) { result, error in
            if let error = error {
                print("❌ Background execution setup failed for \(serviceId): \(error)")
            } else {
                print("✅ Background execution enabled for \(serviceId): \(result ?? "success")")
            }
        }
    }
    
    /// 全WebViewでバックグラウンド実行を有効化
    func enableBackgroundExecutionForAll() {
        print("🔄 Enabling background execution for all WebViews...")
        
        // 組み込みサービス
        for service in AIService.allCases {
            enableBackgroundExecution(for: service.id)
        }
        
        // カスタムサービス
        for customService in customServiceManager.validServices {
            enableBackgroundExecution(for: customService.id.uuidString)
        }
    }
    
    /// WebViewの状態を定期的に保持する
    func maintainWebViewStates() {
        let maintainScript = """
        (function() {
            // 定期的にページの状態を維持
            setInterval(function() {
                // DOM要素の再確認
                const inputs = document.querySelectorAll('input, textarea, [contenteditable="true"]');
                inputs.forEach(input => {
                    if (input.offsetParent === null && input.style.display !== 'none') {
                        // 非表示になった要素を再表示
                        input.style.display = '';
                    }
                });
                
                // ネットワーク接続の維持
                if (navigator.onLine === false) {
                    // オフライン状態を強制的にオンラインに
                    Object.defineProperty(navigator, 'onLine', {
                        value: true,
                        writable: false
                    });
                }
            }, 5000); // 5秒間隔
            
            return 'State maintenance enabled';
        })();
        """
        
        for webView in webViews.values {
            webView.evaluateJavaScript(maintainScript) { _, error in
                if let error = error {
                    print("⚠️ State maintenance setup failed: \(error)")
                }
            }
        }
    }
    
    /// 強制的に全WebViewを事前読み込み
    func preloadAllServices() {
        print("🔄 Preloading all AI services...")
        
        // Built-in services
        for service in AIService.allCases {
            if let webView = webViews[service.id] {
                // ページを再読み込みして確実に初期化
                print("🔄 Reloading \(service.displayName)")
                webView.reload()
                
                // レンダリングサイクルを強制実行
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.forceWebViewActivation(webView, serviceId: service.id)
                }
            }
        }
        
        // Custom services
        for customService in customServiceManager.validServices {
            let serviceId = customService.id.uuidString
            if let webView = webViews[serviceId] {
                print("🔄 Reloading custom service: \(customService.name)")
                webView.reload()
                
                // レンダリングサイクルを強制実行
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.forceWebViewActivation(webView, serviceId: serviceId)
                }
            }
        }
    }
    
    /// WebViewの強制アクティベーション（DOM完成を確実にする）
    private func forceWebViewActivation(_ webView: WKWebView, serviceId: String) {
        // 1. レンダリングサイクル強制実行
        webView.needsLayout = true
        webView.layoutSubtreeIfNeeded()
        
        // 2. JavaScript実行環境の確認
        let domReadyScript = """
        (function() {
            console.log('🔍 DOM Ready Check for \(serviceId)');
            
            // DOM状態の確認
            const readyState = document.readyState;
            console.log('Document ready state:', readyState);
            
            // 基本要素の存在確認
            const body = document.body;
            const hasBody = !!body;
            console.log('Body element exists:', hasBody);
            
            if (hasBody) {
                const elementCount = document.querySelectorAll('*').length;
                console.log('Total elements in DOM:', elementCount);
            }
            
            // サービス固有の要素チェック
            if (window.location.href.includes('claude.ai')) {
                const inputs = document.querySelectorAll('[contenteditable="true"], textarea, input[type="text"]');
                console.log('Claude input elements found:', inputs.length);
                inputs.forEach((input, i) => {
                    console.log('Input', i, ':', {
                        tag: input.tagName,
                        contentEditable: input.contentEditable,
                        visible: input.offsetParent !== null
                    });
                });
            }
            
            return {
                readyState: readyState,
                hasBody: hasBody,
                elementCount: hasBody ? document.querySelectorAll('*').length : 0,
                timestamp: Date.now()
            };
        })();
        """
        
        webView.evaluateJavaScript(domReadyScript) { result, error in
            if let error = error {
                print("❌ DOM ready check failed for \(serviceId): \(error)")
            } else if let result = result {
                print("✅ DOM ready check completed for \(serviceId): \(result)")
            }
        }
        
        // 3. 追加のJavaScript環境準備（Claude専用）
        if serviceId == "claude" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.prepareClaudeSpecificEnvironment(webView)
            }
        }
    }
    
    /// Claude.ai専用の環境準備
    private func prepareClaudeSpecificEnvironment(_ webView: WKWebView) {
        let claudePreparationScript = """
        (function() {
            console.log('🎯 Preparing Claude environment...');
            
            // 入力要素の強制検索と準備
            function prepareInputElements() {
                const selectors = [
                    'div[contenteditable="true"][role="textbox"]',
                    'div[contenteditable="true"]',
                    '[role="textbox"][contenteditable="true"]',
                    '[contenteditable="true"][data-lexical-editor="true"]',
                    '.ProseMirror',
                    '.ProseMirror[contenteditable="true"]'
                ];
                
                let preparedCount = 0;
                
                selectors.forEach(selector => {
                    const elements = document.querySelectorAll(selector);
                    elements.forEach(element => {
                        // フォーカス可能にする
                        if (!element.tabIndex) element.tabIndex = 0;
                        
                        // イベントリスナーの準備
                        ['focus', 'blur', 'input', 'change'].forEach(eventType => {
                            element.dispatchEvent(new Event(eventType, { bubbles: true }));
                        });
                        
                        preparedCount++;
                        console.log('📝 Prepared input element:', selector, element);
                    });
                });
                
                console.log('✅ Prepared', preparedCount, 'input elements for Claude');
                return preparedCount;
            }
            
            // 送信ボタンの準備
            function prepareSubmitButtons() {
                const buttonSelectors = [
                    'button[aria-label*="Send Message"]',
                    'button[aria-label*="Send message"]',
                    '[data-testid="send-button"]',
                    'button[type="submit"][aria-label*="Send"]',
                    'button[class*="inline-flex"]:has(svg)',
                    'form button:has(svg[class*="lucide"])'
                ];
                
                let preparedCount = 0;
                
                buttonSelectors.forEach(selector => {
                    const buttons = document.querySelectorAll(selector);
                    buttons.forEach(button => {
                        // ボタンの可視性確保
                        if (button.style.display === 'none') {
                            button.style.display = '';
                        }
                        
                        preparedCount++;
                        console.log('🔘 Prepared submit button:', selector, button);
                    });
                });
                
                console.log('✅ Prepared', preparedCount, 'submit buttons for Claude');
                return preparedCount;
            }
            
            // 実行
            const inputCount = prepareInputElements();
            const buttonCount = prepareSubmitButtons();
            
            console.log('🎯 Claude environment preparation complete');
            
            return {
                inputElementsPrepared: inputCount,
                submitButtonsPrepared: buttonCount,
                timestamp: Date.now()
            };
        })();
        """
        
        webView.evaluateJavaScript(claudePreparationScript) { result, error in
            if let error = error {
                print("❌ Claude preparation failed: \(error)")
            } else if let result = result {
                print("✅ Claude environment prepared: \(result)")
            }
        }
    }
}

// MARK: - WebView Navigation Delegate
class WebViewNavigationDelegate: NSObject, WKNavigationDelegate {
    let serviceId: String
    let onLoadingStateChanged: (String, Bool) -> Void
    
    init(serviceId: String, onLoadingStateChanged: @escaping (String, Bool) -> Void) {
        self.serviceId = serviceId
        self.onLoadingStateChanged = onLoadingStateChanged
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        onLoadingStateChanged(serviceId, true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // ページ読み込み完了後、少し待ってからDOMが安定するのを待つ
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.onLoadingStateChanged(self.serviceId, false)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("❌ WebView navigation failed for \(serviceId): \(error)")
        onLoadingStateChanged(serviceId, false) // エラーでも読み込み完了として扱う
    }
}
