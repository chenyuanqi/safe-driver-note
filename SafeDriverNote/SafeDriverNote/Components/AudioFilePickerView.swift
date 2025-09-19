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

            // 检查源文件是否存在
            print("检查文件是否可访问...")
            if !FileManager.default.fileExists(atPath: url.path) {
                print("⚠️ 文件不存在或无法直接访问，尝试获取安全权限...")
            }

            // 获取文件访问权限
            let accessing = url.startAccessingSecurityScopedResource()
            print("安全作用域资源访问: \(accessing)")

            // 尝试触发文件下载（对于云存储文件）
            print("检查文件是否需要下载...")

            // 方法1: 尝试使用 NSFileCoordinator 触发下载
            let fileCoordinator = NSFileCoordinator(filePresenter: nil)
            var downloadError: NSError?

            fileCoordinator.coordinate(readingItemAt: url, options: [.forUploading], error: &downloadError) { (downloadURL) in
                print("NSFileCoordinator forUploading URL: \(downloadURL.path)")
                if let attributes = try? FileManager.default.attributesOfItem(atPath: downloadURL.path) {
                    let size = attributes[.size] as? Int64 ?? 0
                    print("forUploading 文件大小: \(size) bytes")
                }
            }

            if let error = downloadError {
                print("NSFileCoordinator forUploading 错误: \(error)")
            }

            // 方法2: 检查文件资源值
            do {
                let resourceKeys: [URLResourceKey] = [
                    .isUbiquitousItemKey,
                    .ubiquitousItemDownloadingStatusKey,
                    .fileSizeKey
                ]

                let resourceValues = try url.resourceValues(forKeys: Set(resourceKeys))

                if let fileSize = resourceValues.fileSize {
                    print("资源值报告的文件大小: \(fileSize) bytes")
                }

                if let isUbiquitous = resourceValues.isUbiquitousItem {
                    print("是否为云文件: \(isUbiquitous)")

                    if isUbiquitous {
                        if let downloadStatus = resourceValues.ubiquitousItemDownloadingStatus {
                            print("下载状态: \(downloadStatus.rawValue)")

                            let isDownloaded = (downloadStatus == .downloaded || downloadStatus == .current)
                            print("是否已下载: \(isDownloaded)")

                            if !isDownloaded {
                                print("尝试触发下载...")
                                try FileManager.default.startDownloadingUbiquitousItem(at: url)

                                // 等待下载
                                for i in 1...20 {
                                    Thread.sleep(forTimeInterval: 0.5)
                                    let values = try url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey])
                                    if let status = values.ubiquitousItemDownloadingStatus,
                                       (status == .downloaded || status == .current) {
                                        print("✅ 文件下载完成")
                                        break
                                    }
                                    if i % 4 == 0 {
                                        print("等待下载... (\(i/2)秒)")
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                print("检查文件状态失败: \(error)")
            }

            // 使用FileCoordinator来确保文件访问
            var coordinatorError: NSError?
            var success = false
            let coordinator = NSFileCoordinator(filePresenter: nil)

            coordinator.coordinate(readingItemAt: url, options: [.withoutChanges], error: &coordinatorError) { (fileURL) in
                do {
                    print("使用FileCoordinator读取文件...")
                    print("协调后的URL: \(fileURL.path)")

                    // 检查文件属性
                    var sourceFileSize: Int64 = 0
                    if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path) {
                        sourceFileSize = attributes[.size] as? Int64 ?? 0
                        print("源文件大小: \(sourceFileSize) bytes (\(Double(sourceFileSize) / 1024 / 1024) MB)")
                    }

                    // 如果文件太小，尝试使用不同的方法读取
                    if sourceFileSize < 1024 {
                        print("⚠️ 文件异常小，尝试使用InputStream读取完整内容...")

                        // 尝试使用InputStream读取
                        if let inputStream = InputStream(url: fileURL) {
                            inputStream.open()
                            defer { inputStream.close() }

                            var data = Data()
                            let bufferSize = 4096
                            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                            defer { buffer.deallocate() }

                            while inputStream.hasBytesAvailable {
                                let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
                                if bytesRead > 0 {
                                    data.append(buffer, count: bytesRead)
                                } else if bytesRead == 0 {
                                    break
                                } else {
                                    print("InputStream读取错误")
                                    break
                                }
                            }

                            print("InputStream读取到的数据大小: \(data.count) bytes")

                            if data.count > sourceFileSize {
                                sourceFileSize = Int64(data.count)
                                print("✅ 成功读取更多数据")
                            }
                        }
                    }

                    // 生成文件名
                    let fileExtension = fileURL.pathExtension.isEmpty ? "m4a" : fileURL.pathExtension
                    let timestamp = DateFormatter.shortAudioFileNameFormatter.string(from: Date())
                    let randomSuffix = String(UUID().uuidString.prefix(4))
                    let fileName = "audio_\(timestamp)_\(randomSuffix).\(fileExtension)"

                    // 获取音频目录
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let audioDirectory = documentsDirectory.appendingPathComponent("AudioFiles")

                    // 确保目录存在
                    if !FileManager.default.fileExists(atPath: audioDirectory.path) {
                        try FileManager.default.createDirectory(at: audioDirectory, withIntermediateDirectories: true, attributes: nil)
                    }

                    let destinationURL = audioDirectory.appendingPathComponent(fileName)

                    // 如果文件大小仍然异常小，尝试多种方法
                    if sourceFileSize < 1024 {
                        print("⚠️ 警告：源文件可能未完全下载或损坏")

                        // 尝试方法1：使用Data(contentsOf:)
                        print("尝试方法1: Data(contentsOf:)")
                        if let data = try? Data(contentsOf: fileURL) {
                            print("Data读取大小: \(data.count) bytes")
                            if data.count > 1024 {
                                try data.write(to: destinationURL)
                                print("✅ 使用Data方法保存成功")
                                success = true
                            }
                        }

                        // 如果还是失败，尝试方法2：直接复制
                        if !success {
                            print("尝试方法2: 直接复制文件")
                            try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                        }
                    } else {
                        // 正常复制文件
                        print("开始复制文件到: \(destinationURL.path)")

                        // 如果目标文件已存在，先删除
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            try FileManager.default.removeItem(at: destinationURL)
                        }

                        // 复制文件
                        try FileManager.default.copyItem(at: fileURL, to: destinationURL)
                    }
                    print("✅ 文件复制成功")

                    // 验证文件
                    if let destAttributes = try? FileManager.default.attributesOfItem(atPath: destinationURL.path),
                       let destFileSize = destAttributes[.size] as? Int64 {
                        print("✅ 目标文件验证成功 - 大小: \(destFileSize) bytes (\(Double(destFileSize) / 1024 / 1024) MB)")

                        if destFileSize < 1024 {
                            print("⚠️ 警告：文件大小异常小，可能复制失败")
                        }

                        self.parent.audioFileName = fileName
                        success = true
                    } else {
                        print("❌ 目标文件验证失败")
                    }
                } catch {
                    print("❌ 文件操作失败: \(error.localizedDescription)")
                    print("错误详情: \(error)")
                }
            }

            if let error = coordinatorError {
                print("❌ FileCoordinator错误: \(error.localizedDescription)")
            }

            // 释放权限
            if accessing {
                url.stopAccessingSecurityScopedResource()
                print("已释放安全作用域资源访问")
            }

            if !success {
                print("❌ AudioFilePickerView - 音频文件处理失败")
            }

            print("========================================\n")
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // 用户取消选择
        }
    }
}