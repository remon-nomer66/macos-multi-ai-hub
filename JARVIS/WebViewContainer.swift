import SwiftUI
import WebKit

struct WebViewContainer: NSViewRepresentable {
    let webView: WKWebView

    func makeNSView(context: Context) -> WKWebView {
        webView.uiDelegate = context.coordinator
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        // 状態を保持するためロードは行わない
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
