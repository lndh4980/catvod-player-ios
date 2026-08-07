import SwiftUI
import AVKit

// MARK: - Main View

struct MainView: View {
    @StateObject private var configManager = ConfigManager()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LiveListView(configManager: configManager)
                .tabItem {
                    Label("直播", systemImage: "tv")
                }
                .tag(0)
            
            SitesView(configManager: configManager)
                .tabItem {
                    Label("点播", systemImage: "play.rectangle")
                }
                .tag(1)
            
            SettingsView(configManager: configManager)
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(2)
        }
    }
}

// MARK: - Live List View

struct LiveListView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var selectedLive: LiveItem?
    @State private var showPlayer = false
    
    var body: some View {
        NavigationView {
            List {
                if configManager.isLoading {
                    ProgressView("加载中...")
                } else if let lives = configManager.config?.lives, !lives.isEmpty {
                    ForEach(lives) { live in
                        Button {
                            selectedLive = live
                            showPlayer = true
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                Text(live.name)
                                Spacer()
                                Text(live.url)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                        }
                    }
                } else {
                    Text("暂无直播源")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("直播")
            .fullScreenCover(isPresented: $showPlayer) {
                if let live = selectedLive {
                    PlayerView(url: live.url, title: live.name)
                }
            }
        }
    }
}

// MARK: - Sites View

struct SitesView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var searchText = ""
    
    var filteredSites: [Site] {
        guard let sites = configManager.config?.sites else { return [] }
        if searchText.isEmpty {
            return sites
        }
        return sites.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                if configManager.isLoading {
                    ProgressView("加载中...")
                } else if filteredSites.isEmpty {
                    Text("暂无站点")
                        .foregroundColor(.gray)
                } else {
                    ForEach(filteredSites) { site in
                        HStack {
                            Image(systemName: "play.circle")
                                .foregroundColor(.green)
                            Text(site.name)
                            Spacer()
                            if let api = site.api {
                                Text(api)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
            }
            .navigationTitle("点播")
            .searchable(text: $searchText, prompt: "搜索站点")
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var configUrl = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("配置地址") {
                    TextField("输入影视仓 JSON 地址", text: $configUrl)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Button("加载配置") {
                        configManager.configUrl = configUrl
                        Task {
                            await configManager.loadConfig()
                        }
                    }
                    .disabled(configUrl.isEmpty || configManager.isLoading)
                }
                
                if let config = configManager.config {
                    Section("配置信息") {
                        LabeledContent("站点数量", value: "\(config.sites?.count ?? 0)")
                        LabeledContent("直播源数量", value: "\(config.lives?.count ?? 0)")
                    }
                }
                
                if let error = configManager.errorMessage {
                    Section("错误") {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("设置")
        }
        .onAppear {
            configUrl = configManager.configUrl
        }
    }
}

// MARK: - Player View

struct PlayerView: View {
    let url: String
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            } else {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            
            VStack {
                HStack {
                    Button {
                        player?.pause()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .clipShape(Capsule())
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            loadVideo()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func loadVideo() {
        guard let videoURL = URL(string: url) else { return }
        player = AVPlayer(url: videoURL)
        player?.play()
    }
}
