import SwiftUI
import Vision
import AppKit
import WebKit
import UniformTypeIdentifiers  // for UTType

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var customServiceManager = CustomAIServiceManager()
    @StateObject private var store: WebViewStore
    @StateObject private var serviceProvider: AIServiceProvider
    @State private var currentService: ExtendedAIService
    @State private var nativePrompt: String = ""
    @State private var showingSettings = false
    @State private var capturedImages: [NSImage] = []
    
    init() {
        let customManager = CustomAIServiceManager()
        let webStore = WebViewStore(customServiceManager: customManager)
        let provider = AIServiceProvider(customServiceManager: customManager)
        
        self._customServiceManager = StateObject(wrappedValue: customManager)
        self._store = StateObject(wrappedValue: webStore)
        self._serviceProvider = StateObject(wrappedValue: provider)
        self._currentService = State(initialValue: ExtendedAIService(builtIn: .chatGPT))
    }

    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
        .frame(
            width:  settings.currentWindowSize.width,
            height: settings.currentWindowSize.height
        )
        .onAppear(perform: setupOnAppear)
        .onChange(of: settings.webViewZoomScale) { _, newScale in
            handleZoomScaleChange(newScale)
        }
        .onChange(of: serviceProvider.availableServices) { _, newServices in
            handleAvailableServicesChange(newServices)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(customServiceManager)
        }
    }
    
    // MARK: - Background Component
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(NSColor.controlBackgroundColor).opacity(0.1),
                Color(NSColor.controlBackgroundColor).opacity(0.05)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Main Content Component
    private var mainContent: some View {
        VStack(spacing: 16) {
            toolbarSection
            serviceSelector  
            webViewContainer
            captureButtonsSection
            capturedImagesPreview
            promptInputSection
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
    
    // MARK: - Toolbar Section
    private var toolbarSection: some View {
        HStack {
                    HStack(spacing: 8) {
                        Button {
                            store.webViews[currentService.id]?.goBack()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(.regularMaterial, in: .circle)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .help("戻る")
                        
                        Button {
                            store.webViews[currentService.id]?.goForward()
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(.regularMaterial, in: .circle)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .help("進む")
                        
                        Button {
                            store.webViews[currentService.id]?.reload()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(.regularMaterial, in: .circle)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .help("リロード")
                        
                        Button {
                            if let webView = store.webViews[currentService.id] {
                                let request = URLRequest(url: currentService.url)
                                webView.load(request)
                            }
                        } label: {
                            Image(systemName: "house")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(.regularMaterial, in: .circle)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .help("ホーム")
                        
                        Button {
                            showingSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.primary)
                                .frame(width: 36, height: 36)
                                .background(.regularMaterial, in: .circle)
                                .contentShape(.circle)
                        }
                        .buttonStyle(.plain)
                        .help("設定")
                    }
                    
                    Spacer()
                    
                    Menu {
                        Button("Quit") { NSApp.terminate(nil) }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)
                            .frame(width: 36, height: 36)
                            .background(.regularMaterial, in: .circle)
                            .contentShape(.circle)
                    }
                    .buttonStyle(.plain)
                    .help("その他")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
    }
    
    // MARK: - Service Selector Section
    private var serviceSelector: some View {
        ExtendedServiceSelectorView(
            availableServices: serviceProvider.availableServices,
            selectedService: $currentService
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, 12)
    }
    
    // MARK: - WebView Container Section
    private var webViewContainer: some View {
        Group {
            if let webView = store.webViews[currentService.id] {
                WebViewContainer(webView: webView)
                        .id(currentService.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .strokeBorder(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.1)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                .padding(.horizontal, 12)
            }
        }
    }
    
    // MARK: - Capture Buttons Section
    private var captureButtonsSection: some View {
        HStack(spacing: 20) {
                    Button(action: {
                        performCapture { image, text in
                            self.nativePrompt = text
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "doc.viewfinder")
                                .font(.system(size: 18, weight: .medium))
                            Text("OCR")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.primary)
                        .frame(width: 60, height: 50)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .help("テキストをOCR")

                    Button(action: {
                        performCapture { image, _ in
                            self.capturedImages.append(image)
                        }
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "photo.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                            Text("画像")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(.primary)
                        .frame(width: 60, height: 50)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                    .help("画像キャプチャ")
                    
                    // ── Parallel Mode Toggle ──
                    Button(action: {
                        settings.parallelMode.toggle()
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: settings.parallelMode ? "arrow.triangle.branch" : "arrow.right")
                                .font(.system(size: 18, weight: .medium))
                            Text("Parallel")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(settings.parallelMode ? .white : .primary)
                        .frame(width: 60, height: 50)
                        .background {
                            if settings.parallelMode {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.blue,
                                        Color.blue.opacity(0.8)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color.clear
                            }
                        }
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .shadow(
                        color: settings.parallelMode ? .blue.opacity(0.3) : .black.opacity(0.1), 
                        radius: 3, 
                        x: 0, 
                        y: 2
                    )
                    .help("Parallelモード: 全AIサービスに同時送信")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .padding(.horizontal, 12)
    }
    
    // MARK: - Captured Images Preview Section
    private var capturedImagesPreview: some View {
        Group {
            if !capturedImages.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "photo.stack")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                                Text("キャプチャ画像")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("\(capturedImages.count) 枚")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.tertiary)
                        }
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(50), spacing: 8), count: 4), spacing: 8) {
                            // 画像サムネイル
                            ForEach(Array(capturedImages.enumerated()), id: \.offset) { index, image in
                                ZStack {
                                    Image(nsImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(.thinMaterial)
                                                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)
                                        )
                                        .onDrag {
                                            // フルサイズの画像をドラッグ&ドロップ
                                            let data = image.tiffRepresentation
                                            return NSItemProvider(item: data as NSData?, typeIdentifier: UTType.png.identifier)
                                        }
                                }
                            }
                            
                            // ゴミ箱ボタン
                            if capturedImages.count < 4 {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        capturedImages.removeAll()
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.secondary)
                                        Text("クリア")
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.thinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        // 4個以上の場合は下段にゴミ箱ボタンを配置
                        if capturedImages.count >= 4 {
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        capturedImages.removeAll()
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundStyle(.secondary)
                                        Text("クリア")
                                            .font(.system(size: 8, weight: .medium))
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(width: 50, height: 50)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.thinMaterial)
                                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
                                    )
                                }
                                .buttonStyle(.plain)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    )
                .padding(.horizontal, 12)
            }
        }
    }
    
    // MARK: - Prompt Input Section  
    private var promptInputSection: some View {
        PromptInputView(
            promptText: $nativePrompt,
            onAutofill: {
                performAutofill()
            }
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .padding(.horizontal, 12)
    }
    
    // MARK: - Event Handlers
    private func setupOnAppear() {
        // WebViewStoreにSettingsStoreの参照を設定
        store.setSettingsStore(settings)
        
        // WebViewのズーム倍率を適用
        store.setZoomScaleForAll(settings.webViewZoomScale)
        
        // 全AIサービスを事前読み込み
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            store.preloadAllServices()
        }
        
        // Claude.aiを含む全WebViewを一度バックグラウンドで表示してDOM構築を強制
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            forceAllWebViewsRendering()
        }
        
        // バックグラウンド実行機能を有効化
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            store.enableBackgroundExecutionForAll()
            store.maintainWebViewStates()
        }
    }
    
    private func handleZoomScaleChange(_ newScale: Double) {
        // ズーム倍率変更時にWebViewに適用
        store.setZoomScaleForAll(newScale)
    }
    
    private func handleAvailableServicesChange(_ newServices: [ExtendedAIService]) {
        // サービスリストが変更された場合、現在選択されているサービスが存在するかチェック
        if !newServices.contains(where: { $0.id == currentService.id }) {
            // 削除されたサービスが選択されている場合、デフォルトサービスに切り替え
            if let firstService = newServices.first {
                print("🔄 Switching to default service: \(firstService.displayName) (deleted service: \(currentService.displayName))")
                currentService = firstService
            }
        }
    }

    /// 領域キャプチャ＋OCR の共通処理
    private func performCapture(completion: @escaping (NSImage, String) -> Void) {
        // ポップオーバーを閉じて背面化
        if let d = NSApp.delegate as? AppDelegate {
            d.popover.performClose(nil)
        }
        NSApp.deactivate()

        // クリップボードにキャプチャ
        let pb = NSPasteboard.general; pb.clearContents()
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c", "-t", "png"]  // png 形式でクリップ
        task.launch()
        task.waitUntilExit()

        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let items = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil),
                let img   = items.first as? NSImage,
                let cg    = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else { return }

            // OCR 処理
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            let req = VNRecognizeTextRequest { req, err in
                let text: String
                if let obs = req.results as? [VNRecognizedTextObservation], err == nil {
                    text = obs.compactMap { $0.topCandidates(1).first?.string }
                              .joined(separator: "\n")
                } else {
                    text = ""
                }
                DispatchQueue.main.async {
                    completion(img, text)
                    // 再度メニューバーに戻す
                    NSApp.activate(ignoringOtherApps: true)
                    if let btn = (NSApp.delegate as? AppDelegate)?.statusItem.button {
                        (NSApp.delegate as? AppDelegate)?.togglePopover(btn)
                    }
                }
            }
            req.revision             = VNRecognizeTextRequestRevision3
            req.recognitionLevel     = .accurate
            req.recognitionLanguages = ["ja-JP","en-US"]
            req.usesLanguageCorrection = true

            try? handler.perform([req])
        }
    }
    
    // MARK: - Auto-fill Function
    private func performAutofill() {
        guard !nativePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("⚠️ No text to autofill")
            return
        }
        
        if settings.parallelMode {
            // Parallelモード: 全サービスに送信
            performParallelAutofill()
        } else {
            // 通常モード: 現在のサービスのみに送信
            performSingleAutofill()
        }
    }
    
    // MARK: - Single Service Autofill
    private func performSingleAutofill() {
        guard let webView = store.webViews[currentService.id] else {
            print("❌ No WebView available for current service")
            return
        }
        
        // カスタムAIサービスの場合は対応していない旨を表示
        if currentService.isCustom {
            print("⚠️ Command+Enter autofill is not supported for custom AI services")
            
            // カスタムサービス用のアラート表示
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "自動入力未対応"
                alert.informativeText = "カスタムAIサービスではCommand+Enterによる自動入力には対応していません。手動でテキストを入力してください。"
                alert.addButton(withTitle: "OK")
                alert.alertStyle = .informational
                alert.runModal()
                
                // 失敗フィードバック
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            }
            return
        }
        
        print("🚀 Performing autofill for service: \(currentService.displayName)")
        print("📝 Text to fill: \(nativePrompt.prefix(50))...")
        
        // WebViewの準備完了を確認してからオートフィルを実行
        Task {
            let isReady = await store.waitForWebViewReady(serviceId: currentService.id)
            
            await MainActor.run {
                if isReady {
                    print("✅ WebView ready for \(currentService.displayName), starting autofill...")
                    AIFormAutofillV2.autofillForm(webView: webView, text: nativePrompt) { success in
                        DispatchQueue.main.async {
                            if success {
                                // 成功時の視覚的フィードバック
                                print("✅ Autofill completed successfully")
                                
                                // 成功時にテキストフィールドをクリア
                                self.nativePrompt = ""
                                
                                // フィードバック用のハプティック（可能であれば）
                                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                            } else {
                                print("❌ Autofill failed")
                                
                                // 失敗時のフィードバック
                                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                            }
                        }
                    }
                } else {
                    print("⚠️ WebView not ready for \(currentService.displayName), attempting autofill anyway...")
                    // タイムアウト時でも試行
                    AIFormAutofillV2.autofillForm(webView: webView, text: nativePrompt) { success in
                        DispatchQueue.main.async {
                            if success {
                                self.nativePrompt = ""
                                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                            } else {
                                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Sequential Autofill Function (Former Parallel)
    private func performParallelAutofill() {
        // 組み込みAIサービスのみを対象とする（カスタムサービスは除外）
        let builtInServices = serviceProvider.availableServices.filter { !$0.isCustom }
        
        guard !builtInServices.isEmpty else {
            print("⚠️ No supported services for sequential autofill")
            return
        }
        
        print("🔄 Performing sequential autofill for \(builtInServices.count) services")
        print("📝 Text to fill: \(nativePrompt.prefix(50))...")
        
        // 順次実行用の状態管理
        var completedServices = 0
        var successfulServices = 0
        let totalServices = builtInServices.count
        
        // 順次実行関数
        func executeNextService(index: Int) {
            guard index < builtInServices.count else {
                // 全サービス完了 - 元のサービスに戻す
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    restoreOriginalService()
                    handleParallelAutofillCompletion(successful: successfulServices, total: totalServices)
                }
                return
            }
            
            let service = builtInServices[index]
            guard let webView = store.webViews[service.id] else {
                print("⚠️ No WebView for service: \(service.displayName)")
                completedServices += 1
                
                // 0.5秒後に次のサービスへ
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    executeNextService(index: index + 1)
                }
                return
            }
            
            print("🚀 [\(index + 1)/\(totalServices)] Starting autofill for \(service.displayName)...")
            
            // サービスをアクティブに切り替え
            print("🔄 Switching to \(service.displayName) tab...")
            switchToService(service)
            
            // タブ切り替え後、少し待ってからWebView準備確認
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                Task {
                    let isReady = await store.waitForWebViewReady(serviceId: service.id, timeout: 10.0)
                    
                    await MainActor.run {
                        if isReady {
                            print("✅ \(service.displayName) WebView ready, starting autofill...")
                        } else {
                            print("⚠️ \(service.displayName) WebView timeout, attempting autofill anyway...")
                        }
                        
                        // WebViewを確実にアクティベート
                        activateWebViewForAutofill(webView, serviceName: service.displayName)
                        
                        // 少し待ってからオートフィル実行
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            AIFormAutofillV2.autofillForm(webView: webView, text: nativePrompt) { success in
                                DispatchQueue.main.async {
                                    completedServices += 1
                                    
                                    if success {
                                        successfulServices += 1
                                        print("✅ [\(index + 1)/\(totalServices)] \(service.displayName) autofill completed")
                                        
                                        // 送信成功後、バックグラウンド実行を確実に有効化
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            self.store.enableBackgroundExecution(for: service.id)
                                            self.preserveServiceStateAfterAutofill(service: service, webView: webView)
                                        }
                                    } else {
                                        print("❌ [\(index + 1)/\(totalServices)] \(service.displayName) autofill failed")
                                    }
                                    
                                    // 2秒待ってから次のサービスへ（バックグラウンド処理を考慮して延長）
                                    let delay = 2.0
                                    print("⏳ Waiting \(delay)s before next service...")
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                                        executeNextService(index: index + 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        // 最初のサービスから順次実行開始
        executeNextService(index: 0)
    }
    
    private func handleParallelAutofillCompletion(successful: Int, total: Int) {
        print("🎯 Sequential autofill completed: \(successful)/\(total) successful")
        
        if successful > 0 {
            // 1つでも成功した場合はテキストクリア
            self.nativePrompt = ""
            
            // 成功時のフィードバック
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            
            // 成功数に応じたメッセージ
            if successful == total {
                print("✅ All services completed successfully")
            } else {
                print("⚠️ \(successful) out of \(total) services completed successfully")
            }
        } else {
            // 全て失敗した場合
            print("❌ All parallel autofills failed")
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }
    
    // MARK: - Service Switching and WebView Activation
    
    /// サービスを切り替えて表示をアクティブにする
    private func switchToService(_ service: ExtendedAIService) {
        print("🔄 Switching to service: \(service.displayName)")
        currentService = service
    }
    
    /// 元のサービスに戻る
    private func restoreOriginalService() {
        // 特に何も変更する必要がない場合は、現在のサービスをそのままにする
        print("✅ Restored to service: \(currentService.displayName)")
    }
    
    /// WebViewをアクティブ化してオートフィル準備
    private func activateWebViewForAutofill(_ webView: WKWebView, serviceName: String) {
        print("🎯 Activating WebView for autofill: \(serviceName)")
        
        // WebViewにフォーカスを当てる
        webView.needsLayout = true
        webView.layoutSubtreeIfNeeded()
        
        // JavaScript環境のアクティベーション
        let activationScript = """
        (function() {
            console.log('🎯 Activating WebView for \(serviceName)...');
            
            // ページがアクティブ状態であることを確認
            if (document.visibilityState !== 'visible') {
                document.dispatchEvent(new Event('visibilitychange'));
            }
            
            // フォーカスイベントをトリガー
            window.dispatchEvent(new Event('focus'));
            document.dispatchEvent(new Event('focus'));
            
            // サービス固有のアクティベーション
            if (window.location.href.includes('claude.ai')) {
                // Claude.ai用の特別なアクティベーション
                const inputs = document.querySelectorAll('[contenteditable="true"][role="textbox"]');
                inputs.forEach(input => {
                    // 入力要素を一度フォーカス/ブラーしてReactの状態を更新
                    input.focus();
                    setTimeout(() => input.blur(), 10);
                    setTimeout(() => input.focus(), 20);
                });
                console.log('Claude inputs activated:', inputs.length);
            }
            
            return {
                service: '\(serviceName)',
                activated: true,
                timestamp: Date.now()
            };
        })();
        """
        
        webView.evaluateJavaScript(activationScript) { result, error in
            if let error = error {
                print("❌ WebView activation failed for \(serviceName): \(error)")
            } else if let result = result {
                print("✅ WebView activated for \(serviceName): \(result)")
            }
        }
    }
    
    // MARK: - Force WebView Rendering
    /// 全WebViewを一度バックグラウンドで強制レンダリングしてDOM構築を完了させる
    private func forceAllWebViewsRendering() {
        print("🎨 Forcing all WebViews rendering for DOM completion...")
        
        // 組み込みサービスの強制レンダリング
        for service in AIService.allCases {
            if let webView = store.webViews[service.id] {
                forceWebViewRendering(webView, serviceName: service.displayName)
            }
        }
        
        // カスタムサービスの強制レンダリング
        for customService in customServiceManager.validServices {
            let serviceId = customService.id.uuidString
            if let webView = store.webViews[serviceId] {
                forceWebViewRendering(webView, serviceName: customService.name)
            }
        }
    }
    
    /// 個別WebViewの強制レンダリング
    private func forceWebViewRendering(_ webView: WKWebView, serviceName: String) {
        print("🎨 Force rendering: \(serviceName)")
        
        // 1. WebViewを一時的に表示可能な状態にする
        let originalFrame = webView.frame
        let originalHidden = webView.isHidden
        
        // 隠し表示でレンダリング強制（1px x 1px）
        webView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
        webView.isHidden = false
        
        // 2. レンダリングサイクル強制実行
        webView.needsLayout = true
        webView.layoutSubtreeIfNeeded()
        
        // 3. 少し待ってから元のサイズに戻し、最終的なレンダリング
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            webView.frame = originalFrame
            webView.isHidden = originalHidden
            webView.needsLayout = true
            webView.layoutSubtreeIfNeeded()
            
            // 4. JavaScript環境の最終確認
            let finalCheckScript = """
            (function() {
                console.log('🔍 Final rendering check for \(serviceName)');
                
                // DOM完全性確認
                const isComplete = document.readyState === 'complete';
                const hasInteractiveElements = document.querySelectorAll('input, textarea, [contenteditable="true"], button').length > 0;
                
                console.log('Document complete:', isComplete);
                console.log('Has interactive elements:', hasInteractiveElements);
                
                return {
                    service: '\(serviceName)',
                    documentComplete: isComplete,
                    interactiveElements: hasInteractiveElements,
                    timestamp: Date.now()
                };
            })();
            """
            
            webView.evaluateJavaScript(finalCheckScript) { result, error in
                if let error = error {
                    print("❌ Final check failed for \(serviceName): \(error)")
                } else if let result = result {
                    print("✅ Final rendering check for \(serviceName): \(result)")
                }
            }
        }
    }
    
    // MARK: - Background State Preservation
    
    /// オートフィル後のサービス状態を保持する
    private func preserveServiceStateAfterAutofill(service: ExtendedAIService, webView: WKWebView) {
        print("🔒 Preserving state for \(service.displayName) after autofill...")
        
        let preservationScript = """
        (function() {
            console.log('🔒 Preserving AI service state after autofill...');
            
            // 回答生成中の状態を検知して維持
            function maintainGenerationState() {
                // ChatGPT特有の生成状態検知
                if (window.location.href.includes('chatgpt.com') || window.location.href.includes('openai.com')) {
                    const stopButton = document.querySelector('[data-testid="stop-button"], button[aria-label*="Stop"]');
                    if (stopButton && !stopButton.disabled) {
                        console.log('🤖 ChatGPT is generating response, maintaining active state...');
                        return true;
                    }
                }
                
                // Gemini特有の生成状態検知
                if (window.location.href.includes('gemini.google.com')) {
                    const stopButton = document.querySelector('button[aria-label*="Stop"], [data-test-id="stop-button"]');
                    const thinkingIndicator = document.querySelector('[data-test-id="thinking-indicator"], .typing-indicator');
                    if ((stopButton && !stopButton.disabled) || thinkingIndicator) {
                        console.log('🤖 Gemini is generating response, maintaining active state...');
                        return true;
                    }
                }
                
                // Claude特有の生成状態検知
                if (window.location.href.includes('claude.ai')) {
                    const stopButton = document.querySelector('button[aria-label*="Stop"]');
                    const thinkingElements = document.querySelectorAll('[data-testid*="loading"], .animate-pulse, .loading');
                    if ((stopButton && !stopButton.disabled) || thinkingElements.length > 0) {
                        console.log('🤖 Claude is generating response, maintaining active state...');
                        return true;
                    }
                }
                
                // 汎用的な生成状態検知
                const loadingElements = document.querySelectorAll('.loading, .spinner, .generating, [data-loading="true"]');
                const streamingText = document.querySelectorAll('.streaming, .typing, .animate-pulse');
                
                if (loadingElements.length > 0 || streamingText.length > 0) {
                    console.log('🤖 AI service is generating response, maintaining active state...');
                    return true;
                }
                
                return false;
            }
            
            // 生成状態を定期的にチェック
            const stateCheckInterval = setInterval(function() {
                if (maintainGenerationState()) {
                    // 生成中は一定間隔でページをアクティブに保つ
                    document.dispatchEvent(new Event('visibilitychange'));
                    window.dispatchEvent(new Event('focus'));
                    
                    // スクロール位置を微調整してページの活性を維持
                    const scrollTop = document.documentElement.scrollTop;
                    document.documentElement.scrollTop = scrollTop + 1;
                    setTimeout(() => {
                        document.documentElement.scrollTop = scrollTop;
                    }, 10);
                } else {
                    // 生成完了後は通常の監視間隔に戻す
                    clearInterval(stateCheckInterval);
                    console.log('✅ AI response generation completed, normal background execution resumed');
                }
            }, 1000); // 1秒間隔で生成状態をチェック
            
            // WebSocket接続の維持
            const originalWebSocketSend = WebSocket.prototype.send;
            WebSocket.prototype.send = function(data) {
                console.log('📡 WebSocket message sent:', data.substring(0, 100) + '...');
                return originalWebSocketSend.call(this, data);
            };
            
            // ページの可視性を強制的に維持
            const keepAliveInterval = setInterval(function() {
                // ページが非表示になった場合の対策
                if (document.visibilityState === 'hidden') {
                    console.log('👁️ Page became hidden, forcing visible state...');
                    
                    // 強制的にvisible状態に戻す
                    Object.defineProperty(document, 'visibilityState', {
                        value: 'visible',
                        writable: false
                    });
                    
                    Object.defineProperty(document, 'hidden', {
                        value: false,
                        writable: false
                    });
                }
                
                // ネットワーク接続の確認と維持
                if (!navigator.onLine) {
                    console.log('🌐 Network offline detected, forcing online state...');
                    Object.defineProperty(navigator, 'onLine', {
                        value: true,
                        writable: false
                    });
                }
                
            }, 3000); // 3秒間隔
            
            console.log('🔒 State preservation setup completed');
            
            return {
                statePreservationEnabled: true,
                service: '\(service.displayName)',
                timestamp: Date.now()
            };
        })();
        """
        
        webView.evaluateJavaScript(preservationScript) { result, error in
            if let error = error {
                print("❌ State preservation failed for \(service.displayName): \(error)")
            } else {
                print("✅ State preservation enabled for \(service.displayName): \(result ?? "success")")
            }
        }
    }
}
