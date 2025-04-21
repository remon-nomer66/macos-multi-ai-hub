import SwiftUI
import Vision
import AppKit
import UniformTypeIdentifiers  // for UTType

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore
    @StateObject private var store = WebViewStore()
    @State private var currentService: AIService = .chatGPT
    @State private var nativePrompt: String = ""
    @State private var showingSettings = false
    
    // ここを追加：キャプチャされた画像を保持
    @State private var capturedImage: NSImage?

    var body: some View {
        VStack(spacing: 8) {
            // ── ツールバー ──
            HStack(spacing: 12) {
                Button { store.webViews[currentService]?.reload() } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("リロード")

                Menu {
                    Button("Settings")   { showingSettings = true }
                    Button("Donation")   { showingSettings = true }
                    Divider()
                    Button("Quit")       { NSApp.terminate(nil) }
                } label: {
                    Image(systemName: "gearshape")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("メニュー")
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.horizontal, 12)

            Divider()

            // ── サービス切替 ──
            ServiceSelectorView(selectedService: $currentService)
                .padding(.horizontal, 12)

            Divider()

            // ── WebView ──
            if let webView = store.webViews[currentService] {
                WebViewContainer(webView: webView)
                    .id(currentService)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            HStack(spacing: 12) {
                // OCR キャプチャ
                Button("OCR キャプチャ") {
                    performCapture { image, text in
                        self.capturedImage = nil  // 画像プレビューは隠さない
                        self.nativePrompt = text
                    }
                }
                .help("テキストをOCR")

                // 画像キャプチャ（ドラッグ＆ドロップ用）
                Button("画像キャプチャ") {
                    performCapture { image, _ in
                        self.capturedImage = image
                    }
                }
                .help("領域をキャプチャしてドラッグ可能に")
            }
            .padding(.horizontal, 12)

            // ── キャプチャプレビュー（ドラッグソース） ──
            if let img = capturedImage {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
                    .border(Color.gray, width: 1)
                    .onDrag {
                        // TIFF データをドラッグアイテムとして提供
                        let data = img.tiffRepresentation
                        return NSItemProvider(item: data as NSData?, typeIdentifier: UTType.tiff.identifier)
                    }
                    .padding(.horizontal, 12)
            }

            Divider()

            // ── プロンプト入力 ──
            PromptInputView(promptText: $nativePrompt)
                .padding(.horizontal, 12)
        }
        .padding(12)
        .frame(
            width:  settings.windowSize.size.width,
            height: settings.windowSize.size.height
        )
        .sheet(isPresented: $showingSettings) {
            SettingsView().environmentObject(settings)
        }
    }

    /// 領域キャプチャを呼び出し、画像とOCRテキストをクロージャで返す共通関数
    private func performCapture(completion: @escaping (NSImage, String) -> Void) {
        // ポップオーバーを閉じ
        if let d = NSApp.delegate as? AppDelegate {
            d.popover.performClose(nil)
        }
        // キャプチャしやすいようアプリを背面化
        NSApp.deactivate()

        // screencapture -i -c でクリップボードに画像を保存
        let pb = NSPasteboard.general; pb.clearContents()
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"]
        task.launch()
        task.waitUntilExit()

        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let items = NSPasteboard.general.readObjects(forClasses: [NSImage.self], options: nil),
                let img   = items.first as? NSImage,
                let cg    = img.cgImage(forProposedRect: nil, context: nil, hints: nil)
            else { return }

            // OCR も実行
            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
            let req = VNRecognizeTextRequest { req, err in
                let text: String
                if let err = err {
                    print("OCR Error:", err)
                    text = ""
                } else if let obs = req.results as? [VNRecognizedTextObservation] {
                    text = obs.compactMap { $0.topCandidates(1).first?.string }
                              .joined(separator: "\n")
                } else {
                    text = ""
                }

                DispatchQueue.main.async {
                    // OCR テキストとキャプチャ画像を返す
                    completion(img, text)

                    // キャプチャのあと再度メニューバーに戻す
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
}
