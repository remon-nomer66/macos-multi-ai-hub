import SwiftUI
import WebKit

struct WebViewContainer: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView.uiDelegate = context.coordinator
        
        // バックグラウンドでの動作を維持するための設定
        webView.configuration.suppressesIncrementalRendering = false
        
        // メモリ管理とパフォーマンスの最適化
        webView.configuration.preferences.minimumFontSize = 0
        
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 状態を保持するためロードは行わない
        // ただし、WebViewが非表示になっても動作を継続するよう設定
        nsView.isHidden = false
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, WKUIDelegate {
        func webView(_ webView: WKWebView,
                     runOpenPanelWith parameters: WKOpenPanelParameters,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping ([URL]?) -> Void) {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = parameters.allowsMultipleSelection
            panel.begin { resp in
                completionHandler(resp == .OK ? panel.urls : nil)
            }
        }
    }
}
