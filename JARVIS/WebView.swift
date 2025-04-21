import SwiftUI
import WebKit

struct WebView: NSViewRepresentable {
    let url: URL?
    var onWebViewCreated: (WKWebView) -> Void

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = context.coordinator
        if let u = url {
            webView.load(URLRequest(url: u))
        }
        // 非同期で参照を保持
        DispatchQueue.main.async {
            onWebViewCreated(webView)
        }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if let u = url, nsView.url != u {
            nsView.load(URLRequest(url: u))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKUIDelegate {
        var parent: WebView
        init(_ parent: WebView) { self.parent = parent }

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
