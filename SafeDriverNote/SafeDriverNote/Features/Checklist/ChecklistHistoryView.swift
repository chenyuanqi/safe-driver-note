import SwiftUI

struct ChecklistHistoryView: View {
    @State private var mode: ChecklistViewModel.Mode = .pre
    @State private var grouped: [(date: Date, punches: [ChecklistPunch])] = []
    @EnvironmentObject private var di: AppDI

    var body: some View {
        List {
            Section { modePicker } footer: { Text("按日分组显示历史每次打卡") }
            ForEach(grouped, id: \.date) { section in
                Section(header: Text(sectionHeader(for: section.date))) {
                    ForEach(section.punches, id: \.id) { p in
                        NavigationLink(value: p) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(p.createdAt, format: Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "zh_CN")))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(titles(for: p).joined(separator: "、"))
                            }
                        }
                        .swipeActions {
                            Button(role: .destructive) { delete(p) } label: { Label("删除", systemImage: "trash") }
                        }
                    }
                }
            }
        }
        .navigationTitle("历史打卡")
        .navigationDestination(for: ChecklistPunch.self) { p in
            ChecklistPunchDetailView(punch: p).environmentObject(di)
        }
        .onAppear(perform: reload)
        .onChange(of: mode) { _, _ in reload() }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            Text("行前").tag(ChecklistViewModel.Mode.pre)
            Text("行后").tag(ChecklistViewModel.Mode.post)
        }.pickerStyle(.segmented)
    }

    private func reload() {
        let repo = di.checklistRepository
        let all = (try? repo.fetchAllPunches(mode: mode == .pre ? .pre : .post)) ?? []
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
    private func titles(for p: ChecklistPunch) -> [String] { p.checkedItemIds.compactMap { _titleMap[$0] } }
    private func sectionHeader(for date: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateStyle = .long; f.timeStyle = .none
        return f.string(from: date)
    }
    private func delete(_ p: ChecklistPunch) {
        try? di.checklistRepository.deletePunch(p)
        reload()
    }
}

#Preview {
    NavigationStack { ChecklistHistoryView().environmentObject(AppDI.shared) }
}

