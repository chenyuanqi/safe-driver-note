import SwiftUI
import UniformTypeIdentifiers

struct AudioFilePickerView: UIViewControllerRepresentable {
    @Binding var selectedAudioURL: URL?

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

            // 获取文件访问权限
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            // 复制文件到应用的文档目录
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                             in: .userDomainMask).first!
            let audioDirectory = documentsDirectory.appendingPathComponent("AudioFiles")

            // 确保目录存在
            if !FileManager.default.fileExists(atPath: audioDirectory.path) {
                try? FileManager.default.createDirectory(at: audioDirectory,
                                                        withIntermediateDirectories: true,
                                                        attributes: nil)
            }

            // 生成唯一文件名
            let fileName = "\(UUID().uuidString)_\(url.lastPathComponent)"
            let destinationURL = audioDirectory.appendingPathComponent(fileName)

            do {
                // 复制文件到应用目录
                try FileManager.default.copyItem(at: url, to: destinationURL)
                self.parent.selectedAudioURL = destinationURL
            } catch {
                print("复制音频文件失败: \(error)")
            }
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // 用户取消选择
        }
    }
}