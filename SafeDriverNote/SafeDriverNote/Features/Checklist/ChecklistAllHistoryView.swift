import SwiftUI

struct ChecklistAllHistoryView: View {
    let mode: ChecklistViewModel.Mode
    @State private var grouped: [(date: Date, punches: [ChecklistPunch])] = []
    @EnvironmentObject private var di: AppDI
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.md) {
                ForEach(grouped, id: \.date) { section in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        // 日期头部
                        HStack {
                            Text(sectionHeader(for: section.date))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                            Spacer()
                        }
                        .padding(.horizontal, Spacing.lg)
                        
                        // 打卡记录列表
                        VStack(spacing: Spacing.sm) {
                            ForEach(section.punches, id: \.id) { punch in
                                NavigationLink(value: punch) {
                                    recordRow(punch: punch)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
            }
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.brandSecondary50)
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
    
    // MARK: - 记录样式组件
    private func recordRow(punch: ChecklistPunch) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(formatDateTime(punch.createdAt))
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
                
                // 显示位置信息
                if let locationNote = punch.locationNote, !locationNote.isEmpty {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption2)
                            .foregroundColor(.brandInfo500)
                        
                        Text(locationNote)
                            .font(.caption)
                            .foregroundColor(.brandSecondary400)
                            .lineLimit(1)
                    }
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
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy 年 M 月 d日 HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack { 
        ChecklistAllHistoryView(mode: .pre)
            .environmentObject(AppDI.shared) 
    }
}