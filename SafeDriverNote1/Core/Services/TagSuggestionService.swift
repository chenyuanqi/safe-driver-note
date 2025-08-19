import Foundation

/// 维护常用标签（本地统计 + 最近使用 + 频次排序）
@MainActor
final class TagSuggestionService: ObservableObject {
    static let shared = TagSuggestionService()

    @Published private(set) var topTags: [String] = []
    private var freq: [String: Int] = [:]
    private let maxStore = 100
    private let userDefaultsKey = "tag_suggestion_freq_v1"

    private init() { load() }

    func record(tags: [String]) {
        guard !tags.isEmpty else { return }
        var changed = false
        for t in tags where !t.isEmpty { freq[t, default: 0] += 1; changed = true }
        if changed { trimIfNeeded(); persist(); recomputeTop() }
    }

    func suggestions(prefix: String? = nil, limit: Int = 12, excluding existing: [String] = []) -> [String] {
        let excludeSet = Set(existing)
        let base = topTags.filter { !excludeSet.contains($0) }
        guard let p = prefix?.lowercased(), !p.isEmpty else { return Array(base.prefix(limit)) }
        let starts = base.filter { $0.hasPrefix(p) }
        if starts.count >= limit { return Array(starts.prefix(limit)) }
        let contains = base.filter { $0.contains(p) && !starts.contains($0) }
        return Array((starts + contains).prefix(limit))
    }

    // MARK: - Private
    private func recomputeTop() {
        topTags = freq.sorted { (a, b) in
            if a.value == b.value { return a.key < b.key }
            return a.value > b.value
        }.prefix(50).map { $0.key }
    }

    private func trimIfNeeded() {
        if freq.count > maxStore {
            let sorted = freq.sorted { $0.value < $1.value }
            let overflow = freq.count - maxStore
            for (k, _) in sorted.prefix(overflow) { freq.removeValue(forKey: k) }
        }
    }

    private func persist() { UserDefaults.standard.set(freq, forKey: userDefaultsKey) }

    private func load() {
        if let dict = UserDefaults.standard.dictionary(forKey: userDefaultsKey) as? [String: Int] { freq = dict }
        recomputeTop()
    }

    // 提供频次快照用于外部权重计算
    func frequencySnapshot() -> [String: Int] { freq }
    func frequency(for tag: String) -> Int { freq[tag] ?? 0 }
}
