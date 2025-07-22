import Foundation
import Combine

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

// MARK: - Extended AI Service (Built-in + Custom)
struct ExtendedAIService: Identifiable, Equatable {
    let id: String
    let displayName: String
    let url: URL
    let isCustom: Bool
    let customService: CustomAIService?
    
    init(builtIn service: AIService) {
        self.id = service.id
        self.displayName = service.displayName
        self.url = service.url
        self.isCustom = false
        self.customService = nil
    }
    
    init(custom service: CustomAIService) {
        self.id = service.id.uuidString
        self.displayName = service.displayName
        self.url = service.serviceURL ?? URL(string: "about:blank")!
        self.isCustom = true
        self.customService = service
    }
    
    static func == (lhs: ExtendedAIService, rhs: ExtendedAIService) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Service Provider
class AIServiceProvider: ObservableObject {
    @Published var availableServices: [ExtendedAIService] = []
    
    private let customServiceManager: CustomAIServiceManager
    private var cancellables: Set<AnyCancellable> = []
    
    init(customServiceManager: CustomAIServiceManager) {
        self.customServiceManager = customServiceManager
        updateAvailableServices()
        
        // CustomAIServiceManager の変更を監視
        customServiceManager.$customServices
            .sink { [weak self] _ in
                self?.updateAvailableServices()
            }
            .store(in: &cancellables)
    }
    
    private func updateAvailableServices() {
        var services: [ExtendedAIService] = []
        
        // Built-in services
        for service in AIService.allCases {
            services.append(ExtendedAIService(builtIn: service))
        }
        
        // Valid custom services
        for customService in customServiceManager.validServices {
            services.append(ExtendedAIService(custom: customService))
        }
        
        availableServices = services
    }
}
