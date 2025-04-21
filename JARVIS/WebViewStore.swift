import WebKit
import Combine

/// 各サービスごとの WKWebView をキャッシュ
class WebViewStore: ObservableObject {
    @Published var webViews: [AIService: WKWebView] = [:]

    init() {
        for service in AIService.allCases {
            let config = WKWebViewConfiguration()
            let wv = WKWebView(frame: .zero, configuration: config)
            wv.load(URLRequest(url: service.url))
            webViews[service] = wv
        }
    }
}
