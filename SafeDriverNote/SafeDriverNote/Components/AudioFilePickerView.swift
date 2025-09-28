import SwiftUI
import UniformTypeIdentifiers
import Foundation
import AVFoundation

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

        // 使用导入模式，让系统复制文件
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: audioTypes, asCopy: true)
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
            print("原始文件URL: \(url.path)")
            print("文件名: \(url.lastPathComponent)")

            // 使用后台队列处理，避免阻塞UI
            DispatchQueue.global(qos: .userInitiated).async {
                var success = false
                var errorMessage = ""

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

                    // 检查源文件
                    if FileManager.default.fileExists(atPath: url.path) {
                        print("源文件存在")

                        // 获取文件属性
                        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                        let fileSize = attributes[.size] as? Int64 ?? 0
                        print("源文件大小: \(fileSize) bytes (\(Double(fileSize) / 1024 / 1024) MB)")

                        if fileSize > 1024 {
                            // 文件大小正常，尝试复制
                            try FileManager.default.copyItem(at: url, to: destinationURL)
                            print("✅ 文件复制成功")

                            // 验证目标文件
                            let destAttributes = try FileManager.default.attributesOfItem(atPath: destinationURL.path)
                            let destSize = destAttributes[.size] as? Int64 ?? 0
                            print("目标文件大小: \(destSize) bytes")

                            if destSize > 1024 {
                                // 验证文件可播放性
                                let asset = AVURLAsset(url: destinationURL)
                                Task {
                                    do {
                                        let playable = try await asset.load(.isPlayable)
                                        print("文件可播放: \(playable)")
                                    } catch {
                                        print("检查文件可播放性失败: \(error)")
                                    }
                                }

                                DispatchQueue.main.async {
                                    self.parent.audioFileName = fileName
                                }
                                success = true
                            } else {
                                errorMessage = "复制后的文件太小"
                                try? FileManager.default.removeItem(at: destinationURL)
                            }
                        } else {
                            // 文件太小
                            print("⚠️ 源文件太小: \(fileSize) bytes")
                            errorMessage = "文件只有 \(fileSize) 字节，可能未完全下载"

                            // 尝试读取数据的其他方法
                            if let data = try? Data(contentsOf: url), data.count > 1024 {
                                print("使用Data读取成功: \(data.count) bytes")
                                try data.write(to: destinationURL)
                                DispatchQueue.main.async {
                                    self.parent.audioFileName = fileName
                                }
                                success = true
                            }
                        }
                    } else {
                        print("❌ 源文件不存在")
                        errorMessage = "无法访问文件"

                        // 尝试使用Data直接读取
                        if let data = try? Data(contentsOf: url) {
                            print("使用Data读取: \(data.count) bytes")
                            if data.count > 1024 {
                                try data.write(to: destinationURL)
                                DispatchQueue.main.async {
                                    self.parent.audioFileName = fileName
                                }
                                success = true
                            } else {
                                errorMessage = "文件太小: \(data.count) 字节"
                            }
                        }
                    }
                } catch {
                    print("❌ 处理失败: \(error)")
                    errorMessage = error.localizedDescription
                }

                // 显示结果
                DispatchQueue.main.async {
                    if success {
                        print("✅ 音频文件处理成功")
                    } else {
                        print("❌ 音频文件处理失败: \(errorMessage)")
                        self.showErrorAlert(errorMessage)
                    }
                    print("========================================\n")
                }
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            print("用户取消了文件选择")
        }

        private func showErrorAlert(_ errorDetail: String) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }

            var topController = rootViewController
            while let presented = topController.presentedViewController {
                topController = presented
            }

            // 创建带有左对齐文字的消息
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left

            let messageAttributes: [NSAttributedString.Key: Any] = [
                .paragraphStyle: paragraphStyle,
                .font: UIFont.systemFont(ofSize: 14)
            ]

            let message = """
            错误详情：\(errorDetail)

            可能的解决方案：

            如果是iCloud文件：
            1. 打开"文件"App
            2. 找到音频文件
            3. 长按文件，选择"下载"
            4. 等待显示实际文件大小
            5. 再重新选择

            其他方法：
            • 使用AirDrop传输文件
            • 保存到"我的iPhone"
            • 从音乐App分享
            """

            let attributedMessage = NSAttributedString(string: message, attributes: messageAttributes)

            let alert = UIAlertController(
                title: "无法加载音频文件",
                message: nil,
                preferredStyle: .alert
            )

            // 设置消息的左对齐
            alert.setValue(attributedMessage, forKey: "attributedMessage")

            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            topController.present(alert, animated: true)
        }
    }
}