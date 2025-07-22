import Foundation
import WebKit

class AIFormAutofillV2 {
    
    // MARK: - Service Configurations
    private static let serviceConfigs: [String: ServiceConfig] = [
        "chatgpt.com": ServiceConfig(
            name: "ChatGPT",
            selectors: ChatGPTSelectors(),
            strategy: .reactInput
        ),
        "gemini.google.com": ServiceConfig(
            name: "Gemini",
            selectors: GeminiSelectors(),
            strategy: .reactInput
        ),
        "claude.ai": ServiceConfig(
            name: "Claude",
            selectors: ClaudeSelectors(),
            strategy: .reactInput
        )
    ]
    
    // MARK: - Configuration Structures
    struct ServiceConfig {
        let name: String
        let selectors: SelectorSet
        let strategy: InputStrategy
    }
    
    enum InputStrategy {
        case reactInput      // React controlled input
        case contentEditable // ContentEditable div
        case textarea        // Standard textarea
    }
    
    protocol SelectorSet {
        var inputSelectors: [String] { get }
        var submitSelectors: [String] { get }
        var waitCondition: String? { get }
    }
    
    // MARK: - ChatGPT Selectors (2025年1月現在)
    struct ChatGPTSelectors: SelectorSet {
        var inputSelectors: [String] = [
            "#prompt-textarea",
            "[data-testid='prompt-textarea']",
            "[contenteditable='true'][data-testid*='prompt']",
            "textarea[placeholder*='Message']",
            "div[contenteditable='true'][role='textbox']",
            ".ProseMirror",
            "[data-id='root'] textarea",
            "div[contenteditable='true'][data-id*='prompt']"
        ]
        
        var submitSelectors: [String] = [
            "[data-testid='send-button']",
            "button[data-testid='send-button']",
            "button[aria-label*='Send message']",
            "button[aria-label*='Send']",
            "[data-testid='fruitjuice-send-button']",
            ".absolute.z-10 button",
            ".flex.h-8.w-8 button",
            "button[class*='rounded-lg'][class*='bg-black']",
            "button svg[width='16'][height='16']",
            "button:has(svg[data-icon='arrow-up'])",
            ".absolute.rounded-lg button",
            "form button[type='button']:not([disabled])"
        ]
        
        var waitCondition: String? = "document.querySelector('#prompt-textarea, [data-testid=\"prompt-textarea\"]')"
    }
    
    // MARK: - Gemini Selectors (2025年1月現在)
    struct GeminiSelectors: SelectorSet {
        var inputSelectors: [String] = [
            ".ql-editor",
            "[contenteditable='true'][aria-label*='prompt']",
            "[contenteditable='true'][role='textbox']",
            ".message-input",
            "rich-textarea .ql-editor",
            "[jsname*='input']",
            "div[contenteditable='true'][data-test-id='input-area']",
            "[contenteditable='true'][data-placeholder*='Enter a prompt']",
            ".ql-container .ql-editor"
        ]
        
        var submitSelectors: [String] = [
            "button[aria-label*='Send message']",
            "button[aria-label*='Send']",
            "[data-test-id='send-button']",
            "button[jsname*='send']",
            ".send-button",
            "button[type='submit']",
            "button[class*='send']",
            "button:has(svg[aria-hidden='true'])",
            "[role='button'][aria-label*='Send']",
            ".VfPpkd-LgbsSe button",
            "button[class*='VfPpkd-LgbsSe']",
            "div[role='button'][jsname*='send']"
        ]
        
        var waitCondition: String? = "document.querySelector('.ql-editor, [contenteditable=\"true\"][role=\"textbox\"]')"
    }
    
    // MARK: - Claude Selectors (2025年1月現在)
    struct ClaudeSelectors: SelectorSet {
        var inputSelectors: [String] = [
            // 2025年1月の最新Claude.ai構造を試行錯誤で特定
            "div[contenteditable='true'][role='textbox']",
            "div[contenteditable='true']",
            "[role='textbox'][contenteditable='true']",
            "[contenteditable='true'][data-lexical-editor='true']",
            ".ProseMirror",
            ".ProseMirror[contenteditable='true']",
            // より汎用的なセレクター
            "div[contenteditable='true']:not([aria-hidden='true'])",
            "[contenteditable='true']:not([readonly]):not([disabled]):not([aria-hidden='true'])",
            // 可視要素優先
            "div[contenteditable='true']:not([style*='display: none']):not([style*='visibility: hidden'])",
            // フォールバック用広範囲セレクター
            "[data-testid*='input']",
            "[data-testid*='chat']",
            "[role='textbox']",
            "textarea",
            "input[type='text']"
        ]
        
        var submitSelectors: [String] = [
            "button[aria-label*='Send Message']",
            "button[aria-label*='Send message']",
            "[data-testid='send-button']",
            "button[type='submit'][aria-label*='Send']",
            ".send-button",
            "button.inline-flex[type='submit']",
            "button[class*='inline-flex']:has(svg)",
            "form button:has(svg[class*='lucide'])",
            "button[class*='bg-accent']:not([disabled])",
            "button:has(svg[data-testid='send-icon'])",
            ".relative button:not([disabled])",
            "button[type='submit']:has(svg)"
        ]
        
        var waitCondition: String? = "document.querySelector('[contenteditable=\"true\"][role=\"textbox\"], .ProseMirror')"
    }
    
    // MARK: - Main Autofill Function
    static func autofillForm(webView: WKWebView, text: String, completion: @escaping (Bool) -> Void) {
        guard let url = webView.url,
              let host = url.host else {
            completion(false)
            return
        }
        
        let serviceName = identifyService(from: host)
        guard let config = serviceConfigs[serviceName] else {
            print("❌ Unsupported service: \(host)")
            completion(false)
            return
        }
        
        print("✅ Auto-filling form for: \(config.name)")
        
        // 段階的なアプローチ: 待機 → 検索 → 入力 → 検証
        waitForElement(webView: webView, config: config) { success in
            guard success else {
                completion(false)
                return
            }
            
            fillInput(webView: webView, config: config, text: text) { success in
                if success {
                    // 入力成功後、マイクボタン→送信ボタンの切り替えを待つ
                    print("⏳ Waiting 0.5s for microphone→send button transition...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        clickSubmitButton(webView: webView, config: config) { submitSuccess in
                            print(submitSuccess ? "✅ Submit button clicked" : "⚠️ Submit button not found or failed to click")
                            completion(success) // 入力の成功は保持
                        }
                    }
                } else {
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
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
    
    private static func waitForElement(webView: WKWebView, config: ServiceConfig, completion: @escaping (Bool) -> Void) {
        let waitScript = """
        (function() {
            const maxAttempts = 20;
            let attempts = 0;
            
            function checkElement() {
                attempts++;
                console.log('🔍 Attempt', attempts, 'looking for input element...');
                
                // Multiple selector strategy
                const selectors = \(jsonString(config.selectors.inputSelectors));
                
                for (let selector of selectors) {
                    const elements = document.querySelectorAll(selector);
                    for (let element of elements) {
                        if (element.offsetParent !== null || element.style.display !== 'none') {
                            console.log('✅ Found element:', selector, element);
                            return true;
                        }
                    }
                }
                
                if (attempts < maxAttempts) {
                    setTimeout(checkElement, 200);
                } else {
                    console.log('❌ Element not found after', maxAttempts, 'attempts');
                    return false;
                }
                
                return false;
            }
            
            return checkElement();
        })();
        """
        
        executeWithRetry(webView: webView, script: waitScript, maxRetries: 3) { result, error in
            if let error = error {
                print("❌ Wait script error: \(error)")
                completion(false)
            } else if let success = result as? Bool, success {
                completion(true)
            } else {
                // タイムアウト後でも試行
                print("⚠️ Wait timeout, attempting autofill anyway")
                completion(true)
            }
        }
    }
    
    private static func fillInput(webView: WKWebView, config: ServiceConfig, text: String, completion: @escaping (Bool) -> Void) {
        let escapedText = escapeJavaScriptString(text)
        
        let fillScript = """
        (function() {
            console.log('🚀 Starting autofill for \(config.name)...');
            
            const inputSelectors = \(jsonString(config.selectors.inputSelectors));
            const text = '\(escapedText)';
            
            // Find input element with detailed debugging
            function findInputElement() {
                console.log('🔍 Searching for input elements...');
                console.log('Available selectors:', inputSelectors);
                
                for (let selector of inputSelectors) {
                    console.log('🔍 Trying selector:', selector);
                    const elements = document.querySelectorAll(selector);
                    console.log('Found', elements.length, 'elements for selector:', selector);
                    
                    for (let i = 0; i < elements.length; i++) {
                        const element = elements[i];
                        const rect = element.getBoundingClientRect();
                        const style = window.getComputedStyle(element);
                        const isVisible = rect.width > 0 && rect.height > 0 && 
                                        element.offsetParent !== null &&
                                        style.visibility !== 'hidden' &&
                                        style.display !== 'none';
                        
                        console.log('Element', i, ':', {
                            tagName: element.tagName,
                            contentEditable: element.contentEditable,
                            role: element.getAttribute('role'),
                            dataLexical: element.getAttribute('data-lexical-editor'),
                            className: element.className,
                            id: element.id,
                            rect: { width: rect.width, height: rect.height },
                            visibility: style.visibility,
                            display: style.display,
                            offsetParent: !!element.offsetParent,
                            isVisible: isVisible
                        });
                        
                        if (isVisible) {
                            console.log('✅ Found visible input element:', selector, element);
                            return element;
                        }
                    }
                }
                console.log('❌ No visible input element found');
                return null;
            }
            
            // Input strategy based on element type
            function setInputValue(element, text) {
                const strategy = '\(config.strategy)';
                console.log('📝 Using strategy:', strategy);
                
                // Focus element first
                element.focus();
                element.click();
                
                // Wait a moment for focus
                setTimeout(() => {
                    try {
                        if (strategy === 'contentEditable' || element.contentEditable === 'true') {
                            // ContentEditable strategy
                            console.log('📝 ContentEditable strategy');
                            
                            // Focus element first
                            element.focus();
                            element.click();
                            
                            // Clear existing content
                            if (element.innerHTML) element.innerHTML = '';
                            if (element.textContent) element.textContent = '';
                            
                            // Strategy 1: execCommand insertText
                            if (document.execCommand('insertText', false, text)) {
                                console.log('✅ Text inserted via execCommand');
                            } else {
                                // Strategy 2: Direct content setting
                                element.innerHTML = text;
                                element.textContent = text;
                                console.log('✅ Text inserted via direct setting');
                            }
                            
                            // Dispatch events
                            element.dispatchEvent(new Event('focus', { bubbles: true }));
                            element.dispatchEvent(new Event('input', { bubbles: true }));
                            element.dispatchEvent(new Event('change', { bubbles: true }));
                            
                            // React-specific events
                            const reactEvents = ['input', 'change', 'blur'];
                            reactEvents.forEach(eventType => {
                                const event = new Event(eventType, { bubbles: true });
                                element.dispatchEvent(event);
                            });
                            
                        } else if (strategy === 'reactInput' || element.tagName === 'TEXTAREA' || element.tagName === 'INPUT') {
                            // React Input / Textarea strategy
                            console.log('📝 React Input strategy');
                            
                            // Clear and set value
                            element.value = text;
                            
                            // React-specific property setting
                            const descriptor = Object.getOwnPropertyDescriptor(element, 'value') ||
                                             Object.getOwnPropertyDescriptor(Object.getPrototypeOf(element), 'value');
                            if (descriptor && descriptor.set) {
                                descriptor.set.call(element, text);
                            }
                            
                            // Comprehensive event dispatch
                            const events = [
                                new Event('focus', { bubbles: true }),
                                new Event('input', { bubbles: true }),
                                new Event('change', { bubbles: true }),
                                new KeyboardEvent('keydown', { bubbles: true }),
                                new KeyboardEvent('keyup', { bubbles: true })
                            ];
                            
                            events.forEach(event => element.dispatchEvent(event));
                        }
                        
                        // Final verification
                        setTimeout(() => {
                            const currentValue = element.value || element.textContent || element.innerHTML;
                            console.log('🔍 Final value check:', currentValue.substring(0, 50));
                            
                            if (currentValue && currentValue.includes(text.substring(0, 10))) {
                                console.log('✅ Autofill successful');
                                return true;
                            } else {
                                console.log('❌ Autofill verification failed');
                                return false;
                            }
                        }, 100);
                        
                        return true;
                        
                    } catch (error) {
                        console.error('❌ Input strategy error:', error);
                        return false;
                    }
                }, 100);
                
                return true;
            }
            
            // Main execution
            const inputElement = findInputElement();
            if (inputElement) {
                return setInputValue(inputElement, text);
            } else {
                console.log('❌ No input element found');
                return false;
            }
        })();
        """
        
        executeWithRetry(webView: webView, script: fillScript, maxRetries: 2) { result, error in
            if let error = error {
                print("❌ Fill script error: \(error)")
                completion(false)
            } else if let success = result as? Bool {
                print(success ? "✅ Autofill completed" : "❌ Autofill failed")
                completion(success)
            } else {
                print("⚠️ Autofill completed with unknown result")
                completion(true) // デフォルトで成功とみなす
            }
        }
    }
    
    private static func clickSubmitButton(webView: WKWebView, config: ServiceConfig, completion: @escaping (Bool) -> Void) {
        let clickScript = """
        (function() {
            console.log('🖱️ Looking for submit button for \(config.name)...');
            
            const submitSelectors = \(jsonString(config.selectors.submitSelectors));
            
            // Advanced button finder with multiple strategies
            function findSubmitButton() {
                let foundButton = null;
                let candidateButtons = [];
                
                // Strategy 1: Use provided selectors with strict validation
                for (let selector of submitSelectors) {
                    try {
                        const elements = document.querySelectorAll(selector);
                        for (let element of elements) {
                            if (isValidButton(element) && isLikelySubmitButton(element)) {
                                console.log('✅ Found button via selector:', selector, element);
                                return element; // Return immediately for exact matches
                            } else if (isValidButton(element)) {
                                candidateButtons.push({element, source: 'selector', selector});
                            }
                        }
                    } catch (e) {
                        console.log('Selector failed:', selector, e);
                    }
                }
                
                // Strategy 2: Look for buttons near input areas with strict filtering
                const inputAreas = document.querySelectorAll('[contenteditable="true"], textarea, input[type="text"]');
                for (let input of inputAreas) {
                    const nearbyButtons = findNearbyButtons(input);
                    for (let btn of nearbyButtons) {
                        if (isValidButton(btn) && isLikelySubmitButton(btn)) {
                            console.log('✅ Found nearby button:', btn);
                            return btn; // Return immediately for good matches
                        } else if (isValidButton(btn)) {
                            candidateButtons.push({element: btn, source: 'nearby', input});
                        }
                    }
                }
                
                // Strategy 3: Final fallback with very strict criteria
                const allButtons = document.querySelectorAll('button, [role="button"]');
                let bestCandidate = null;
                let highestScore = 0;
                
                for (let btn of allButtons) {
                    if (isValidButton(btn)) {
                        const score = calculateButtonScore(btn);
                        if (score > 0 && score > highestScore) {
                            bestCandidate = btn;
                            highestScore = score;
                        }
                    }
                }
                
                if (bestCandidate && highestScore >= 3) {
                    console.log('✅ Found button by scoring:', bestCandidate, 'score:', highestScore);
                    return bestCandidate;
                }
                
                console.log('No suitable button found. Candidates:', candidateButtons.length);
                return null;
            }
            
            // Scoring function for buttons (higher score = more likely to be submit)
            function calculateButtonScore(button) {
                let score = 0;
                const text = button.textContent?.toLowerCase() || '';
                const ariaLabel = button.getAttribute('aria-label')?.toLowerCase() || '';
                const dataTestId = button.getAttribute('data-testid')?.toLowerCase() || '';
                const className = button.className?.toLowerCase() || '';
                
                // High score for exact matches
                if (dataTestId.includes('send-button') || dataTestId === 'send') score += 5;
                if (ariaLabel.includes('send message') || ariaLabel === 'send') score += 5;
                if (text === 'send' || text === '送信') score += 4;
                
                // Medium score for partial matches
                if (text.includes('send') || ariaLabel.includes('send')) score += 2;
                if (className.includes('send') || className.includes('submit')) score += 1;
                
                // Bonus for being near input
                if (isNearInputArea(button)) score += 1;
                
                // Penalty for wrong buttons
                const badKeywords = ['menu', 'profile', 'settings', 'cancel', 'close'];
                if (badKeywords.some(keyword => text.includes(keyword) || ariaLabel.includes(keyword))) {
                    score -= 5;
                }
                
                return score;
            }
            
            function isValidButton(element) {
                if (!element) return false;
                
                // Check visibility
                const rect = element.getBoundingClientRect();
                const isVisible = rect.width > 0 && rect.height > 0 && 
                                element.offsetParent !== null &&
                                window.getComputedStyle(element).visibility !== 'hidden' &&
                                window.getComputedStyle(element).display !== 'none';
                
                // Check if enabled
                const isEnabled = !element.disabled && 
                                !element.hasAttribute('disabled') &&
                                !element.classList.contains('disabled') &&
                                window.getComputedStyle(element).pointerEvents !== 'none';
                
                return isVisible && isEnabled;
            }
            
            function findNearbyButtons(inputElement) {
                const buttons = [];
                let parent = inputElement.parentElement;
                
                // Search up to 5 levels up
                for (let i = 0; i < 5 && parent; i++) {
                    const foundButtons = parent.querySelectorAll('button, [role="button"]');
                    buttons.push(...foundButtons);
                    parent = parent.parentElement;
                }
                
                return buttons;
            }
            
            function isLikelySubmitButton(button) {
                const text = button.textContent?.toLowerCase() || '';
                const ariaLabel = button.getAttribute('aria-label')?.toLowerCase() || '';
                const title = button.getAttribute('title')?.toLowerCase() || '';
                const className = button.className?.toLowerCase() || '';
                const id = button.getAttribute('id')?.toLowerCase() || '';
                const dataTestId = button.getAttribute('data-testid')?.toLowerCase() || '';
                
                // Site-specific detection based on current service
                const serviceName = '\(config.name)';
                
                if (serviceName === 'ChatGPT') {
                    // ChatGPT specific checks
                    if (dataTestId.includes('send')) return true;
                    if (ariaLabel.includes('send message') || ariaLabel.includes('send')) return true;
                    if (button.querySelector('svg[width="16"][height="16"]')) return true;
                    
                    // Exclude microphone button specifically
                    if (ariaLabel.includes('microphone') || ariaLabel.includes('voice') || ariaLabel.includes('mic')) return false;
                    if (button.querySelector('svg[data-icon*="microphone"]') || button.querySelector('svg[class*="microphone"]')) return false;
                    
                    // ChatGPT send button is usually in the bottom right of input area
                    const inputArea = document.querySelector('#prompt-textarea, [data-testid="prompt-textarea"]');
                    if (inputArea && isNearElement(button, inputArea, 100)) {
                        const rect = button.getBoundingClientRect();
                        if (rect.width <= 60 && rect.height <= 60) return true;
                    }
                }
                
                if (serviceName === 'Gemini') {
                    // Gemini specific checks
                    if (ariaLabel.includes('send') || text.includes('send')) return true;
                    if (button.classList.contains('VfPpkd-LgbsSe')) return true;
                    
                    // Exclude microphone button specifically
                    if (ariaLabel.includes('microphone') || ariaLabel.includes('voice') || ariaLabel.includes('mic')) return false;
                    if (button.querySelector('svg[data-icon*="mic"]') || button.querySelector('svg[class*="mic"]')) return false;
                    
                    if (button.querySelector('svg[aria-hidden="true"]')) {
                        const rect = button.getBoundingClientRect();
                        if (rect.width <= 50 && rect.height <= 50) return true;
                    }
                }
                
                if (serviceName === 'Claude') {
                    // Claude specific checks
                    if (ariaLabel.includes('send message') || ariaLabel.includes('send')) return true;
                    if (dataTestId.includes('send')) return true;
                    if (button.classList.contains('bg-accent') || className.includes('bg-accent')) return true;
                    if (button.querySelector('svg[class*="lucide"]')) return true;
                    // Claude send button is in the form with the input
                    const form = button.closest('form');
                    const inputInForm = form && form.querySelector('[contenteditable="true"]');
                    if (inputInForm) return true;
                }
                
                // Exclude common non-submit buttons
                const excludeKeywords = [
                    'cancel', 'close', 'back', 'menu', 'settings', 'profile', 
                    'login', 'signup', 'share', 'copy', 'edit', 'delete',
                    'like', 'dislike', 'thumb', 'star', 'bookmark',
                    'microphone', 'mic', 'voice', 'record', 'audio',
                    'キャンセル', '閉じる', '戻る', 'メニュー', '設定', 'ログイン'
                ];
                
                const hasExcludeKeyword = excludeKeywords.some(keyword =>
                    text.includes(keyword) || ariaLabel.includes(keyword) ||
                    title.includes(keyword) || className.includes(keyword)
                );
                
                if (hasExcludeKeyword) return false;
                
                // Generic fallback checks (more strict)
                const submitKeywords = ['send', 'submit', '送信'];
                const hasStrictSubmitKeyword = submitKeywords.some(keyword => 
                    text.includes(keyword) || ariaLabel.includes(keyword)
                );
                
                // Only allow SVG buttons if they're very small and near input
                const hasSvg = button.querySelector('svg') !== null;
                const rect = button.getBoundingClientRect();
                const isVerySmallButton = rect.width <= 40 && rect.height <= 40;
                
                return hasStrictSubmitKeyword || (hasSvg && isVerySmallButton && isNearInputArea(button));
            }
            
            // Helper function to check if button is near an element
            function isNearElement(button, element, maxDistance) {
                const buttonRect = button.getBoundingClientRect();
                const elementRect = element.getBoundingClientRect();
                
                const distance = Math.sqrt(
                    Math.pow(buttonRect.left - elementRect.right, 2) +
                    Math.pow(buttonRect.top - elementRect.top, 2)
                );
                
                return distance <= maxDistance;
            }
            
            // Helper function to check if button is near any input area
            function isNearInputArea(button) {
                const inputAreas = document.querySelectorAll(
                    '[contenteditable="true"], textarea, input[type="text"]'
                );
                
                for (let input of inputAreas) {
                    if (isNearElement(button, input, 150)) {
                        return true;
                    }
                }
                return false;
            }
            
            // Enhanced click function
            function clickButton(button) {
                try {
                    console.log('🎯 Attempting to click button:', button);
                    
                    // Scroll button into view
                    button.scrollIntoView({ behavior: 'instant', block: 'center' });
                    
                    // Focus the button
                    button.focus();
                    
                    // Wait a moment then click
                    setTimeout(() => {
                        // Try direct click first
                        button.click();
                        
                        // Follow up with events for React compatibility
                        setTimeout(() => {
                            const events = [
                                new MouseEvent('mousedown', { bubbles: true, cancelable: true, view: window }),
                                new MouseEvent('mouseup', { bubbles: true, cancelable: true, view: window }),
                                new MouseEvent('click', { bubbles: true, cancelable: true, view: window }),
                                new PointerEvent('pointerdown', { bubbles: true, cancelable: true }),
                                new PointerEvent('pointerup', { bubbles: true, cancelable: true }),
                                new KeyboardEvent('keydown', { key: 'Enter', code: 'Enter', bubbles: true }),
                                new KeyboardEvent('keyup', { key: 'Enter', code: 'Enter', bubbles: true })
                            ];
                            
                            events.forEach(event => {
                                try {
                                    button.dispatchEvent(event);
                                } catch (e) {
                                    // Ignore event dispatch errors
                                }
                            });
                        }, 10);
                    }, 50);
                    
                    console.log('✅ Submit button click executed');
                    return true;
                } catch (error) {
                    console.error('❌ Error clicking submit button:', error);
                    return false;
                }
            }
            
            // Main execution
            const submitButton = findSubmitButton();
            if (submitButton) {
                return clickButton(submitButton);
            } else {
                console.log('❌ No suitable submit button found for \(config.name)');
                console.log('🔍 Debugging available buttons:');
                const allButtons = document.querySelectorAll('button, [role="button"]');
                
                allButtons.forEach((btn, i) => {
                    if (isValidButton(btn)) {
                        const score = calculateButtonScore(btn);
                        const text = btn.textContent?.substring(0, 30) || '';
                        const ariaLabel = btn.getAttribute('aria-label') || '';
                        const dataTestId = btn.getAttribute('data-testid') || '';
                        const className = btn.className || '';
                        
                        console.log('Button ' + i + ':', {
                            text: text,
                            ariaLabel: ariaLabel,
                            dataTestId: dataTestId,
                            className: className.substring(0, 50),
                            score: score,
                            rect: btn.getBoundingClientRect(),
                            isLikelySubmit: isLikelySubmitButton(btn)
                        });
                    }
                });
                
                // Also check what input areas we found
                console.log('🔍 Input areas found:');
                const inputs = document.querySelectorAll('[contenteditable="true"], textarea, input[type="text"]');
                inputs.forEach((input, i) => {
                    console.log('Input ' + i + ':', {
                        tagName: input.tagName,
                        id: input.id,
                        className: input.className.substring(0, 50),
                        placeholder: input.placeholder || input.getAttribute('data-placeholder'),
                        rect: input.getBoundingClientRect()
                    });
                });
                
                return false;
            }
        })();
        """
        
        executeWithRetry(webView: webView, script: clickScript, maxRetries: 3) { result, error in
            if let error = error {
                print("❌ Submit button click error: \(error)")
                completion(false)
            } else if let success = result as? Bool {
                completion(success)
            } else {
                print("⚠️ Submit button click completed with unknown result")
                completion(false) // より厳密にfalseを返す
            }
        }
    }
    
    private static func executeWithRetry(webView: WKWebView, script: String, maxRetries: Int, completion: @escaping (Any?, Error?) -> Void) {
        func attempt(_ retryCount: Int) {
            webView.evaluateJavaScript(script) { result, error in
                if let error = error, retryCount < maxRetries {
                    print("⚠️ JavaScript retry \(retryCount + 1)/\(maxRetries): \(error)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        attempt(retryCount + 1)
                    }
                } else {
                    completion(result, error)
                }
            }
        }
        attempt(0)
    }
    
    private static func escapeJavaScriptString(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
            .replacingOccurrences(of: "\t", with: "\\t")
    }
    
    private static func jsonString(_ value: [String]) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }
}