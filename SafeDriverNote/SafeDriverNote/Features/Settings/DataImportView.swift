import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI

    @State private var selectedFileName: String?
    @State private var backupEnvelope: BackupEnvelope?
    @State private var importSummary: BackupSummary?
    @State private var importOptions = ImportOptions()
    @State private var isShowingImporter = false
    @State private var isImporting = false
    @State private var showingSuccess = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    infoSection
                    filePickerSection

                    if let summary = importSummary {
                        summarySection(summary)
                        importToggleSection(summary)
                    }

                    importButtonSection
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("导入数据")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .fileImporter(isPresented: $isShowingImporter, allowedContentTypes: [.json]) { result in
                handleFileSelection(result: result)
            }
            .alert("导入完成", isPresented: $showingSuccess) {
                Button("完成") {
                    showingSuccess = false
                    dismiss()
                }
            } message: {
                Text("数据已成功恢复，建议返回首页查看最新内容。")
            }
            .alert("导入失败", isPresented: $showingError) {
                Button("确定") { showingError = false }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Sections
    private var infoSection: some View {
        Card(backgroundColor: .brandInfo100, shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Image(systemName: "archivebox")
                        .font(.bodyLarge)
                        .foregroundColor(.brandInfo500)
                    Text("如何导入备份")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    infoBullet("仅支持从本应用导出的 JSON 备份文件。")
                    infoBullet("导入会覆盖所选数据类型，请提前备份重要信息。")
                    infoBullet("如果备份包含语音、照片，请自行确保相关文件已另行保存。")
                }
            }
            .padding(Spacing.lg)
        }
    }

    private func infoBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.caption)
                .foregroundColor(.brandInfo500)
            Text(text)
                .font(.body)
                .foregroundColor(.brandSecondary700)
        }
    }

    private var filePickerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("选择备份文件")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Button(action: { isShowingImporter = true }) {
                        HStack {
                            Image(systemName: "doc.badge.plus")
                                .font(.title3)
                                .foregroundColor(.brandPrimary500)

                            Text("从“文件”App 选择")
                                .font(.bodyLarge)
                                .fontWeight(.medium)
                                .foregroundColor(.brandPrimary600)

                            Spacer()
                        }
                        .padding(.vertical, Spacing.md)
                        .padding(.horizontal, Spacing.lg)
                        .background(Color.brandPrimary50)
                        .cornerRadius(CornerRadius.md)
                    }
                    .buttonStyle(PlainButtonStyle())

                    if let fileName = selectedFileName {
                        HStack(alignment: .top, spacing: Spacing.md) {
                            Image(systemName: "doc.text")
                                .font(.body)
                                .foregroundColor(.brandSecondary500)
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(fileName)
                                    .font(.body)
                                    .foregroundColor(.brandSecondary900)
                                if let summary = importSummary {
                                    Text("备份时间：\(summary.exportedAtFormatted)")
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary500)
                                }
                            }
                            Spacer()
                        }
                    } else {
                        Text("尚未选择备份文件")
                            .font(.body)
                            .foregroundColor(.brandSecondary500)
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    private func summarySection(_ summary: BackupSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("备份内容概览")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    summaryRow(icon: "car", title: "驾驶路线", value: "\(summary.routeCount) 条")
                    summaryRow(icon: "list.bullet", title: "驾驶日志", value: "\(summary.logCount) 条")
                    summaryRow(icon: "checkmark.circle", title: "检查打卡", value: "\(summary.checklistPunchCount) 次")
                    summaryRow(icon: "square.stack.3d.up", title: "检查记录", value: "\(summary.checklistRecordCount) 天")
                    summaryRow(icon: "doc.badge.gearshape", title: "自定义检查项", value: "\(summary.checklistItemCount) 项")
                    summaryRow(icon: "book", title: "学习进度", value: "\(summary.knowledgeProgressCount) 条")
                    summaryRow(icon: "person.crop.circle", title: "用户资料", value: summary.hasUserProfile ? "包含" : "无")
                }
                .padding(Spacing.lg)
            }
        }
    }

    private func importToggleSection(_ summary: BackupSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("选择需要恢复的数据")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: Spacing.md) {
                    importToggle(
                        title: "驾驶路线",
                        subtitle: "恢复驾驶时间、路线等记录",
                        isOn: $importOptions.importRoutes,
                        available: summary.routeCount > 0
                    )

                    Divider()

                    importToggle(
                        title: "驾驶日志",
                        subtitle: "恢复所有日志、标签与语音转写",
                        isOn: $importOptions.importLogs,
                        available: summary.logCount > 0
                    )

                    Divider()

                    importToggle(
                        title: "检查数据",
                        subtitle: "包含每日记录、自定义项目与打卡清单",
                        isOn: $importOptions.importChecklist,
                        available: summary.hasChecklistData
                    )

                    Divider()

                    importToggle(
                        title: "学习进度",
                        subtitle: "恢复知识卡片的掌握状态",
                        isOn: $importOptions.importKnowledge,
                        available: summary.knowledgeProgressCount > 0
                    )

                    Divider()

                    importToggle(
                        title: "用户资料",
                        subtitle: "恢复昵称、驾龄等个人设置",
                        isOn: $importOptions.importUserProfile,
                        available: summary.hasUserProfile
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    private func importToggle(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        available: Bool
    ) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
            }
        }
        .disabled(!available)
        .opacity(available ? 1.0 : 0.4)
        .toggleStyle(SwitchToggleStyle(tint: .brandPrimary500))
    }

    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.brandSecondary500)
                .frame(width: 24)

            Text(title)
                .font(.body)
                .foregroundColor(.brandSecondary700)

            Spacer()

            Text(value)
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)
        }
    }

    private var importButtonSection: some View {
        Button(action: executeImport) {
            HStack {
                if isImporting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                Text(isImporting ? "导入中..." : "开始导入")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(canImport ? Color.brandPrimary500 : Color.brandSecondary300)
            .foregroundColor(.white)
            .cornerRadius(CornerRadius.md)
        }
        .disabled(!canImport)
        .buttonStyle(PlainButtonStyle())
    }

    private var canImport: Bool {
        guard backupEnvelope != nil else { return false }
        guard importOptions.hasSelection else { return false }
        return !isImporting
    }

    // MARK: - File Handling
    private func handleFileSelection(result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            do {
                try loadBackup(from: url)
            } catch {
                errorMessage = (error as? BackupError)?.localizedDescription ?? error.localizedDescription
                showingError = true
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showingError = true
        }
    }

    private func loadBackup(from url: URL) throws {
        let securityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if securityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.invalidFile
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let envelope: BackupEnvelope
        do {
            envelope = try decoder.decode(BackupEnvelope.self, from: data)
        } catch {
            throw BackupError.decodingFailed
        }

        selectedFileName = url.lastPathComponent
        backupEnvelope = envelope
        importSummary = BackupSummary(envelope: envelope)
        importOptions = ImportOptions(defaultsFrom: envelope)
    }

    private func executeImport() {
        guard let backup = backupEnvelope else { return }
        guard importOptions.hasSelection else {
            errorMessage = BackupError.emptySelection.localizedDescription
            showingError = true
            return
        }

        isImporting = true

        Task {
            do {
                try await BackupImporter.importData(
                    backup,
                    options: importOptions
                )
                await MainActor.run {
                    isImporting = false
                    showingSuccess = true
                }
            } catch {
                await MainActor.run {
                    isImporting = false
                    errorMessage = (error as? BackupError)?.localizedDescription ?? error.localizedDescription
                    showingError = true
                }
            }
        }
    }
}

// MARK: - Import Options & Summary
private struct ImportOptions {
    var importRoutes: Bool = false
    var importLogs: Bool = false
    var importChecklist: Bool = false
    var importKnowledge: Bool = false
    var importUserProfile: Bool = false

    init() {}

    init(defaultsFrom envelope: BackupEnvelope) {
        self.importRoutes = !(envelope.drivingRoutes?.isEmpty ?? true)
        self.importLogs = !(envelope.drivingLogs?.isEmpty ?? true)
        let hasChecklist = !(envelope.checklistRecords?.isEmpty ?? true)
            || !(envelope.checklistItems?.isEmpty ?? true)
            || !(envelope.checklistPunches?.isEmpty ?? true)
        self.importChecklist = hasChecklist
        self.importKnowledge = !(envelope.knowledgeProgress?.isEmpty ?? true)
        self.importUserProfile = envelope.userProfile != nil
    }

    var hasSelection: Bool {
        importRoutes || importLogs || importChecklist || importKnowledge || importUserProfile
    }
}

private struct BackupSummary {
    let routeCount: Int
    let logCount: Int
    let checklistRecordCount: Int
    let checklistItemCount: Int
    let checklistPunchCount: Int
    let knowledgeProgressCount: Int
    let hasUserProfile: Bool
    let exportedAt: Date?

    init(envelope: BackupEnvelope) {
        self.routeCount = envelope.drivingRoutes?.count ?? 0
        self.logCount = envelope.drivingLogs?.count ?? 0
        self.checklistRecordCount = envelope.checklistRecords?.count ?? 0
        self.checklistItemCount = envelope.checklistItems?.count ?? 0
        self.checklistPunchCount = envelope.checklistPunches?.count ?? 0
        self.knowledgeProgressCount = envelope.knowledgeProgress?.count ?? 0
        self.hasUserProfile = envelope.userProfile != nil
        self.exportedAt = envelope.metadata.exportedAt
    }

    var exportedAtFormatted: String {
        guard let exportedAt else { return "未知时间" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
        return formatter.string(from: exportedAt)
    }

    var hasChecklistData: Bool {
        checklistRecordCount > 0 || checklistItemCount > 0 || checklistPunchCount > 0
    }
}

// MARK: - Importer
private struct BackupImporter {
    @MainActor
    static func importData(_ envelope: BackupEnvelope, options: ImportOptions) throws {
        guard let context = GlobalModelContext.context else { throw BackupError.contextUnavailable }

        if options.importRoutes {
            try clearAll(of: DriveRoute.self, in: context)
            envelope.drivingRoutes?.forEach { context.insert($0.toModel()) }
        }

        if options.importLogs {
            try clearAll(of: LogEntry.self, in: context)
            envelope.drivingLogs?.forEach { context.insert($0.toModel()) }
        }

        if options.importChecklist {
            try clearAll(of: ChecklistRecord.self, in: context)
            try clearAll(of: ChecklistItem.self, in: context)
            try clearAll(of: ChecklistPunch.self, in: context)
            envelope.checklistRecords?.forEach { context.insert($0.toModel()) }
            envelope.checklistItems?.forEach { context.insert($0.toModel()) }
            envelope.checklistPunches?.forEach { context.insert($0.toModel()) }
        }

        if options.importKnowledge {
            try clearAll(of: KnowledgeProgress.self, in: context)
            envelope.knowledgeProgress?.forEach { context.insert($0.toModel()) }

            if let backups = envelope.knowledgeCards {
                let existingCards = try context.fetch(FetchDescriptor<KnowledgeCard>())
                var map: [String: KnowledgeCard] = [:]
                for card in existingCards { map[card.id] = card }

                for backup in backups {
                    if let existing = map[backup.id] {
                        existing.title = backup.title
                        existing.what = backup.what
                        existing.why = backup.why
                        existing.how = backup.how
                        existing.tags = backup.tags
                    } else {
                        context.insert(backup.toModel())
                    }
                }
            }
        }

        if options.importUserProfile {
            try clearAll(of: UserProfile.self, in: context)
            if let profile = envelope.userProfile {
                context.insert(profile.toModel())
            }
        }

        try context.save()
    }

    @MainActor
    private static func clearAll<T: PersistentModel>(of type: T.Type, in context: ModelContext) throws {
        let items = try context.fetch(FetchDescriptor<T>())
        for item in items {
            context.delete(item)
        }
    }
}

#Preview {
    DataImportView()
        .environmentObject(AppDI.shared)
}
