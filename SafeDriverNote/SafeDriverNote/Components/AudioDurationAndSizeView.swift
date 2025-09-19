import SwiftUI
import Foundation
import AVFoundation

struct AudioDurationAndSizeView: View {
    let fileName: String
    @State private var duration: TimeInterval?
    @State private var size: Double?
    
    var body: some View {
        Text(durationAndSizeText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .onAppear {
                Task {
                    await loadAudioInfo()
                }
            }
    }
    
    private var durationAndSizeText: String {
        if let duration = duration, let size = size {
            return "时长: \(formatDuration(duration)) · 大小: \(String(format: "%.1f", size))MB"
        } else if duration == nil && size == nil {
            return "正在加载..."
        } else if let duration = duration {
            return "时长: \(formatDuration(duration))"
        } else if let size = size {
            return "大小: \(String(format: "%.1f", size))MB"
        } else {
            return ""
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func loadAudioInfo() async {
        // 添加调试信息
        print("\n===== AudioDurationAndSizeView - 开始加载音频信息 =====")
        print("文件名: \(fileName)")

        // 列出所有音频文件
        AudioStorageService.shared.listAllAudioFiles()

        // 检查文件是否存在
        if let url = AudioStorageService.shared.getAudioURL(fileName: fileName) {
            print("音频文件URL: \(url.path)")
            print("文件存在: \(FileManager.default.fileExists(atPath: url.path))")
        } else {
            print("⚠️ 无法获取音频文件URL: \(fileName)")
        }

        async let durationTask = AudioStorageService.shared.getAudioDuration(fileName: fileName)
        let sizeResult = AudioStorageService.shared.getAudioFileSize(fileName: fileName)

        print("获取到的文件大小: \(sizeResult ?? -1) MB")

        let durationResult = await durationTask
        print("获取到的时长: \(durationResult ?? -1) 秒")

        await MainActor.run {
            self.duration = durationResult
            self.size = sizeResult
        }
    }
}

#Preview {
    AudioDurationAndSizeView(fileName: "test_audio.m4a")
}