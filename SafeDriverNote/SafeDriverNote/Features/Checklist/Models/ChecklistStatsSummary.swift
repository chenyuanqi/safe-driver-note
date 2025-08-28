import Foundation

/// 打卡统计汇总模型
struct ChecklistStatsSummary {
    let totalPunches: Int           // 总打卡次数
    let totalDays: Int              // 打卡总天数
    let averageScore: Double        // 平均得分
    let completionRate: Double      // 完成率
    let currentStreak: Int          // 当前连续天数
    let mode: ChecklistMode         // 行前或行后
    
    var formattedAverageScore: String {
        return String(format: "%.1f", averageScore)
    }
    
    var formattedCompletionRate: String {
        return String(format: "%.1f%%", completionRate * 100)
    }
}

extension ChecklistStatsSummary {
    /// 从打卡记录列表计算统计汇总
    static func calculate(from punches: [ChecklistPunch], mode: ChecklistMode) -> ChecklistStatsSummary {
        let filteredPunches = punches.filter { $0.mode == mode }
        
        let totalPunches = filteredPunches.count
        let totalScore = filteredPunches.reduce(0) { $0 + $1.score }
        let averageScore = totalPunches > 0 ? Double(totalScore) / Double(totalPunches) : 0.0
        
        // 计算打卡天数
        let uniqueDays = Set(filteredPunches.map { 
            Calendar.current.startOfDay(for: $0.createdAt) 
        })
        let totalDays = uniqueDays.count
        
        // 计算完成率（假设满分为100）
        let completionRate = averageScore / 100.0
        
        // 计算当前连续天数
        let currentStreak = calculateCurrentStreak(from: filteredPunches)
        
        return ChecklistStatsSummary(
            totalPunches: totalPunches,
            totalDays: totalDays,
            averageScore: averageScore,
            completionRate: completionRate,
            currentStreak: currentStreak,
            mode: mode
        )
    }
    
    /// 计算当前连续打卡天数
    private static func calculateCurrentStreak(from punches: [ChecklistPunch]) -> Int {
        guard !punches.isEmpty else { return 0 }
        
        // 按天分组
        let groupedByDay = Dictionary(grouping: punches) { 
            Calendar.current.startOfDay(for: $0.createdAt) 
        }
        
        let sortedDays = groupedByDay.keys.sorted(by: >)
        guard !sortedDays.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 检查是否今天有打卡
        var currentStreak = 0
        var checkDate = today
        
        for day in sortedDays {
            if calendar.isDate(day, inSameDayAs: checkDate) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if day < checkDate {
                // 有间隔，停止计算
                break
            }
        }
        
        return currentStreak
    }
}