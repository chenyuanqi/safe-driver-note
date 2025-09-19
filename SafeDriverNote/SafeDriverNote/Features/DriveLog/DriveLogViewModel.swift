import Foundation
import SwiftUI
import UIKit

@MainActor
final class DriveLogViewModel: ObservableObject {
    @Published private(set) var logs: [LogEntry] = []
    @Published private(set) var routes: [DriveRoute] = []
    @Published var filter: LogType? = nil { didSet { applyFilter() } }
    @Published var showDriveRoutes: Bool = false { didSet { applyFilter() } }
    @Published var editing: LogEntry? = nil
    @Published private(set) var tagOptions: [String] = []
    @Published var selectedTags: Set<String> = [] { didSet { applyFilter() } }
    @Published var showAllTags: Bool = false
    @Published private(set) var fullTagCount: Int = 0

    private let repository: LogRepository
    private let routeRepository: DriveRouteRepository
    private var all: [LogEntry] = []
    private(set) var allRoutes: [DriveRoute] = []

    init(repository: LogRepository, routeRepository: DriveRouteRepository? = nil) {
        self.repository = repository
        self.routeRepository = routeRepository ?? AppDI.shared.driveRouteRepository
        load()
    }

    func load() {
        if let list = try? repository.fetchAll() { 
            self.all = list
        }
        if let routeList = try? routeRepository.fetchAllRoutes() {
            self.allRoutes = routeList
        }
        applyFilter()
    }

    func create(type: LogType,
                detail: String,
                locationNote: String,
                scene: String,
                cause: String?,
                improvement: String?,
                rawTags: String,
                images: [UIImage] = [],
                audioFileName: String? = nil,
                transcript: String? = nil) {
        let tags = normalizeTags(rawTags)

        // 保存图片并获取文件名
        let photoFileNames = ImageStorageService.shared.saveImages(images)

        let entry = LogEntry(type: type,
                             locationNote: locationNote,
                             scene: scene,
                             detail: detail,
                             cause: type == .mistake ? (cause?.nilIfBlank) : nil,
                             improvement: type == .mistake ? (improvement?.nilIfBlank) : nil,
                             tags: tags,
                             photoLocalIds: photoFileNames,
                             audioFileName: audioFileName,
                             transcript: transcript)
        try? repository.add(entry)
        Task { @MainActor in
            AppDI.shared.tagSuggestionService.record(tags: tags)
        }
        load()
    }

    func delete(at offsets: IndexSet) {
        for index in offsets {
            let entry = logs[index]
            // 删除相关图片文件
            ImageStorageService.shared.deleteImages(fileNames: entry.photoLocalIds)
            // 删除相关音频文件
            if let audioFileName = entry.audioFileName {
                AudioStorageService.shared.deleteAudioFile(fileName: audioFileName)
            }
            try? repository.delete(entry)
        }
        load()
    }

    func deleteRoute(at offsets: IndexSet) {
        for index in offsets {
            let route = routes[index]
            try? routeRepository.deleteRoute(route)
        }
        load()
    }

    func deleteRoute(_ route: DriveRoute) {
        try? routeRepository.deleteRoute(route)
        load()
    }

    func beginEdit(_ entry: LogEntry) { editing = entry }

    func update(entry: LogEntry,
                type: LogType,
                detail: String,
                locationNote: String,
                scene: String,
                cause: String?,
                improvement: String?,
                rawTags: String,
                images: [UIImage],
                audioFileName: String?,
                transcript: String?) {
        let tags = normalizeTags(rawTags)

        // 删除旧图片
        ImageStorageService.shared.deleteImages(fileNames: entry.photoLocalIds)

        // 保存新图片
        let photoFileNames = ImageStorageService.shared.saveImages(images)

        // 注意：音频文件的处理已经在 LogEditorView 中完成，
        // 这里只需要更新文件名引用即可

        try? repository.update(entry) { e in
            e.type = type
            e.detail = detail
            e.locationNote = locationNote
            e.scene = scene
            e.cause = type == .mistake ? cause : nil
            e.improvement = type == .mistake ? improvement : nil
            e.tags = tags
            e.photoLocalIds = photoFileNames
            e.audioFileName = audioFileName
            e.transcript = transcript
        }
        Task { @MainActor in AppDI.shared.tagSuggestionService.record(tags: tags) }
        editing = nil
        load()
    }

    private func applyFilter() {
        if showDriveRoutes {
            // 显示驾驶记录
            routes = allRoutes.sorted { $0.startTime > $1.startTime }
            logs = []
        } else {
            // 显示日志记录
            var tmp = all
            if let f = filter { tmp = tmp.filter { $0.type == f } }
            if !selectedTags.isEmpty { tmp = tmp.filter { Set($0.tags).isSuperset(of: selectedTags) } }
            logs = tmp.sorted { $0.createdAt > $1.createdAt }
            routes = []
        }
        recomputeTags() // 更新候选
    }

    // MARK: - Helpers
    private func normalizeTags(_ raw: String) -> [String] {
        let parts = raw.split { ",#\n\t ".contains($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        return parts.filter { seen.insert($0).inserted }.prefix(8).map { String($0) } // 限制最多8个标签
    }

    func attachmentSummary(for entry: LogEntry) -> String? {
        let photoCount = entry.photoLocalIds.count
        let hasAudio = entry.audioFileName != nil
        if photoCount == 0 && !hasAudio { return nil }
        var parts: [String] = []
        if photoCount > 0 { parts.append("📷" + String(photoCount)) }
        if hasAudio { parts.append("🎤1") }
        return parts.joined(separator: " ")
    }

    func toggleMultiTag(_ tag: String) {
        if selectedTags.contains(tag) { selectedTags.remove(tag) } else { selectedTags.insert(tag) }
    }

    func clearAllTagFilters() {
        selectedTags.removeAll()
    }

    func toggleShowAllTags() {
        showAllTags.toggle()
        recomputeTags()
    }

    private func recomputeTags() {
        // 综合：出现频次（所有日志） + 最近使用（TagSuggestionService）
        var freq: [String: Int] = [:]
        for e in all { for t in e.tags { freq[t, default: 0] += 1 } }
        let suggestionFreq = AppDI.shared.tagSuggestionService.frequencySnapshot()
        // 合并：出现频次权重 1，最近使用额外加 1 分（或 suggestionFreq / 10 可调）
        var combined: [(String, Int, Int)] = [] // (tag, totalScore, appearCount)
        for (tag, appear) in freq {
            let recent = suggestionFreq[tag] ?? 0
            let score = appear * 10 + min(recent, 50) // 放大出现次数主导，叠加最近使用
            combined.append((tag, score, appear))
        }
        combined.sort { a, b in
            if a.1 == b.1 { return a.0 < b.0 }
            return a.1 > b.1
        }
    let fullList = combined.map { $0.0 }
    fullTagCount = fullList.count
    let limit = 30
    tagOptions = showAllTags ? fullList : Array(fullList.prefix(limit))
    }
}

private extension String {
    var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}
