import SwiftUI
import AVFoundation

class AudioPlayerViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private let fileName: String
    
    init(fileName: String) {
        self.fileName = fileName
        super.init()
        setupAudioSession()
        setupAudioPlayer()
    }

    private func setupAudioSession() {
        do {
            // 配置音频会话
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("音频会话配置成功")
        } catch {
            print("音频会话配置失败: \(error)")
        }
    }
    
    private var audioURL: URL? {
        AudioStorageService.shared.getAudioURL(fileName: fileName)
    }
    
    private func setupAudioPlayer() {
        guard let url = audioURL else {
            print("音频文件URL为空: \(fileName)")
            return
        }

        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("音频文件不存在: \(url.path)")
            return
        }

        do {
            // 获取文件属性，用于调试
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) {
                let fileSize = attributes[.size] as? Int64 ?? 0
                print("音频文件大小: \(fileSize) bytes")
            }

            // 尝试准备播放器
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay() // 预加载音频数据
            duration = audioPlayer?.duration ?? 0
            print("音频播放器初始化成功: \(fileName), 时长: \(duration)秒")
        } catch {
            print("无法初始化音频播放器: \(fileName)")
            print("错误详情: \(error.localizedDescription)")
            print("文件路径: \(url.path)")

            // 尝试使用AVAsset获取时长（作为备用方案）
            Task { @MainActor in
                if let duration = await AudioStorageService.shared.getAudioDuration(fileName: fileName) {
                    self.duration = duration
                    print("通过AVAsset获取时长成功: \(duration)秒")
                }
            }
        }
    }
    
    func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        guard let player = audioPlayer else {
            print("音频播放器未初始化，尝试重新初始化")
            setupAudioPlayer()
            return
        }

        do {
            // 确保音频会话激活
            try AVAudioSession.sharedInstance().setActive(true)

            player.currentTime = currentTime
            let success = player.play()
            if success {
                isPlaying = true
                print("开始播放音频")

                // 启动计时器更新进度
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    DispatchQueue.main.async {
                        self.currentTime = player.currentTime
                    }
                }
            } else {
                print("播放失败")
            }
        } catch {
            print("激活音频会话失败: \(error)")
        }
    }
    
    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        timer?.invalidate()
        currentTime = 0
    }
    
    func seekToTime(_ time: TimeInterval) {
        audioPlayer?.currentTime = time
        if isPlaying {
            audioPlayer?.play()
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - AVAudioPlayerDelegate
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        timer?.invalidate()
    }
}

struct AudioPlayerView: View {
    let fileName: String
    @StateObject private var viewModel: AudioPlayerViewModel
    
    init(fileName: String) {
        self.fileName = fileName
        _viewModel = StateObject(wrappedValue: AudioPlayerViewModel(fileName: fileName))
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // 播放/暂停按钮
            Button(action: viewModel.togglePlayback) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 进度条
            VStack(alignment: .leading, spacing: 4) {
                Slider(
                    value: Binding(
                        get: { viewModel.currentTime },
                        set: { newValue in
                            viewModel.seekToTime(newValue)
                        }
                    ),
                    in: 0...max(viewModel.duration, 0.1),
                    step: 0.1
                )
                .accentColor(.blue)
                
                // 时间显示
                HStack {
                    Text(viewModel.formatTime(viewModel.currentTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(viewModel.formatTime(viewModel.duration))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 文件信息
            VStack(alignment: .trailing, spacing: 2) {
                if let size = AudioStorageService.shared.getAudioFileSize(fileName: fileName) {
                    Text("\(String(format: "%.1f", size))MB")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onDisappear {
            viewModel.stopPlayback()
        }
    }
}

#Preview {
    AudioPlayerView(fileName: "test_audio.m4a")
}