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

// MARK: - m3u 解析

func parseM3U(_ content: String) -> [Channel] {
    var channels: [Channel] = []
    let lines = content.components(separatedBy: .newlines)
    var currentName: String?
    for raw in lines {
        let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if line.hasPrefix("#EXTINF") {
            if let range = line.range(of: ",") {
                let name = String(line[range.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                currentName = name.isEmpty ? "频道" : name
            } else {
                currentName = "频道"
            }
        } else if !line.isEmpty && !line.hasPrefix("#") {
            let chName = currentName ?? line
            channels.append(Channel(name: chName, url: line))
            currentName = nil
        }
    }
    return channels
}

// MARK: - Live List View

struct LiveListView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var selectedLive: LiveItem?

    var body: some View {
        NavigationView {
            List {
                if configManager.isLoading {
                    ProgressView("加载中...")
                } else if let lives = configManager.config?.lives, !lives.isEmpty {
                    ForEach(lives) { live in
                        Button {
                            selectedLive = live
                        } label: {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                Text(live.name)
                                Spacer()
                                if let ua = live.ua, !ua.isEmpty {
                                    Text("UA")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                    }
                } else {
                    Text("暂无直播源")
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("直播")
            .sheet(item: $selectedLive) { live in
                LiveDetailView(live: live)
            }
        }
    }
}

// MARK: - Live Detail (拉取并解析 m3u)

struct LiveDetailView: View {
    let live: LiveItem
    @Environment(\.dismiss) private var dismiss
    @State private var channels: [Channel] = []
    @State private var isLoading = true
    @State private var errorMsg: String?
    @State private var selectedChannel: Channel?
    @State private var showPlayer = false

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("解析中...")
                } else if let errorMsg {
                    ScrollView { Text(errorMsg).foregroundColor(.red).padding() }
                } else if channels.isEmpty {
                    Text("无可用频道").foregroundColor(.gray)
                } else {
                    List(channels) { ch in
                        Button {
                            selectedChannel = ch
                            showPlayer = true
                        } label: {
                            HStack {
                                Image(systemName: "dot.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                Text(ch.name)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(live.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let ch = selectedChannel {
                    let headers = live.ua.map { ["User-Agent": $0] }
                    PlayerView(url: ch.url, title: ch.name, headers: headers)
                }
            }
        }
        .task { await load() }
    }

    func load() async {
        guard !live.url.isEmpty else {
            errorMsg = "无播放地址"; isLoading = false; return
        }
        guard let u = URL(string: live.url) else {
            errorMsg = "地址无效"; isLoading = false; return
        }
        var req = URLRequest(url: u)
        if let ua = live.ua, !ua.isEmpty {
            req.setValue(ua, forHTTPHeaderField: "User-Agent")
        }
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let content = String(data: data, encoding: .utf8) ?? ""
            if content.contains("#EXTINF") || content.contains("#EXTM3U") {
                channels = parseM3U(content)
                if channels.isEmpty { errorMsg = "播放列表为空" }
            } else if let firstHttp = content.components(separatedBy: .newlines)
                .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
                .first(where: { $0.contains("://") }) {
                channels = [Channel(name: live.name, url: firstHttp)]
            } else {
                errorMsg = "无法解析该直播源内容"
            }
        } catch {
            errorMsg = "加载失败: \(error.localizedDescription)"
        }
        isLoading = false
    }
}

// MARK: - Sites View

struct SitesView: View {
    @ObservedObject var configManager: ConfigManager
    @State private var searchText = ""

    var filteredSites: [Site] {
        guard let sites = configManager.config?.sites else { return [] }
        if searchText.isEmpty { return sites }
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
                                    .lineLimit(1)
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
                        Task { await configManager.loadConfig() }
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
    var headers: [String: String]? = nil
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
        .onAppear { loadVideo() }
        .onDisappear { player?.pause() }
    }

    private func loadVideo() {
        guard let videoURL = URL(string: url) else { return }
        if let headers = headers, !headers.isEmpty {
            let asset = AVURLAsset(url: videoURL,
                                   options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
            player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        } else {
            player = AVPlayer(url: videoURL)
        }
        player?.play()
    }
}
