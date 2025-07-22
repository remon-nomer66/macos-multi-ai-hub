import SwiftUI
import Foundation

class SettingsStore: ObservableObject {
    enum WindowSize: String, CaseIterable, Identifiable {
        case small, medium, large, custom
        var id: String { rawValue }
        var size: CGSize {
            switch self {
            case .small:  return CGSize(width: 350, height: 700)
            case .medium: return CGSize(width: 450, height: 900)
            case .large:  return CGSize(width: 650, height: 1200)
            case .custom: return CGSize(width: 450, height: 900) // デフォルト値
            }
        }
        var displayName: String {
            switch self {
            case .small:  return "小"
            case .medium: return "中"
            case .large:  return "大"
            case .custom: return "カスタム"
            }
        }
    }
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let windowSize = "windowSize"
        static let customWindowWidth = "customWindowWidth"
        static let customWindowHeight = "customWindowHeight"
        static let webViewZoomScale = "webViewZoomScale"
        static let selectedHotKey = "selectedHotKey"
        static let parallelMode = "parallelMode"
    }
    
    // MARK: - Published Properties
    @Published var windowSize: WindowSize = .medium {
        didSet {
            UserDefaults.standard.set(windowSize.rawValue, forKey: UserDefaultsKeys.windowSize)
        }
    }
    
    @Published var customWindowWidth: Double = 450
    @Published var customWindowHeight: Double = 900
    
    // 一時的な値を保持するためのプロパティ（最小値制限付き）
    @Published var tempCustomWindowWidth: Double = 450
    @Published var tempCustomWindowHeight: Double = 900
    
    @Published var webViewZoomScale: Double = 1.0 {
        didSet {
            UserDefaults.standard.set(webViewZoomScale, forKey: UserDefaultsKeys.webViewZoomScale)
        }
    }
    
    @Published var parallelMode: Bool = false {
        didSet {
            UserDefaults.standard.set(parallelMode, forKey: UserDefaultsKeys.parallelMode)
        }
    }
    
    // MARK: - Computed Properties
    var currentWindowSize: CGSize {
        if windowSize == .custom {
            return CGSize(width: customWindowWidth, height: customWindowHeight)
        }
        return windowSize.size
    }
    
    // MARK: - Public Methods
    func applyCustomWindowSize() {
        // 最小値制限を適用 (300x600)
        customWindowWidth = max(tempCustomWindowWidth, 300)
        customWindowHeight = max(tempCustomWindowHeight, 600)
        
        // tempに制限後の値を反映
        tempCustomWindowWidth = customWindowWidth
        tempCustomWindowHeight = customWindowHeight
        
        // UserDefaultsに保存
        UserDefaults.standard.set(customWindowWidth, forKey: UserDefaultsKeys.customWindowWidth)
        UserDefaults.standard.set(customWindowHeight, forKey: UserDefaultsKeys.customWindowHeight)
    }
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        // Load window size
        if let windowSizeString = UserDefaults.standard.object(forKey: UserDefaultsKeys.windowSize) as? String,
           let savedWindowSize = WindowSize(rawValue: windowSizeString) {
            windowSize = savedWindowSize
        }
        
        // Load custom window dimensions with minimum constraints
        let savedWidth = UserDefaults.standard.double(forKey: UserDefaultsKeys.customWindowWidth)
        if savedWidth > 0 {
            customWindowWidth = max(savedWidth, 300) // 最小幅300
            tempCustomWindowWidth = customWindowWidth
        }
        
        let savedHeight = UserDefaults.standard.double(forKey: UserDefaultsKeys.customWindowHeight)
        if savedHeight > 0 {
            customWindowHeight = max(savedHeight, 600) // 最小高さ600
            tempCustomWindowHeight = customWindowHeight
        }
        
        // Load web view zoom scale
        let savedZoom = UserDefaults.standard.double(forKey: UserDefaultsKeys.webViewZoomScale)
        if savedZoom > 0 {
            webViewZoomScale = savedZoom
        } else {
            webViewZoomScale = 1.0
        }
        
        // Load parallel mode
        parallelMode = UserDefaults.standard.bool(forKey: UserDefaultsKeys.parallelMode)
    }
}
