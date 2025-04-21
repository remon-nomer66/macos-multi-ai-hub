import Foundation

enum AIService: String, CaseIterable, Identifiable {
    case chatGPT = "ChatGPT"
    case gemini  = "Gemini"
    case claude  = "Claude"

    var id: String { rawValue }
    var displayName: String { rawValue }
    var url: URL {
        switch self {
        case .chatGPT: return URL(string: "https://chat.openai.com/")!
        case .gemini:  return URL(string: "https://gemini.google.com/app?hl=ja")!
        case .claude:  return URL(string: "https://claude.ai/new")!
        }
    }
}
