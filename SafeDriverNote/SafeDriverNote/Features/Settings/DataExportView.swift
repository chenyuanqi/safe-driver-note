import SwiftUI
import Foundation
import UIKit
import SwiftData

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI
    @State private var exportDrivingRoutes = true
    @State private var exportDrivingLogs = true
    @State private var exportChecklistRecords = true
    @State private var exportKnowledgeProgress = false
    @State private var exportFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var showingExportComplete = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var exportedFileURL: URL? = nil
    @State private var showingShareSheet = false

    // 数据统计
    @State private var routeCount = 0
    @State private var logCount = 0
    @State private var checklistCount = 0
    @State private var knowledgeCount = 0

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"
        case pdf = "PDF"

        var description: String {
            switch self {
            case .json: return "结构化数据格式，适合备份"
            case .csv: return "表格格式，可用Excel打开"
            case .pdf: return "PDF报告，适合打印分享"
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 导出说明
                    exportInfoSection

                    // 数据选择
                    dataSelectionSection

                    // 格式选择
                    formatSelectionSection

                    // 导出统计
                    exportStatsSection

                    // 导出按钮
                    exportButtonSection
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("导出数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadDataCounts()
            }
            .alert("导出完成", isPresented: $showingExportComplete) {
                Button("查看文件") {
                    showingExportComplete = false
                    if let url = exportedFileURL {
                        exportedFileURL = url
                        showingShareSheet = true
                    }
                }
                Button("关闭", role: .cancel) {
                    showingExportComplete = false
                }
            } message: {
                Text("数据已导出到“文件”App的应用目录。您也可以立即分享或保存到其他位置。")
            }
            .alert("导出失败", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                exportedFileURL = nil
            }) {
                if let url = exportedFileURL {
                    ShareSheet(activityItems: [url])
                } else {
                    Text("未找到导出文件")
                }
            }
        }
    }

    // MARK: - 导出说明
    private var exportInfoSection: some View {
        Card(backgroundColor: .brandInfo100, shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.bodyLarge)
                        .foregroundColor(.brandInfo500)

                    Text("数据导出说明")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("• 导出的数据包含您在应用中的所有记录")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)

                    Text("• 数据将以您选择的格式保存到文件app")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)

                    Text("• 导出过程中请保持网络连接")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)

                    Text("• 导出的数据仅供个人使用，请妥善保管")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - 数据选择
    private var dataSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("选择导出内容")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    dataCheckboxRow(
                        title: "驾驶路线记录",
                        subtitle: "包含起点、终点、时间、距离等信息",
                        isSelected: $exportDrivingRoutes
                    )

                    Divider()

                    dataCheckboxRow(
                        title: "驾驶日志",
                        subtitle: "您记录的驾驶心得、经验和改进建议",
                        isSelected: $exportDrivingLogs
                    )

                    Divider()

                    dataCheckboxRow(
                        title: "检查清单记录",
                        subtitle: "行前行后检查的完成记录和打分",
                        isSelected: $exportChecklistRecords
                    )

                    Divider()

                    dataCheckboxRow(
                        title: "知识学习进度",
                        subtitle: "安全知识的学习记录和标记状态",
                        isSelected: $exportKnowledgeProgress
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 格式选择
    private var formatSelectionSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("导出格式")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: 0) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Button(action: {
                            exportFormat = format
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text(format.rawValue)
                                        .font(.bodyLarge)
                                        .fontWeight(.medium)
                                        .foregroundColor(.brandSecondary900)

                                    Text(format.description)
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary500)
                                }

                                Spacer()

                                Image(systemName: exportFormat == format ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(exportFormat == format ? .brandPrimary500 : .brandSecondary300)
                            }
                            .padding(.vertical, Spacing.md)
                            .padding(.horizontal, Spacing.lg)
                        }
                        .buttonStyle(PlainButtonStyle())

                        if format != ExportFormat.allCases.last {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    // MARK: - 导出统计
    private var exportStatsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("导出预览")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: Spacing.md) {
                    if exportDrivingRoutes {
                        statRow(icon: "car", title: "驾驶路线", count: "\(routeCount)条记录")
                    }

                    if exportDrivingLogs {
                        statRow(icon: "list.bullet", title: "驾驶日志", count: "\(logCount)条记录")
                    }

                    if exportChecklistRecords {
                        statRow(icon: "checklist", title: "检查记录", count: "\(checklistCount)次检查")
                    }

                    if exportKnowledgeProgress {
                        statRow(icon: "book", title: "学习进度", count: "\(knowledgeCount)个知识点")
                    }

                    if !hasSelectedData {
                        Text("请至少选择一项数据进行导出")
                            .font(.body)
                            .foregroundColor(.brandSecondary500)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.lg)
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 导出按钮
    private var exportButtonSection: some View {
        Button(action: {
            performExport()
        }) {
            HStack {
                if isExporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                Text(isExporting ? "导出中..." : "开始导出")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(hasSelectedData ? Color.brandPrimary500 : Color.brandSecondary300)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(!hasSelectedData || isExporting)
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 计算属性
    private var hasSelectedData: Bool {
        exportDrivingRoutes || exportDrivingLogs || exportChecklistRecords || exportKnowledgeProgress
    }

    // MARK: - 辅助方法
    private func dataCheckboxRow(
        title: String,
        subtitle: String,
        isSelected: Binding<Bool>
    ) -> some View {
        Button(action: {
            isSelected.wrappedValue.toggle()
        }) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: isSelected.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected.wrappedValue ? .brandPrimary500 : .brandSecondary300)

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    Text(subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func statRow(icon: String, title: String, count: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.bodyMedium)
                .foregroundColor(.brandPrimary500)
                .frame(width: 20)

            Text(title)
                .font(.body)
                .foregroundColor(.brandSecondary700)

            Spacer()

            Text(count)
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)
        }
    }

    private func loadDataCounts() {
        Task {
            do {
                let counts = try await MainActor.run { () -> (Int, Int, Int, Int) in
                    let routes = try di.driveRouteRepository.fetchAllRoutes()
                    let logs = try di.logRepository.fetchAll()
                    let checklists = try di.checklistRepository.fetchAllPunches(mode: nil)
                    let knowledge = try di.knowledgeRepository.allCards()
                    return (routes.count, logs.count, checklists.count, knowledge.count)
                }

                await MainActor.run {
                    self.routeCount = counts.0
                    self.logCount = counts.1
                    self.checklistCount = counts.2
                    self.knowledgeCount = counts.3
                }
            } catch {
                await MainActor.run {
                    print("Failed to load data counts: \(error)")
                }
            }
        }
    }

    private func performExport() {
        guard hasSelectedData else { return }

        isExporting = true

        Task {
            do {
                let backup = try await buildBackupEnvelope()
                let fileName = "SafeDriverNote_Backup_\(formatDate(Date()))"
                let fileURL = try await saveExportData(backup, fileName: fileName, format: exportFormat)

                await MainActor.run {
                    self.isExporting = false
                    self.exportedFileURL = fileURL
                    self.showingExportComplete = true
                }

            } catch {
                await MainActor.run {
                    self.isExporting = false
                    if let backupError = error as? BackupError {
                        self.errorMessage = backupError.localizedDescription
                    } else {
                        self.errorMessage = "导出失败：\(error.localizedDescription)"
                    }
                    self.showingError = true
                }
            }
        }
    }

    private func buildBackupEnvelope() async throws -> BackupEnvelope {
        try await MainActor.run {
            guard let context = GlobalModelContext.context else { throw BackupError.contextUnavailable }

            var envelope = BackupEnvelope(
                metadata: BackupMetadata(
                    exportedAt: Date(),
                    appVersion: currentAppVersion()
                )
            )

            if exportDrivingRoutes {
                let routes = try context.fetch(FetchDescriptor<DriveRoute>())
                envelope.drivingRoutes = routes.map(DriveRouteBackup.init)
            }

            if exportDrivingLogs {
                let logs = try context.fetch(FetchDescriptor<LogEntry>())
                envelope.drivingLogs = logs.map(DrivingLogBackup.init)
            }

            if exportChecklistRecords {
                let records = try context.fetch(FetchDescriptor<ChecklistRecord>())
                envelope.checklistRecords = records.map(ChecklistRecordBackup.init)

                let items = try context.fetch(FetchDescriptor<ChecklistItem>())
                envelope.checklistItems = items.map(ChecklistItemBackup.init)

                let punches = try context.fetch(FetchDescriptor<ChecklistPunch>())
                envelope.checklistPunches = punches.map(ChecklistPunchBackup.init)
            }

            if exportKnowledgeProgress {
                let progresses = try context.fetch(FetchDescriptor<KnowledgeProgress>())
                envelope.knowledgeProgress = progresses.map(KnowledgeProgressBackup.init)

                let cards = try context.fetch(FetchDescriptor<KnowledgeCard>())
                envelope.knowledgeCards = cards.map(KnowledgeCardBackup.init)
            }

            let profiles = try context.fetch(FetchDescriptor<UserProfile>())
            envelope.userProfile = profiles.first.map(UserProfileBackup.init)

            return envelope
        }
    }

    private func saveExportData(_ data: BackupEnvelope, fileName: String, format: ExportFormat) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        switch format {
        case .json:
            let fileURL = documentsPath.appendingPathComponent("\(fileName).json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            do {
                let jsonData = try encoder.encode(data)
                try removeExistingFile(at: fileURL)
                try jsonData.write(to: fileURL)
                return fileURL
            } catch {
                throw BackupError.encodingFailed
            }

        case .csv:
            let fileURL = documentsPath.appendingPathComponent("\(fileName).csv")
            let csvContent = try generateCSVContent(from: data)
            try removeExistingFile(at: fileURL)
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL

        case .pdf:
            let fileURL = documentsPath.appendingPathComponent("\(fileName).pdf")
            let textContent = generateTextReport(from: data)
            try removeExistingFile(at: fileURL)
            try renderPDF(textContent: textContent, to: fileURL)
            return fileURL
        }
    }

    private func generateCSVContent(from backup: BackupEnvelope) throws -> String {
        var csvLines: [String] = []
        csvLines.append("数据类型,ID,标题/位置,详情,时间,附加信息")

        if let logs = backup.drivingLogs {
            for log in logs {
                let line = [
                    "驾驶日志",
                    log.id.uuidString,
                    sanitizeCSV(log.scene),
                    sanitizeCSV(log.detail),
                    iso8601String(from: log.createdAt),
                    sanitizeCSV(log.tags.joined(separator: ";"))
                ].joined(separator: ",")
                csvLines.append(line)
            }
        }

        if let routes = backup.drivingRoutes {
            for route in routes {
                let title = route.startLocation?.address ?? "行程"
                let detail = route.endLocation?.address ?? ""
                let info = "状态: \(route.status.rawValue)"
                let line = [
                    "驾驶路线",
                    route.id.uuidString,
                    sanitizeCSV(title),
                    sanitizeCSV(detail),
                    iso8601String(from: route.startTime),
                    sanitizeCSV(info)
                ].joined(separator: ",")
                csvLines.append(line)
            }
        }

        if let punches = backup.checklistPunches {
            for punch in punches {
                let line = [
                    "检查打卡",
                    punch.id.uuidString,
                    punch.mode.rawValue,
                    sanitizeCSV(punch.locationNote ?? ""),
                    iso8601String(from: punch.createdAt),
                    "得分: \(punch.score)"
                ].joined(separator: ",")
                csvLines.append(line)
            }
        }

        return csvLines.joined(separator: "\n")
    }

    private func generateTextReport(from backup: BackupEnvelope) -> String {
        var report = "=== 安全驾驶助手数据导出报告 ===\n"
        report += "导出时间：\(formatDate(Date()))\n"
        report += "应用版本：\(backup.metadata.appVersion)\n\n"

        if let routes = backup.drivingRoutes {
            report += "驾驶路线记录（\(routes.count)条）：\n"
            for route in routes {
                let start = route.startLocation?.address ?? "未知起点"
                let end = route.endLocation?.address ?? "未知终点"
                report += "• \(start) → \(end) [状态: \(route.status.displayName)]\n"
            }
            report += "\n"
        }

        if let logs = backup.drivingLogs {
            report += "驾驶日志（\(logs.count)条）：\n"
            for log in logs {
                report += "• [\(log.type == .success ? "成功" : "失误")] \(log.scene)：\(log.detail)\n"
            }
            report += "\n"
        }

        if let punches = backup.checklistPunches {
            report += "检查打卡（\(punches.count)次）：\n"
            for punch in punches {
                report += "• \(punch.mode == .pre ? "行前" : "行后")检查，得分 \(punch.score) 分\n"
            }
            report += "\n"
        }

        if let knowledge = backup.knowledgeProgress {
            report += "知识学习记录：已标记 \(knowledge.count) 个知识点。\n\n"
        }

        if let profile = backup.userProfile {
            report += "用户资料：\(profile.userName)，驾龄 \(profile.drivingYears) 年。\n"
        }

        return report
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: date)
    }

    private func iso8601String(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private func sanitizeCSV(_ value: String) -> String {
        var sanitized = value.replacingOccurrences(of: "\n", with: " ")
        sanitized = sanitized.replacingOccurrences(of: "\r", with: " ")
        sanitized = sanitized.replacingOccurrences(of: "\"", with: "\"\"")
        if sanitized.contains(",") {
            sanitized = "\"\(sanitized)\""
        }
        return sanitized
    }

    private func currentAppVersion() -> String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private func removeExistingFile(at url: URL) throws {
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    private func renderPDF(textContent: String, to url: URL) throws {
        let pageRect = CGRect(x: 0, y: 0, width: 595, height: 842)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        try renderer.writePDF(to: url) { context in
            context.beginPage()

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .left

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .paragraphStyle: paragraphStyle
            ]

            let textRect = pageRect.insetBy(dx: 32, dy: 32)
            textContent.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

#Preview {
    DataExportView()
        .environmentObject(AppDI.shared)
}
