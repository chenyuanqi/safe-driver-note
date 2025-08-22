import SwiftUI

struct LogStatsView: View {
    let logs: [LogEntry]

    // MARK: - Derived
    private var monthLogs: [LogEntry] {
        let cal = Calendar(identifier: .gregorian)
        guard let start = cal.date(from: cal.dateComponents([.year, .month], from: Date())) else { return [] }
        return logs.filter { $0.createdAt >= start }
    }
    private var monthTotal: Int { monthLogs.count }
    private var monthMistakes: Int { monthLogs.filter { $0.type == .mistake }.count }
    private var monthSuccess: Int { monthLogs.filter { $0.type == .success }.count }
    private var improvementRate: Double {
        guard monthTotal > 0 else { return 0 }
        return Double(monthSuccess) / Double(monthTotal)
    }
    private var improvementRateText: String { monthTotal == 0 ? "--%" : String(format: "%.0f%%", improvementRate * 100) }

    private var recentMonths: [(label: String, total: Int, mistakes: Int, success: Int)] {
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let monthsBack = (0..<6).compactMap { off -> Date? in cal.date(byAdding: .month, value: -off, to: now) }
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.dateFormat = "M月"
        return monthsBack.reversed().map { m in
            let start = cal.date(from: cal.dateComponents([.year, .month], from: m))!
            let end = cal.date(byAdding: DateComponents(month: 1, day: 0), to: start)!
            let items = logs.filter { $0.createdAt >= start && $0.createdAt < end }
            let total = items.count
            let mistakes = items.filter { $0.type == .mistake }.count
            let success = items.filter { $0.type == .success }.count
            return (df.string(from: start), total, mistakes, success)
        }
    }

    private var sceneDistribution: [(scene: String, count: Int)] {
        let dict = Dictionary(grouping: logs) { ($0.scene.isEmpty ? "未填写场景" : $0.scene) }
            .mapValues { $0.count }
        return Array(
            dict.map { ($0.key, $0.value) }
                .sorted { $0.count > $1.count }
                .prefix(5)
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    statCard(title: "本月总次数", value: "\(monthTotal)", color: .blue)
                    statCard(title: "本月失误", value: "\(monthMistakes)", color: .red)
                    statCard(title: "改进率", value: improvementRateText, color: .green)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("失误趋势（近6个月）")
                        .font(.headline)
                    barChart(data: recentMonths.map { ($0.label, $0.mistakes) }, accent: .red)
                        .frame(height: 140)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 12) {
                    Text("场景分布（Top 5）")
                        .font(.headline)
                    vBarList(items: sceneDistribution)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding()
        }
        .navigationTitle("数据统计")
    }

    // MARK: - Components
    private func statCard(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func barChart(data: [(String, Int)], accent: Color) -> some View {
        GeometryReader { geo in
            let maxV = max(data.map { $0.1 }.max() ?? 1, 1)
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(Array(data.enumerated()), id: \.offset) { _, item in
                    VStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(accent.opacity(0.8))
                            .frame(height: CGFloat(item.1) / CGFloat(maxV) * (geo.size.height - 24))
                        Text(item.0)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func vBarList(items: [(scene: String, count: Int)]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            let total = max(items.map { $0.count }.reduce(0, +), 1)
            ForEach(Array(items.enumerated()), id: \.offset) { _, row in
                HStack(alignment: .center, spacing: 8) {
                    Text(row.scene)
                        .font(.subheadline)
                        .lineLimit(1)
                        .frame(width: 96, alignment: .leading)
                    GeometryReader { geo in
                        let w = geo.size.width
                        let ratio = CGFloat(row.count) / CGFloat(total)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.2))
                            .frame(width: max(8, w * ratio), height: 10, alignment: .leading)
                    }
                    .frame(height: 10)
                    Text("\(row.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    let sample: [LogEntry] = []
    return NavigationStack { LogStatsView(logs: sample) }
}