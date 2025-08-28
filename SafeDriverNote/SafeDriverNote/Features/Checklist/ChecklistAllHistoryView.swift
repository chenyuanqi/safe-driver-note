import SwiftUI

struct ChecklistAllHistoryView: View {
    let mode: ChecklistViewModel.Mode
    @State private var grouped: [(date: Date, punches: [ChecklistPunch])] = []
    @EnvironmentObject private var di: AppDI
    
    var body: some View {
        List {
            ForEach(grouped, id: \.date) { section in
                Section(header: Text(sectionHeader(for: section.date))) {
                    ForEach(section.punches, id: \.id) { punch in
                        NavigationLink(value: punch) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(punch.createdAt, format: Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "zh_CN")))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(titles(for: punch).joined(separator: "、"))
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { delete(punch) } 
                            label: { Label("删除", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .navigationTitle("全部打卡记录")
        .navigationDestination(for: ChecklistPunch.self) { punch in
            ChecklistPunchDetailView(punch: punch).environmentObject(di)
        }
        .onAppear(perform: reload)
    }
    
    private func reload() {
        let repo = di.checklistRepository
        let currentMode: ChecklistMode = mode == .pre ? .pre : .post
        let all = (try? repo.fetchAllPunches(mode: currentMode)) ?? []
        let items = (try? repo.fetchItems(mode: nil)) ?? []
        let titleMap: [UUID:String] = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.title) })
        
        // 分组到天
        let groupedByDay = Dictionary(grouping: all) { Calendar.current.startOfDay(for: $0.createdAt) }
        let pairs = groupedByDay.map { (key: Date, value: [ChecklistPunch]) in
            (date: key, punches: value.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.date > $1.date }
        grouped = pairs
        self._titleMap = titleMap
    }
    
    // 缓存标题映射
    @State private var _titleMap: [UUID:String] = [:]
    private func titles(for punch: ChecklistPunch) -> [String] { 
        punch.checkedItemIds.compactMap { _titleMap[$0] } 
    }
    
    private func sectionHeader(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func delete(_ punch: ChecklistPunch) {
        try? di.checklistRepository.deletePunch(punch)
        reload()
    }
}

#Preview {
    NavigationStack { 
        ChecklistAllHistoryView(mode: .pre)
            .environmentObject(AppDI.shared) 
    }
}