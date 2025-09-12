import SwiftUI
import Charts

struct ChecklistPunchDetailView: View {
    let punch: ChecklistPunch
    @EnvironmentObject private var di: AppDI
    @State private var itemTitleMap: [UUID:String] = [:]
    @State private var weekStats: Stats = .empty
    @State private var monthStats: Stats = .empty
    @State private var period: Period = .week

    var body: some View {
        List {
            Section(header: Text("打卡详情")) {
                HStack {
                    Text("时间")
                    Spacer()
                    Text(format(date: punch.createdAt, dateStyle: .long, timeStyle: .short))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("类型")
                    Spacer()
                    Text(punch.mode == .pre ? "行前" : "行后").foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("项目")
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(titles(for: punch), id: \.self) { t in
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Image(systemName: "checkmark.circle")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(t)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }

            Section {
                Picker("周期", selection: $period) {
                    Text("本周").tag(Period.week)
                    Text("本月").tag(Period.month)
                }.pickerStyle(.segmented)

                if currentStats.topItems.isEmpty {
                    Text("无数据").foregroundStyle(.secondary)
                } else {
                    Chart(currentStats.topItems, id: \.0) { (title, count) in
                        BarMark(
                            x: .value("次数", count),
                            y: .value("项目", title)
                        )
                    }
                    .frame(height: 220)

                    ForEach(currentStats.topItems, id: \.0) { title, count in
                        HStack { Text(title); Spacer(); Text("\(count) 次").foregroundStyle(.secondary) }
                    }
                }
            } footer: {
                Text("按相同类型统计：\(punch.mode == .pre ? "行前" : "行后") · 共有 \((period == .week ? weekStats.totalPunches : monthStats.totalPunches)) 次")
            }
        }
        .navigationTitle("打卡详情")
        .onAppear(perform: load)
    }

    private func load() {
        let items = (try? di.checklistRepository.fetchItems(mode: nil)) ?? []
        itemTitleMap = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.title) })

        let all = (try? di.checklistRepository.fetchAllPunches(mode: punch.mode)) ?? []
        if let week = Calendar.current.dateInterval(of: .weekOfYear, for: punch.createdAt) {
            weekStats = aggregate(punches: all.filter { week.contains($0.createdAt) })
        }
        if let month = Calendar.current.dateInterval(of: .month, for: punch.createdAt) {
            monthStats = aggregate(punches: all.filter { month.contains($0.createdAt) })
        }
    }

    private func aggregate(punches: [ChecklistPunch]) -> Stats {
        var counter: [String:Int] = [:]
        for p in punches {
            for id in p.checkedItemIds { if let t = itemTitleMap[id] { counter[t, default: 0] += 1 } }
        }
        let sorted = counter.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value > rhs.value
        }
        return Stats(totalPunches: punches.count, topItems: Array(sorted.prefix(10)).map { ($0.key, $0.value) })
    }

    private func titles(for p: ChecklistPunch) -> [String] { p.checkedItemIds.compactMap { itemTitleMap[$0] } }
    private func format(date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateStyle = dateStyle; f.timeStyle = timeStyle
        return f.string(from: date)
    }

    struct Stats { let totalPunches: Int; let topItems: [(String, Int)]; static let empty = Stats(totalPunches: 0, topItems: []) }
    enum Period { case week, month }
    private var currentStats: Stats { period == .week ? weekStats : monthStats }
}

// 添加便利初始化器，支持从ChecklistPunchSummary创建
extension ChecklistPunchDetailView {
    init(punch: ChecklistPunchSummary) {
        // 创建一个临时的ChecklistPunch对象
        let checklistPunch = ChecklistPunch(
            id: punch.id,
            createdAt: punch.createdAt,
            mode: punch.mode,
            checkedItemIds: punch.checkedItemIds,
            isQuickComplete: punch.isQuickComplete,
            score: punch.score,
            locationNote: punch.locationNote
        )
        
        self.init(punch: checklistPunch)
    }
}

#Preview {
    NavigationStack {
        // 占位预览
        Text("选择一条记录")
    }
}