import SwiftUI

struct CalendarView: View {
    let logs: [LogEntry]
    let routes: [DriveRoute]
    @State private var selectedDate = Date()
    @State private var currentMonth = Date()

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "zh_CN")
        return cal
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // 月份导航
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.body)
                        .foregroundColor(.brandPrimary500)
                }

                Spacer()

                Text(monthYearString)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.body)
                        .foregroundColor(.brandPrimary500)
                }
            }
            .padding(.horizontal, Spacing.lg)

            // 星期标题
            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary500)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Spacing.md)

            // 日期网格
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: Spacing.sm) {
                ForEach(daysInMonth, id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            logs: logsForDate(date),
                            routes: routesForDate(date),
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isToday: calendar.isDateInToday(date)
                        ) {
                            selectedDate = date
                        }
                    } else {
                        Color.clear
                            .frame(height: 50)
                    }
                }
            }
            .padding(.horizontal, Spacing.md)

            // 选中日期的详情
            if !logsForDate(selectedDate).isEmpty || !routesForDate(selectedDate).isEmpty {
                selectedDateDetails
            }
        }
        .padding(.vertical, Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
    }

    // MARK: - Day Cell
    struct DayCell: View {
        let date: Date
        let logs: [LogEntry]
        let routes: [DriveRoute]
        let isSelected: Bool
        let isToday: Bool
        let onTap: () -> Void

        var body: some View {
            VStack(spacing: 4) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(textColor)

                // 活动指示器
                HStack(spacing: 2) {
                    if !logs.isEmpty {
                        Circle()
                            .fill(logsHaveMistakes ? Color.brandDanger500 : Color.brandPrimary500)
                            .frame(width: 6, height: 6)
                    }
                    if !routes.isEmpty {
                        Circle()
                            .fill(Color.brandInfo500)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .cornerRadius(CornerRadius.sm)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.sm)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 0)
            )
            .onTapGesture(perform: onTap)
        }

        private var textColor: Color {
            if isSelected {
                return .brandPrimary500
            } else if isToday {
                return .brandPrimary700
            } else {
                return .brandSecondary900
            }
        }

        private var backgroundColor: Color {
            if isSelected {
                return Color.brandPrimary100
            } else if isToday {
                return Color.brandPrimary50
            } else if !logs.isEmpty || !routes.isEmpty {
                return Color.brandSecondary50
            } else {
                return Color.clear
            }
        }

        private var borderColor: Color {
            isSelected ? Color.brandPrimary500 : Color.clear
        }

        private var logsHaveMistakes: Bool {
            logs.contains { $0.type == .mistake }
        }
    }

    // MARK: - Selected Date Details
    private var selectedDateDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(dateFormatter.string(from: selectedDate))
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.horizontal, Spacing.lg)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    // 日志统计
                    if !logsForDate(selectedDate).isEmpty {
                        MiniStatCard(
                            icon: "doc.text",
                            title: "日志",
                            value: "\(logsForDate(selectedDate).count)",
                            color: .brandPrimary500
                        )

                        let mistakes = logsForDate(selectedDate).filter { $0.type == .mistake }.count
                        if mistakes > 0 {
                            MiniStatCard(
                                icon: "exclamationmark.triangle",
                                title: "失误",
                                value: "\(mistakes)",
                                color: .brandDanger500
                            )
                        }
                    }

                    // 行驶记录统计
                    if !routesForDate(selectedDate).isEmpty {
                        MiniStatCard(
                            icon: "car",
                            title: "行程",
                            value: "\(routesForDate(selectedDate).count)",
                            color: .brandInfo500
                        )

                        let totalDistance = routesForDate(selectedDate).compactMap { $0.distance }.reduce(0, +)
                        if totalDistance > 0 {
                            MiniStatCard(
                                icon: "road.lanes",
                                title: "里程",
                                value: formatDistance(totalDistance),
                                color: .brandWarning500
                            )
                        }
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }
        }
        .padding(.top, Spacing.md)
    }

    // MARK: - Mini Stat Card
    struct MiniStatCard: View {
        let icon: String
        let title: String
        let value: String
        let color: Color

        var body: some View {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)
                    Text(value)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)
                }
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(color.opacity(0.1))
            .cornerRadius(CornerRadius.md)
        }
    }

    // MARK: - Helper Methods
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月"
        return formatter.string(from: currentMonth)
    }

    private var weekdaySymbols: [String] {
        ["日", "一", "二", "三", "四", "五", "六"]
    }

    private var daysInMonth: [Date?] {
        guard let monthRange = calendar.range(of: .day, in: .month, for: currentMonth),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: firstOfMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in monthRange {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                days.append(date)
            }
        }

        // 填充到7的倍数
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    private func logsForDate(_ date: Date) -> [LogEntry] {
        logs.filter { calendar.isDate($0.createdAt, inSameDayAs: date) }
    }

    private func routesForDate(_ date: Date) -> [DriveRoute] {
        routes.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1fkm", distance / 1000)
        } else {
            return String(format: "%.0fm", distance)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter
    }
}