import Foundation

struct CustomAIService: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var url: String
    
    init(name: String = "", url: String = "") {
        self.id = UUID()
        self.name = name
        self.url = url
    }
    
    var isValid: Bool {
        return !name.isEmpty && !url.isEmpty && name.count <= 10
    }
    
    var displayName: String {
        return name.isEmpty ? "未設定" : name
    }
    
    var serviceURL: URL? {
        return URL(string: url)
    }
}

class CustomAIServiceManager: ObservableObject {
    @Published var customServices: [CustomAIService] = []
    
    private let userDefaultsKey = "customAIServices"
    private let maxServices = 3
    
    init() {
        loadCustomServices()
    }
    
    func addService() -> Bool {
        guard customServices.count < maxServices else { return false }
        customServices.append(CustomAIService())
        saveCustomServices()
        return true
    }
    
    func removeService(at index: Int) {
        guard index < customServices.count else { return }
        customServices.remove(at: index)
        saveCustomServices()
    }
    
    func updateService(at index: Int, with service: CustomAIService) {
        guard index < customServices.count else { return }
        customServices[index] = service
        saveCustomServices()
    }
    
    var canAddMore: Bool {
        return customServices.count < maxServices
    }
    
    var validServices: [CustomAIService] {
        return customServices.filter { $0.isValid }
    }
    
    private func saveCustomServices() {
        if let data = try? JSONEncoder().encode(customServices) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }
    
    private func loadCustomServices() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let services = try? JSONDecoder().decode([CustomAIService].self, from: data) else {
            return
        }
        customServices = services
    }
}