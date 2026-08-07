import Foundation
import Combine

@MainActor
class ConfigManager: ObservableObject {
    @Published var config: CatVodConfig?
    @Published var configUrl: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let configUrlKey = "catvod_config_url"
    
    init() {
        loadSavedConfig()
    }
    
    private func loadSavedConfig() {
        if let savedUrl = userDefaults.string(forKey: configUrlKey) {
            configUrl = savedUrl
        }
    }
    
    func loadConfig() async {
        guard !configUrl.isEmpty else {
            errorMessage = "请输入配置地址"
            return
        }
        
        guard let url = URL(string: configUrl) else {
            errorMessage = "无效的 URL"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                throw NSError(domain: "HTTP", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
            }
            
            let decoder = JSONDecoder()
            config = try decoder.decode(CatVodConfig.self, from: data)
            
            // 保存配置地址
            userDefaults.set(configUrl, forKey: configUrlKey)
            
        } catch {
            errorMessage = "加载失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func clearConfig() {
        config = nil
        errorMessage = nil
        userDefaults.removeObject(forKey: configUrlKey)
    }
}
