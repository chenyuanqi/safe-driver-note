import SwiftUI
import UniformTypeIdentifiers
import Foundation

private extension DateFormatter {
    static let shortAudioFileNameFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddHHmmss"  // 月日时分秒
        return formatter
    }()
}

struct AudioFilePickerView: UIViewControllerRepresentable {
    @Binding var audioFileName: String?

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // 配置支持的音频文件类型
        let audioTypes: [UTType] = [
            .audio,          // 通用音频
            .mpeg4Audio,     // M4A
            .mp3,            // MP3
            .wav,            // WAV
            .aiff,           // AIFF
            .appleProtectedMPEG4Audio // M4P
        ]

        let picker = UIDocumentPickerViewController(forOpeningContentTypes: audioTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        // 优先显示最近使用的文档
        picker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: AudioFilePickerView

        init(_ parent: AudioFilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            print("\n========== AudioFilePickerView - 开始处理选中的文件 ==========")
            print("文件URL: \(url.path)")
            print("文件名: \(url.lastPathComponent)")

            // 获取文件访问权限
            let accessing = url.startAccessingSecurityScopedResource()
            print("安全作用域资源访问: \(accessing)")

            defer {
                // 确保最后释放权限
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                    print("已释放安全作用域资源访问")
                }
            }

            // 简化的文件处理流程
            var success = false

            do {
                // 生成目标文件名
                let fileExtension = url.pathExtension.isEmpty ? "m4a" : url.pathExtension
                let timestamp = DateFormatter.shortAudioFileNameFormatter.string(from: Date())
                let randomSuffix = String(UUID().uuidString.prefix(8))
                let fileName = "audio_\(timestamp)_\(randomSuffix).\(fileExtension)"

                // 获取目标目录
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let audioDirectory = documentsDirectory.appendingPathComponent("AudioFiles")

                // 确保目录存在
                if !FileManager.default.fileExists(atPath: audioDirectory.path) {
                    try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
                }

                let destinationURL = audioDirectory.appendingPathComponent(fileName)

                // 方法1: 使用 NSFileCoordinator 确保文件可访问
                let coordinator = NSFileCoordinator(filePresenter: nil)
                var coordinatorError: NSError?

                coordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &coordinatorError) { (coordinatedURL) in
                    do {
                        print("使用协调URL: \(coordinatedURL.path)")

                        // 尝试读取文件数据
                        let fileData = try Data(contentsOf: coordinatedURL)
                        print("读取到文件数据: \(fileData.count) bytes")

                        if fileData.count < 1024 {
                            print("⚠️ 警告：文件大小异常小 (\(fileData.count) bytes)")
                            print("可能原因：")
                            print("1. 文件在iCloud中未完全下载")
                            print("2. 文件已损坏")
                            print("\n建议解决方案：")
                            print("1. 在'文件'App中先下载该文件到本地")
                            print("2. 使用AirDrop或其他方式传输文件到设备")
                            print("3. 从本地存储而非iCloud Drive选择文件")
                        }

                        // 保存文件数据
                        try fileData.write(to: destinationURL)
                        print("✅ 文件保存成功: \(fileName)")

                        // 验证保存的文件
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: destinationURL.path),
                           let fileSize = attributes[.size] as? Int64 {
                            print("保存的文件大小: \(fileSize) bytes")
                        }

                        self.parent.audioFileName = fileName
                        success = true
                    } catch {
                        print("❌ 处理协调URL失败: \(error)")
                    }
                }

                if let error = coordinatorError {
                    print("❌ NSFileCoordinator错误: \(error)")
                }

                // 方法2: 如果协调器失败，尝试直接复制
                if !success {
                    print("尝试直接复制文件...")

                    // 检查是否是iCloud文件
                    var isCloudFile = false
                    if let resourceValues = try? url.resourceValues(forKeys: [.isUbiquitousItemKey]) {
                        isCloudFile = resourceValues.isUbiquitousItem ?? false
                    }

                    if isCloudFile {
                        print("⚠️ 这是一个iCloud文件")
                        print("❌ 直接从iCloud读取大文件可能失败")
                        print("请先在'文件'App中下载该文件，或选择本地文件")
                    }

                    // 尝试直接读取
                    let fileData = try Data(contentsOf: url)
                    print("直接读取到: \(fileData.count) bytes")

                    if fileData.count < 1024 {
                        print("⚠️ 文件可能未完全下载或已损坏")
                    }

                    try fileData.write(to: destinationURL)
                    self.parent.audioFileName = fileName
                    success = true
                    print("✅ 直接复制成功")
                }
            } catch {
                print("❌ 文件处理失败: \(error)")
                print("错误详情: \(error.localizedDescription)")

                // 给用户友好的错误提示
                if error.localizedDescription.contains("cloud") || error.localizedDescription.contains("iCloud") {
                    print("\n💡 提示：如果文件在iCloud中，请先下载到本地再选择")
                }
            }

            if !success {
                print("❌ 音频文件处理失败")
            }

            print("========================================\n")
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // 用户取消选择
            print("用户取消了文件选择")
        }
    }
}