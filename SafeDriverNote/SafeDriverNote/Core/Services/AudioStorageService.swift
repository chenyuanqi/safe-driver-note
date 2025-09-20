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

    static let shortAudioFileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddHHmmss"  // 更短的格式：月日时分秒
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
        print("\n========== 开始保存音频文件 ==========")
        print("源文件URL: \(url.path)")

        // 检查源文件是否存在和大小
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("❌ 源文件不存在: \(url.path)")
            return nil
        }

        // 获取源文件大小
        if let sourceAttributes = try? FileManager.default.attributesOfItem(atPath: url.path),
           let sourceSize = sourceAttributes[.size] as? Int64 {
            print("源文件大小: \(sourceSize) bytes (\(Double(sourceSize) / 1024 / 1024) MB)")

            // 如果文件太小（小于1KB），说明可能有问题
            if sourceSize < 1024 {
                print("⚠️ 警告：文件大小异常小 (\(sourceSize) bytes)，可能不是有效的音频文件")
            }
        } else {
            print("❌ 无法获取源文件大小")
        }

        // 处理文件访问权限（对于从文档选择器获取的文件）
        let shouldStopAccess = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        // 生成更短、更友好的文件名
        // 格式：audio_月日时分秒_随机数.扩展名
        // 例如：audio_1225143025_8f2a3b5c.mp3
        let fileExtension = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
        let timestamp = DateFormatter.shortAudioFileNameFormatter.string(from: Date())
        let randomSuffix = String(UUID().uuidString.prefix(8))  // 取UUID的前8位，确保唯一性
        let safeFileName = "audio_\(timestamp)_\(randomSuffix).\(fileExtension)"
        let destinationURL = audioDirectory.appendingPathComponent(safeFileName)

        print("目标文件名: \(safeFileName)")
        print("目标路径: \(destinationURL.path)")

        do {
            // 如果源文件已经在我们的目录中，检查是否需要重命名
            if url.path.contains(audioDirectory.path) {
                let existingFileName = url.lastPathComponent
                // 如果文件名包含非ASCII字符或太长，重命名它
                if existingFileName.containsNonASCII || existingFileName.count > 30 {
                    let newURL = audioDirectory.appendingPathComponent(safeFileName)
                    try FileManager.default.moveItem(at: url, to: newURL)
                    print("重命名音频文件: \(existingFileName) -> \(safeFileName)")
                    return safeFileName
                }
                return existingFileName
            }

            // 检查源文件是否存在
            guard FileManager.default.fileExists(atPath: url.path) else {
                print("源音频文件不存在: \(url.path)")
                return nil
            }

            // 如果目标文件已存在，先删除
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // 使用Data读写方式，更可靠
            print("开始读取源文件数据...")
            let audioData = try Data(contentsOf: url)
            print("读取到数据大小: \(audioData.count) bytes")

            // 写入目标文件
            print("开始写入目标文件...")
            try audioData.write(to: destinationURL)
            print("✅ 文件写入成功")

            // 验证保存的文件
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: destinationURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    print("✅ 验证成功 - 保存的文件大小: \(fileSize) bytes (\(Double(fileSize) / 1024 / 1024) MB)")

                    // 验证文件大小是否一致
                    if fileSize == audioData.count {
                        print("✅ 文件完整性验证通过")
                    } else {
                        print("⚠️ 文件大小不一致：源 \(audioData.count) bytes, 目标 \(fileSize) bytes")
                    }
                }
                print("========================================\n")
                return safeFileName
            } else {
                print("❌ 文件保存后无法找到")
                print("========================================\n")
                return nil
            }
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
        print("获取音频时长 - 文件名: \(fileName)")

        guard let url = getAudioURL(fileName: fileName) else {
            print("无法获取文件URL，尝试直接路径")
            // 如果获取URL失败，尝试直接构建路径
            let directURL = audioDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: directURL.path) {
                let asset = AVURLAsset(url: directURL)
                do {
                    let duration = try await asset.load(.duration)
                    let seconds = CMTimeGetSeconds(duration)
                    if seconds.isFinite && seconds > 0 {
                        print("获取时长成功（直接路径）: \(seconds) 秒")
                        return seconds
                    }
                } catch {
                    print("获取时长失败（直接路径）: \(error)")
                }
            }
            return nil
        }

        print("使用文件路径: \(url.path)")

        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            print("AVAsset时长: \(seconds) 秒")

            if seconds.isFinite && seconds > 0 {
                return seconds
            } else {
                print("时长无效或为0，尝试使用AVAudioPlayer")
                // 尝试使用AVAudioPlayer作为备用方案
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    let playerDuration = player.duration
                    print("AVAudioPlayer时长: \(playerDuration) 秒")
                    return playerDuration > 0 ? playerDuration : nil
                } catch {
                    print("AVAudioPlayer也失败: \(error)")
                }
            }
            return nil
        } catch {
            print("获取音频时长失败: \(error)")
            return nil
        }
    }

    /// 获取音频文件大小（MB）
    func getAudioFileSize(fileName: String) -> Double? {
        print("获取文件大小 - 文件名: \(fileName)")

        // 尝试获取文件URL
        guard let url = getAudioURL(fileName: fileName) else {
            print("无法获取文件URL: \(fileName)")
            // 如果获取URL失败，尝试直接构建路径
            let directURL = audioDirectory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: directURL.path) {
                print("使用直接路径: \(directURL.path)")
                if let attributes = try? FileManager.default.attributesOfItem(atPath: directURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    let sizeInMB = Double(fileSize) / (1024 * 1024)
                    print("文件大小: \(fileSize) bytes = \(sizeInMB) MB")
                    return sizeInMB
                }
            }
            return nil
        }

        print("文件路径: \(url.path)")
        print("文件存在: \(FileManager.default.fileExists(atPath: url.path))")

        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            print("无法获取文件属性")
            return nil
        }

        guard let fileSize = attributes[.size] as? Int64 else {
            print("无法获取文件大小属性")
            return nil
        }

        let sizeInMB = Double(fileSize) / (1024 * 1024)
        print("文件大小: \(fileSize) bytes = \(sizeInMB) MB")
        return sizeInMB
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

    /// 列出所有音频文件（调试用）
    func listAllAudioFiles() {
        print("========== 音频文件目录内容 ==========")
        print("目录路径: \(audioDirectory.path)")

        if let contents = try? FileManager.default.contentsOfDirectory(at: audioDirectory,
                                                                       includingPropertiesForKeys: [.fileSizeKey]) {
            print("文件数量: \(contents.count)")
            for fileURL in contents {
                let fileName = fileURL.lastPathComponent
                if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
                   let fileSize = attributes[.size] as? Int64 {
                    print("  - \(fileName): \(fileSize) bytes")
                } else {
                    print("  - \(fileName): 无法获取大小")
                }
            }
        } else {
            print("无法读取目录内容")
        }
        print("=====================================")
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