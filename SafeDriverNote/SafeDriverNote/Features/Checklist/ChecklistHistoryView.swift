import SwiftUI

struct ChecklistHistoryView: View {
    @State private var mode: ChecklistViewModel.Mode = .pre
    @State private var grouped: [(date: Date, punches: [ChecklistPunch])] = []
    @State private var stats: ChecklistStatsSummary?
    @State private var showAllDetails = false
    @EnvironmentObject private var di: AppDI

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // 模式选择器
                VStack(spacing: Spacing.md) {
                    modePicker
                    Text("按日分组显示历史每次打卡")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }
                .padding(.horizontal, Spacing.lg)
                
                // 统计汇总
                if let stats = stats {
                    ChecklistStatsSummaryView(stats: stats)
                        .padding(.horizontal, Spacing.lg)
                }
                
                // 打卡明细
                recentRecordsSection
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.brandSecondary50)
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
        let currentMode: ChecklistMode = mode == .pre ? .pre : .post
        let all = (try? repo.fetchAllPunches(mode: currentMode)) ?? []
        let items = (try? repo.fetchItems(mode: nil)) ?? []
        let titleMap: [UUID:String] = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.title) })
        
        // 计算统计汇总
        stats = ChecklistStatsSummary.calculate(from: all, mode: currentMode)
        
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
    
    private var recentRecordsSection: some View {
        VStack(spacing: Spacing.md) {
            HStack {
                Text("最近打卡记录")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                
                Spacer()
                
                if grouped.flatMap({ $0.punches }).count > 3 {
                    NavigationLink("查看全部") {
                        ChecklistAllHistoryView(mode: mode)
                            .environmentObject(di)
                    }
                    .font(.bodySmall)
                    .foregroundColor(.brandPrimary500)
                }
            }
            .padding(.horizontal, Spacing.lg)
            
            if grouped.isEmpty {
                emptyStateView
            } else {
                recentRecordsList
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.largeTitle)
                .foregroundColor(.brandSecondary300)
            
            Text("暂无打卡记录")
                .font(.bodyMedium)
                .foregroundColor(.brandSecondary500)
            
            Text("完成检查后记录会显示在这里")
                .font(.bodySmall)
                .foregroundColor(.brandSecondary400)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
        .padding(.horizontal, Spacing.lg)
        .background(Color.white)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        .padding(.horizontal, Spacing.lg)
    }
    
    private var recentRecordsList: some View {
        VStack(spacing: Spacing.sm) {
            let recentPunches = Array(grouped.flatMap { $0.punches }.prefix(3))
            
            ForEach(recentPunches, id: \.id) { punch in
                NavigationLink(value: punch) {
                    recentRecordRow(punch: punch)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.lg)
    }
    
    private func recentRecordRow(punch: ChecklistPunch) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(punch.createdAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened).locale(Locale(identifier: "zh_CN")))
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
                
                Image(systemName: punch.mode == .pre ? "car.fill" : "parkingsign.circle.fill")
                    .font(.title3)
                    .foregroundColor(punch.mode == .pre ? .brandInfo500 : .brandWarning500)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(punch.mode == .pre ? "行前检查" : "行后检查")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                    
                    if punch.isQuickComplete {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.brandWarning500)
                    }
                    
                    Spacer()
                    
                    Text("\(punch.score)分")
                        .font(.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSuccess500)
                }
                
                if !punch.checkedItemIds.isEmpty {
                    Text(titles(for: punch).joined(separator: "、"))
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                        .lineLimit(2)
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.brandSecondary400)
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    }
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

