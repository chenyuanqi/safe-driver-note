import Foundation
import AVFoundation

// MARK: - Extensions for Safe File Naming
private extension String {
    var containsNonASCII: Bool {
        return !allSatisfy { $0.isASCII }
    }
}

private extension DateFormatter {
    static let audioFileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter
    }()
}

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
        // 生成安全的文件名，避免中文字符导致的问题
        let originalName = url.lastPathComponent
        let fileExtension = url.pathExtension
        let timestamp = DateFormatter.audioFileNameFormatter.string(from: Date())
        let safeFileName = "\(UUID().uuidString)_\(timestamp).\(fileExtension)"
        let destinationURL = audioDirectory.appendingPathComponent(safeFileName)

        do {
            // 如果源文件已经在我们的目录中，检查是否需要重命名
            if url.path.contains(audioDirectory.path) {
                let existingFileName = url.lastPathComponent
                // 如果文件名包含非ASCII字符，重命名它
                if existingFileName.containsNonASCII {
                    let newURL = audioDirectory.appendingPathComponent(safeFileName)
                    try FileManager.default.moveItem(at: url, to: newURL)
                    return safeFileName
                }
                return existingFileName
            }

            // 复制文件到应用目录
            try FileManager.default.copyItem(at: url, to: destinationURL)
            print("音频文件保存成功: \(originalName) -> \(safeFileName)")
            return safeFileName
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
    func getAudioDuration(fileName: String) async -> TimeInterval? {
        guard let url = getAudioURL(fileName: fileName) else { return nil }

        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : nil
        } catch {
            print("获取音频时长失败: \(error)")
            return nil
        }
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

    /// 修复有问题的音频文件名
    func fixProblematicAudioFiles() {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: audioDirectory,
                                                                         includingPropertiesForKeys: nil) else {
            return
        }

        for fileURL in contents {
            let fileName = fileURL.lastPathComponent
            if fileName.containsNonASCII {
                let fileExtension = fileURL.pathExtension
                let timestamp = DateFormatter.audioFileNameFormatter.string(from: Date())
                let safeFileName = "\(UUID().uuidString)_\(timestamp).\(fileExtension)"
                let newURL = audioDirectory.appendingPathComponent(safeFileName)

                do {
                    try FileManager.default.moveItem(at: fileURL, to: newURL)
                    print("修复音频文件名: \(fileName) -> \(safeFileName)")
                } catch {
                    print("修复音频文件名失败: \(error)")
                }
            }
        }
    }
}