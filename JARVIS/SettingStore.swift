import SwiftUI

class SettingsStore: ObservableObject {
    enum WindowSize: String, CaseIterable, Identifiable {
        case small, medium, large
        var id: String { rawValue }
        var size: CGSize {
            switch self {
            case .small:  return CGSize(width: 300, height: 600)
            case .medium: return CGSize(width: 400, height: 900)
            case .large:  return CGSize(width: 600, height: 1200)
            }
        }
        var displayName: String {
            switch self {
            case .small:  return "小"
            case .medium: return "中"
            case .large:  return "大"
            }
        }
    }

    @Published var windowSize: WindowSize = .medium
}
