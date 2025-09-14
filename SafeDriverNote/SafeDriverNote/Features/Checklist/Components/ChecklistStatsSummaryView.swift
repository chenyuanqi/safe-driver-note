import SwiftUI

struct ChecklistStatsSummaryView: View {
    let stats: ChecklistStatsSummary
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            headerSection
            statsGrid
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("打卡统计")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                
                Text(stats.mode == .pre ? "行前检查汇总" : "行后检查汇总")
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary600)
            }
            
            Spacer()
            
            Image(systemName: stats.mode == .pre ? "car.fill" : "parkingsign.circle.fill")
                .font(.title2)
                .foregroundColor(stats.mode == .pre ? .brandInfo500 : .brandWarning500)
        }
    }
    
    private var statsGrid: some View {
        VStack(spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                statCard(
                    title: "总次数",
                    value: "\(stats.totalPunches)",
                    subtitle: "次打卡",
                    color: .brandPrimary500
                )
                
                statCard(
                    title: "打卡天数",
                    value: "\(stats.totalDays)",
                    subtitle: "天",
                    color: .brandSuccess500
                )
            }
            
            HStack(spacing: Spacing.md) {
                statCard(
                    title: "平均得分",
                    value: stats.formattedAverageScore,
                    subtitle: "分",
                    color: .brandInfo500
                )
                
                statCard(
                    title: "连续天数",
                    value: "\(stats.currentStreak)",
                    subtitle: "天",
                    color: .brandWarning500
                )
            }
        }
    }
    
    private func statCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: Spacing.xs) {
            Text(title)
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.brandSecondary400)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.md)
        .background(Color.brandSecondary25)
        .cornerRadius(CornerRadius.md)
    }
}

#Preview {
    let sampleStats = ChecklistStatsSummary(
        totalPunches: 45,
        totalDays: 23,
        averageScore: 87.5,
        completionRate: 0.875,
        currentStreak: 7,
        mode: .pre
    )
    
    ChecklistStatsSummaryView(stats: sampleStats)
        .padding()
        .background(Color.brandSecondary50)
}