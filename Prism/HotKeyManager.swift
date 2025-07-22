import AppKit
import Carbon
import Foundation

// MARK: - HotKey Definition
enum HotKeyOption: String, CaseIterable, Identifiable {
    case none = "none"
    case cmdShiftP = "cmd_shift_p"
    case cmdOptionSpace = "cmd_option_space"
    case ctrlShiftSpace = "ctrl_shift_space"
    case cmdShiftSpace = "cmd_shift_space"
    case optionSpace = "option_space"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none:
            return "設定なし"
        case .cmdShiftP:
            return "⌘+Shift+P"
        case .cmdOptionSpace:
            return "⌘+Option+Space"
        case .ctrlShiftSpace:
            return "Ctrl+Shift+Space"
        case .cmdShiftSpace:
            return "⌘+Shift+Space"
        case .optionSpace:
            return "Option+Space"
        }
    }
    
    var description: String {
        switch self {
        case .none:
            return "ホットキーを使用しない"
        case .cmdShiftP:
            return "VS Code風のコマンドパレット"
        case .cmdOptionSpace:
            return "Alfred風のランチャー"
        case .ctrlShiftSpace:
            return "Google Input Tools風"
        case .cmdShiftSpace:
            return "Spotlight代替"
        case .optionSpace:
            return "シンプルなアクセス"
        }
    }
    
    var keyCode: UInt32? {
        switch self {
        case .none:
            return nil
        case .cmdShiftP:
            return 35 // kVK_ANSI_P
        case .cmdOptionSpace, .ctrlShiftSpace, .cmdShiftSpace, .optionSpace:
            return 49 // kVK_Space
        }
    }
    
    var modifierFlags: UInt32 {
        switch self {
        case .none:
            return 0
        case .cmdShiftP:
            return 0x0100 + 0x0200 // cmdKey + shiftKey
        case .cmdOptionSpace:
            return 0x0100 + 0x0800 // cmdKey + optionKey
        case .ctrlShiftSpace:
            return 0x1000 + 0x0200 // controlKey + shiftKey
        case .cmdShiftSpace:
            return 0x0100 + 0x0200 // cmdKey + shiftKey
        case .optionSpace:
            return 0x0800 // optionKey
        }
    }
}

// MARK: - HotKey Manager
class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    @Published var selectedHotKey: HotKeyOption {
        didSet {
            UserDefaults.standard.set(selectedHotKey.rawValue, forKey: "selectedHotKey")
            updateHotKeyRegistration()
        }
    }
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var onHotKeyPressed: (() -> Void)?
    
    private init() {
        let savedRawValue = UserDefaults.standard.string(forKey: "selectedHotKey") ?? HotKeyOption.none.rawValue
        self.selectedHotKey = HotKeyOption(rawValue: savedRawValue) ?? .none
        
        setupEventHandler()
        updateHotKeyRegistration()
    }
    
    deinit {
        unregisterHotKey()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
    
    // MARK: - Public Methods
    func setHotKeyCallback(_ callback: @escaping () -> Void) {
        self.onHotKeyPressed = callback
    }
    
    // MARK: - Private Methods
    private func setupEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        let callback: EventHandlerProcPtr = { (nextHandler, theEvent, userData) -> OSStatus in
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData!).takeUnretainedValue()
            manager.handleHotKeyEvent()
            return noErr
        }
        
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            callback,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )
        
        if status != noErr {
            print("❌ Failed to install event handler: \(status)")
        }
    }
    
    private func updateHotKeyRegistration() {
        unregisterHotKey()
        
        guard selectedHotKey != .none,
              let keyCode = selectedHotKey.keyCode else {
            print("📝 HotKey disabled")
            return
        }
        
        registerHotKey(keyCode: keyCode, modifiers: selectedHotKey.modifierFlags)
    }
    
    private func registerHotKey(keyCode: UInt32, modifiers: UInt32) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x50524953), id: 1) // 'PRIS'
        
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr {
            print("✅ HotKey registered: \(selectedHotKey.displayName)")
        } else {
            print("❌ Failed to register hotkey: \(status)")
            
            // 一般的なエラーの説明
            let errorMessage: String
            switch status {
            case -9878: // eventAlreadyPostedErr 
                errorMessage = "This hotkey combination is already in use by another application"
            case -50: // paramErr
                errorMessage = "Invalid parameter for hotkey registration"  
            case -600: // procNotFound
                errorMessage = "Process not found"
            case -609: // memFullErr
                errorMessage = "Memory full error"
            default:
                errorMessage = "Unknown error code: \(status)"
            }
            print("   → \(errorMessage)")
        }
    }
    
    private func unregisterHotKey() {
        if let hotKeyRef = hotKeyRef {
            let status = UnregisterEventHotKey(hotKeyRef)
            if status == noErr {
                print("✅ HotKey unregistered")
            } else {
                print("❌ Failed to unregister hotkey: \(status)")
            }
            self.hotKeyRef = nil
        }
    }
    
    private func handleHotKeyEvent() {
        print("🔥 HotKey activated: \(selectedHotKey.displayName)")
        
        DispatchQueue.main.async { [weak self] in
            self?.onHotKeyPressed?()
        }
    }
    
    // MARK: - Accessibility Check
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue(): true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func requestAccessibilityPermission() {
        let alert = NSAlert()
        alert.messageText = "アクセシビリティ許可が必要です"
        alert.informativeText = "グローバルホットキーを使用するには、「システム設定」>「プライバシーとセキュリティ」>「アクセシビリティ」でPrismを許可してください。"
        alert.addButton(withTitle: "システム設定を開く")
        alert.addButton(withTitle: "後で設定する")
        alert.alertStyle = .informational
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}