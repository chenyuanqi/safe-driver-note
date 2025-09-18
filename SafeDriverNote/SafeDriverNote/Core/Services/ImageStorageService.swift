import Foundation
import UIKit

final class ImageStorageService {
    static let shared = ImageStorageService()

    private let documentsDirectory: URL
    private let imagesDirectory: URL

    private init() {
        // 获取Documents目录
        documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                      in: .userDomainMask).first!

        // 创建专门的图片存储目录
        imagesDirectory = documentsDirectory.appendingPathComponent("LogImages")

        // 确保目录存在
        if !FileManager.default.fileExists(atPath: imagesDirectory.path) {
            try? FileManager.default.createDirectory(at: imagesDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
    }

    /// 保存图片并返回文件名数组
    func saveImages(_ images: [UIImage]) -> [String] {
        var savedFileNames: [String] = []

        for image in images {
            // 生成唯一文件名
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = imagesDirectory.appendingPathComponent(fileName)

            // 压缩并保存图片
            if let jpegData = image.jpegData(compressionQuality: 0.8) {
                do {
                    try jpegData.write(to: fileURL)
                    savedFileNames.append(fileName)
                } catch {
                    print("保存图片失败: \(error)")
                }
            }
        }

        return savedFileNames
    }

    /// 根据文件名加载图片
    func loadImage(fileName: String) -> UIImage? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return image
    }

    /// 加载多张图片
    func loadImages(fileNames: [String]) -> [UIImage] {
        return fileNames.compactMap { loadImage(fileName: $0) }
    }

    /// 删除图片
    func deleteImage(fileName: String) {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// 删除多张图片
    func deleteImages(fileNames: [String]) {
        fileNames.forEach { deleteImage(fileName: $0) }
    }

    /// 获取图片文件的URL（用于分享等）
    func getImageURL(fileName: String) -> URL? {
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// 清理不再使用的图片（传入当前所有日志使用的文件名）
    func cleanupUnusedImages(usedFileNames: Set<String>) {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: imagesDirectory,
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