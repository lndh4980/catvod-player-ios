import Foundation

@MainActor
class ConfigManager: ObservableObject {
    @Published var config: CatVodConfig?
    @Published var configUrl: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let configUrlKey = "configUrl"
    
    init() {
        // 加载保存的配置地址
        if let savedUrl = userDefaults.string(forKey: configUrlKey) {
            configUrl = savedUrl
            Task {
                await loadConfig()
            }
        }
    }
    
    func loadConfig() async {
        guard !configUrl.isEmpty else {
            errorMessage = "请输入配置地址"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            guard let url = URL(string: configUrl) else {
                throw ConfigError.invalidUrl
            }
            
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ConfigError.networkError
            }
            
            let decoder = JSONDecoder()
            config = try decoder.decode(CatVodConfig.self, from: data)
            
            // 保存配置地址
            userDefaults.set(configUrl, forKey: configUrlKey)
            
            print("✅ 配置加载成功：\(config?.sites?.count ?? 0) 个站点，\(config?.lives?.count ?? 0) 个直播源")
            
        } catch {
            errorMessage = "加载失败：\(error.localizedDescription)"
            print("❌ 配置加载失败：\(error)")
        }
        
        isLoading = false
    }
    
    func clearConfig() {
        config = nil
        configUrl = ""
        userDefaults.removeObject(forKey: configUrlKey)
    }
}

enum ConfigError: Error, LocalizedError {
    case invalidUrl
    case networkError
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "无效的配置地址"
        case .networkError:
            return "网络请求失败"
        case .parseError:
            return "配置格式错误"
        }
    }
}
