import Foundation
import WebKit

class AIFormAutofill {
    
    // 各AIサービスのフォームセレクター定義
    private static let formSelectors: [String: FormSelector] = [
        "chatgpt.com": FormSelector(
            inputSelector: "#prompt-textarea, [data-testid='prompt-textarea'], textarea[placeholder*='Message']",
            submitSelector: "button[data-testid='send-button'], button[aria-label='Send prompt']",
            waitForLoad: true
        ),
        "gemini.google.com": FormSelector(
            inputSelector: ".ql-editor, [data-test-id='input-area'], textarea[aria-label*='prompt']",
            submitSelector: "button[aria-label='Send message'], [data-test-id='send-button']",
            waitForLoad: true
        ),
        "claude.ai": FormSelector(
            inputSelector: "[contenteditable='true'], div[role='textbox'], textarea[placeholder*='Talk to Claude']",
            submitSelector: "button[aria-label='Send Message'], button[data-testid='send-button']",
            waitForLoad: true
        )
    ]
    
    struct FormSelector {
        let inputSelector: String
        let submitSelector: String
        let waitForLoad: Bool
    }
    
    static func autofillForm(webView: WKWebView, text: String, completion: @escaping (Bool) -> Void) {
        guard let url = webView.url,
              let host = url.host else {
            completion(false)
            return
        }
        
        // ホスト名からサービスを特定
        let serviceName = identifyService(from: host)
        guard let formSelector = formSelectors[serviceName] else {
            print("❌ Unsupported service: \(host)")
            completion(false)
            return
        }
        
        print("✅ Auto-filling form for: \(serviceName)")
        
        // JavaScriptコードを生成
        let jsCode = generateJavaScript(
            text: text,
            inputSelector: formSelector.inputSelector,
            submitSelector: formSelector.submitSelector
        )
        
        // フォーム読み込み待機とオートフィル実行
        if formSelector.waitForLoad {
            waitForFormLoad(webView: webView, jsCode: jsCode, completion: completion)
        } else {
            executeAutofill(webView: webView, jsCode: jsCode, completion: completion)
        }
    }
    
    private static func identifyService(from host: String) -> String {
        if host.contains("chatgpt.com") || host.contains("openai.com") {
            return "chatgpt.com"
        } else if host.contains("gemini.google.com") || host.contains("bard.google.com") {
            return "gemini.google.com"
        } else if host.contains("claude.ai") || host.contains("anthropic.com") {
            return "claude.ai"
        }
        return host
    }
    
    private static func generateJavaScript(text: String, inputSelector: String, submitSelector: String) -> String {
        let escapedText = text.replacingOccurrences(of: "'", with: "\\'")
                             .replacingOccurrences(of: "\n", with: "\\n")
                             .replacingOccurrences(of: "\r", with: "\\r")
        
        return """
        (function() {
            console.log('🤖 Prism Auto-fill starting...');
            
            // フォーム要素を見つける関数
            function findElement(selectors) {
                const selectorList = selectors.split(', ');
                for (let selector of selectorList) {
                    const elements = document.querySelectorAll(selector.trim());
                    if (elements.length > 0) {
                        // 表示されている要素を優先
                        for (let element of elements) {
                            if (element.offsetParent !== null) {
                                return element;
                            }
                        }
                        return elements[0]; // フォールバック
                    }
                }
                return null;
            }
            
            // テキスト入力を実行する関数
            function fillText(element, text) {
                if (element.contentEditable === 'true') {
                    // ContentEditable要素の場合
                    element.innerHTML = text;
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                } else if (element.tagName === 'TEXTAREA' || element.tagName === 'INPUT') {
                    // テキストエリア・入力フィールドの場合
                    element.value = text;
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                    element.dispatchEvent(new Event('change', { bubbles: true }));
                } else {
                    // その他の場合（divなど）
                    element.textContent = text;
                    element.dispatchEvent(new Event('input', { bubbles: true }));
                }
                
                // フォーカスを設定
                element.focus();
            }
            
            // メイン処理
            const inputElement = findElement('\(inputSelector)');
            if (inputElement) {
                console.log('✅ Input element found:', inputElement);
                fillText(inputElement, '\(escapedText)');
                
                // 送信ボタンを探してトリガー（オプション）
                setTimeout(() => {
                    const submitButton = findElement('\(submitSelector)');
                    if (submitButton && submitButton.disabled !== true) {
                        console.log('✅ Submit button found:', submitButton);
                        // 自動送信はしない（ユーザーが確認できるように）
                        // submitButton.click();
                    }
                }, 500);
                
                return true;
            } else {
                console.log('❌ Input element not found');
                return false;
            }
        })();
        """
    }
    
    private static func waitForFormLoad(webView: WKWebView, jsCode: String, completion: @escaping (Bool) -> Void) {
        // ページが完全に読み込まれるまで待機
        let checkLoadJS = """
        document.readyState === 'complete' && 
        (document.querySelector('\(formSelectors.values.first?.inputSelector ?? "")') !== null)
        """
        
        func checkAndExecute(attempt: Int = 0) {
            webView.evaluateJavaScript(checkLoadJS) { result, error in
                if let isReady = result as? Bool, isReady {
                    executeAutofill(webView: webView, jsCode: jsCode, completion: completion)
                } else if attempt < 10 { // 最大10回試行（5秒間）
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkAndExecute(attempt: attempt + 1)
                    }
                } else {
                    print("⚠️ Form load timeout, attempting autofill anyway")
                    executeAutofill(webView: webView, jsCode: jsCode, completion: completion)
                }
            }
        }
        
        checkAndExecute()
    }
    
    private static func executeAutofill(webView: WKWebView, jsCode: String, completion: @escaping (Bool) -> Void) {
        webView.evaluateJavaScript(jsCode) { result, error in
            if let error = error {
                print("❌ Autofill JavaScript error: \(error)")
                completion(false)
            } else if let success = result as? Bool {
                print(success ? "✅ Autofill successful" : "❌ Autofill failed")
                completion(success)
            } else {
                print("⚠️ Autofill completed with unknown result")
                completion(true) // デフォルトで成功とみなす
            }
        }
    }
}