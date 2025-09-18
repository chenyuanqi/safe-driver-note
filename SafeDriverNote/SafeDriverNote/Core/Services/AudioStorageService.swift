import Foundation
import AVFoundation

final class AudioStorageService {
    static let shared = AudioStorageService()

    private let documentsDirectory: URL
    private let audioDirectory: URL

    private init() {
        // 获取Documents目录
        documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first!

        // 创建专门的音频存储目录
        audioDirectory = documentsDirectory.appendingPathComponent("AudioFiles")

        // 确保目录存在
        if !FileManager.default.fileExists(atPath: audioDirectory.path) {
            try? FileManager.default.createDirectory(at: audioDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
    }

    /// 保存音频文件并返回文件名
    func saveAudioFile(from url: URL) -> String? {
        // 生成唯一文件名
        let fileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
        let destinationURL = audioDirectory.appendingPathComponent(fileName)

        do {
            // 如果源文件已经在我们的目录中，直接返回文件名
            if url.path.contains(audioDirectory.path) {
                return url.lastPathComponent
            }

            // 复制文件到应用目录
            try FileManager.default.copyItem(at: url, to: destinationURL)
            return fileName
        } catch {
            print("保存音频文件失败: \(error)")
            return nil
        }
    }

    /// 根据文件名获取音频文件URL
    func getAudioURL(fileName: String) -> URL? {
        let fileURL = audioDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// 删除音频文件
    func deleteAudioFile(fileName: String) {
        let fileURL = audioDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// 获取音频文件时长
    func getAudioDuration(fileName: String) -> TimeInterval? {
        guard let url = getAudioURL(fileName: fileName) else { return nil }

        let asset = AVURLAsset(url: url)
        let duration = asset.duration
        let seconds = CMTimeGetSeconds(duration)

        return seconds.isFinite ? seconds : nil
    }

    /// 获取音频文件大小（MB）
    func getAudioFileSize(fileName: String) -> Double? {
        guard let url = getAudioURL(fileName: fileName),
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? Int64 else {
            return nil
        }

        return Double(fileSize) / (1024 * 1024) // 转换为MB
    }

    /// 清理不再使用的音频文件
    func cleanupUnusedAudioFiles(usedFileNames: Set<String>) {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: audioDirectory,
                                                                         includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            if !usedFileNames.contains(fileName) {
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
    }
}