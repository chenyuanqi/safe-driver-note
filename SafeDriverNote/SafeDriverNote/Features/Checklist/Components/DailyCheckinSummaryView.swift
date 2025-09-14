import SwiftUI

struct DailyCheckinSummaryView: View {
    let summary: DailyCheckinSummary
    let items: [ChecklistItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            headerSection
            
            if summary.prePunches.isEmpty && summary.postPunches.isEmpty {
                emptyStateView
            } else {
                recordsList
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("今日打卡记录")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                
                Text(summary.completionStatus)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary600)
            }
            
            Spacer()
            
            if summary.totalScore > 0 {
                VStack(alignment: .trailing, spacing: Spacing.xs) {
                    Text("总分")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                    
                    Text("\(summary.totalScore)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.brandPrimary500)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.brandSecondary300)
            
            Text("今日还未进行任何检查")
                .font(.bodyMedium)
                .foregroundColor(.brandSecondary500)
            
            Text("点击上方打卡按钮开始检查")
                .font(.bodySmall)
                .foregroundColor(.brandSecondary400)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.xl)
    }
    
    private var recordsList: some View {
        LazyVStack(spacing: Spacing.md) {
            // 合并所有打卡记录并按时间倒序排列
            let allPunches = (summary.prePunches + summary.postPunches).sorted { $0.createdAt > $1.createdAt }
            
            ForEach(allPunches, id: \.id) { punch in
                NavigationLink(destination: ChecklistPunchDetailView(punch: punch)) {
                    checkinRecordRow(punch: punch, mode: punch.mode)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .slide),
                    removal: .opacity
                ))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: summary.prePunches.count + summary.postPunches.count)
    }
    
    private func checkinRecordRow(punch: ChecklistPunchSummary, mode: ChecklistMode) -> some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(DateFormatter.timeOnly.string(from: punch.createdAt))
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
                
                Image(systemName: mode == .pre ? "car" : "parkingsign.circle")
                    .font(.title3)
                    .foregroundColor(mode == .pre ? .brandInfo500 : .brandWarning500)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(mode == .pre ? "行前检查" : "行后检查")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                    
                    if punch.isQuickComplete {
                        Image(systemName: "bolt.fill")
                            .font(.caption)
                            .foregroundColor(.brandWarning500)
                    }
                    
                    Spacer()
                    
                    Text("完成 \(punch.checkedItemIds.count)/\(itemsCount(for: mode)) 项")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary600)
                }
                
                if !punch.checkedItemIds.isEmpty {
                    Text(itemTitles(for: punch).joined(separator: "、"))
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
            
            VStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.brandSuccess500)
                
                Text("\(punch.score)分")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSuccess700)
            }
        }
        .padding(Spacing.md)
        .background(Color.brandSecondary25)
        .cornerRadius(CornerRadius.md)
    }
    
    private func itemsCount(for mode: ChecklistMode) -> Int {
        return items.filter { $0.mode == mode }.count
    }
    
    private func itemTitles(for punch: ChecklistPunchSummary) -> [String] {
        let itemDict = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0.title) })
        return punch.checkedItemIds.compactMap { itemDict[$0] }
    }
}

extension DateFormatter {
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

#Preview {
    let sampleItems = [
        ChecklistItem(title: "胎压检查", mode: .pre),
        ChecklistItem(title: "灯光检查", mode: .pre),
        ChecklistItem(title: "手刹检查", mode: .post)
    ]
    
    let sampleSummary = DailyCheckinSummary(
        date: Date(),
        prePunches: [
            ChecklistPunchSummary(
                id: UUID(),
                createdAt: Date().addingTimeInterval(-3600), // 1小时前
                mode: .pre,
                checkedItemIds: [sampleItems[0].id, sampleItems[1].id],
                isQuickComplete: true,
                score: 100,
                locationNote: "测试位置"
            )
        ],
        postPunches: [
            ChecklistPunchSummary(
                id: UUID(),
                createdAt: Date(), // 现在
                mode: .post,
                checkedItemIds: [sampleItems[2].id],
                isQuickComplete: false,
                score: 80,
                locationNote: "停车场"
            )
        ]
    )
    
    NavigationStack {
        DailyCheckinSummaryView(summary: sampleSummary, items: sampleItems)
            .padding()
    }
}