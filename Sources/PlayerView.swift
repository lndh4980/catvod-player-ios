import SwiftUI
import MobileVLCKit

struct PlayerView: View {
    let url: String
    let title: String
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playerManager = VLCPlayerManager()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VLCVideoView(playerManager: playerManager)
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            playerManager.togglePlay()
                        }) {
                            Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Text(playerManager.currentTime)
                            .foregroundColor(.white)
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.black.opacity(0.5))
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        playerManager.stop()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("16:9") {
                            playerManager.setAspectRatio(16.0 / 9.0)
                        }
                        Button("4:3") {
                            playerManager.setAspectRatio(4.0 / 3.0)
                        }
                        Button("自适应") {
                            playerManager.setAspectRatio(0)
                        }
                    } label: {
                        Image(systemName: "aspectratio")
                    }
                }
            }
        }
        .onAppear {
            playerManager.play(url: url)
        }
        .onDisappear {
            playerManager.stop()
        }
    }
}

// MARK: - VLC Video View

struct VLCVideoView: UIViewRepresentable {
    let playerManager: VLCPlayerManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let player = playerManager.player {
            player.drawable = uiView
        }
    }
}

// MARK: - VLC Player Manager

class VLCPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime = "00:00"
    
    var player: VLCMediaPlayer?
    private var media: VLCMedia?
    
    override init() {
        super.init()
        setupPlayer()
    }
    
    private func setupPlayer() {
        player = VLCMediaPlayer()
        player?.delegate = self
        player?.drawable = nil
    }
    
    func play(url: String) {
        guard let mediaURL = URL(string: url) else {
            print("❌ 无效的播放地址：\(url)")
            return
        }
        
        stop()
        
        media = VLCMedia(url: mediaURL)
        player?.media = media
        player?.play()
        
        isPlaying = true
        print("▶️ 开始播放：\(url)")
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
        currentTime = "00:00"
    }
    
    func togglePlay() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }
    
    func setAspectRatio(_ ratio: Float) {
        if ratio == 0 {
            player?.videoAspectRatio = nil
        } else {
            player?.videoAspectRatio = "\(ratio)"
        }
    }
}

// MARK: - VLC Player Delegate

extension VLCPlayerManager: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer else { return }
        
        switch player.state {
        case .playing:
            isPlaying = true
        case .paused, .stopped:
            isPlaying = false
        case .error:
            print("❌ 播放错误")
            isPlaying = false
        default:
            break
        }
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let player = aNotification.object as? VLCMediaPlayer,
              let time = player.time else { return }
        
        let totalSeconds = Int(time.value?.intValue ?? 0) / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        currentTime = String(format: "%02d:%02d", minutes, seconds)
    }
}
