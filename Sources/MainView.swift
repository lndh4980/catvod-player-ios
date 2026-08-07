import SwiftUI

struct MainView: View {
    @StateObject private var configManager = ConfigManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 直播
            LiveListView(config: configManager.config)
                .tabItem {
                    Image(systemName: "tv")
                    Text("直播")
                }
                .tag(0)
            
            // 点播
            SitesView(config: configManager.config)
                .tabItem {
                    Image(systemName: "play.rectangle")
                    Text("点播")
                }
                .tag(1)
            
            // 设置
            SettingsView(configManager: configManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("设置")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}

// MARK: - 直播列表视图

struct LiveListView: View {
    let config: CatVodConfig?
    
    @State private var selectedLive: Live?
    @State private var channels: [LiveChannel] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                } else if channels.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tv.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无直播源")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("请先在设置中添加配置地址")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                } else {
                    List(channels) { channel in
                        Button(action: {
                            selectedLive = Live(
                                name: channel.name,
                                type: 0,
                                url: channel.url,
                                playerType: 2,
                                epg: nil,
                                logo: channel.logo,
                                timeout: nil,
                                ua: nil
                            )
                        }) {
                            HStack {
                                if let logo = channel.logo, let url = URL(string: logo) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().aspectRatio(contentMode: .fit)
                                    } placeholder: {
                                        Image(systemName: "tv")
                                    }
                                    .frame(width: 40, height: 40)
                                    .cornerRadius(4)
                                } else {
                                    Image(systemName: "tv")
                                        .frame(width: 40, height: 40)
                                }
                                
                                VStack(alignment: .leading) {
                                    Text(channel.name)
                                        .font(.headline)
                                    Text(channel.url)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("直播")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await loadLiveChannels()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .sheet(item: $selectedLive) { live in
                PlayerView(url: live.url, title: live.name)
            }
            .task {
                await loadLiveChannels()
            }
        }
    }
    
    private func loadLiveChannels() async {
        guard let lives = config?.lives, !lives.isEmpty else {
            channels = []
            return
        }
        
        isLoading = true
        
        // 加载第一个直播源
        let firstLive = lives[0]
        
        do {
            guard let url = URL(string: firstLive.url) else {
                isLoading = false
                return
            }
            
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let content = String(data: data, encoding: .utf8) {
                if firstLive.url.hasSuffix(".m3u") || firstLive.url.hasSuffix(".m3u8") {
                    channels = LiveParser.parseM3U(content)
                } else {
                    channels = LiveParser.parseTxt(content)
                }
            }
        } catch {
            print("❌ 加载直播源失败：\(error)")
        }
        
        isLoading = false
    }
}

// MARK: - 点播站点视图

struct SitesView: View {
    let config: CatVodConfig?
    
    @State private var searchText = ""
    
    var filteredSites: [Site] {
        guard let sites = config?.sites else { return [] }
        
        if searchText.isEmpty {
            return sites
        } else {
            return sites.filter { site in
                site.name.localizedCaseInsensitiveContains(searchText) ||
                site.key.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if let sites = config?.sites, !sites.isEmpty {
                    List(filteredSites) { site in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(site.name)
                                .font(.headline)
                            
                            HStack {
                                if let type = site.type {
                                    Text("类型: \(type)")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                                
                                if let searchable = site.searchable, searchable == 1 {
                                    Text("可搜索")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            if let api = site.api {
                                Text(api)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "play.rectangle.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("暂无站点")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text("请先在设置中添加配置地址")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationTitle("点播")
            .searchable(text: $searchText, prompt: "搜索站点")
        }
    }
}

// MARK: - 设置视图

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("配置地址")) {
                    TextField("输入配置地址", text: $configManager.configUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    Button(action: {
                        Task {
                            await configManager.loadConfig()
                        }
                    }) {
                        HStack {
                            if configManager.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text("加载配置")
                        }
                    }
                    .disabled(configManager.isLoading || configManager.configUrl.isEmpty)
                    
                    Button("清除配置", role: .destructive) {
                        configManager.clearConfig()
                    }
                }
                
                if let config = configManager.config {
                    Section(header: Text("配置信息")) {
                        LabeledContent("站点数量", value: "\(config.sites?.count ?? 0)")
                        LabeledContent("直播源数量", value: "\(config.lives?.count ?? 0)")
                        
                        if let spider = config.spider {
                            Text("Spider: \(spider)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if let error = configManager.errorMessage {
                    Section(header: Text("错误信息")) {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("关于")) {
                    LabeledContent("版本", value: "1.0.0")
                    LabeledContent("作者", value: "AI Assistant")
                    Text("支持影视仓/CatVod JSON 格式")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("设置")
        }
    }
}
