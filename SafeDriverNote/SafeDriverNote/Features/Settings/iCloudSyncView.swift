import SwiftUI

struct iCloudSyncView: View {
    @State private var syncService: iCloudSyncService?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI

    @State private var showingInfo = false
    @State private var showingSyncOptions = false
    @State private var lastSyncTime: Date?
    @State private var isInitializing = true

    var body: some View {
        NavigationView {
            Group {
                if isInitializing {
                    // 初始化状态
                    VStack(spacing: Spacing.xl) {
                        ProgressView()
                            .scaleEffect(1.2)

                        Text("正在初始化 iCloud 服务...")
                            .font(.bodyMedium)
                            .foregroundColor(.brandSecondary500)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.brandSecondary50)
                } else if let service = syncService {
                    // 主内容
                    ScrollView {
                        VStack(spacing: Spacing.xxxl) {
                            // 状态卡片
                            syncStatusCard(service: service)

                            // 同步统计
                            if let stats = service.lastSyncStats {
                                syncStatsCard(stats)
                            }

                            // 操作按钮
                            syncActionsSection(service: service)

                            // 信息说明
                            infoSection
                        }
                        .padding(Spacing.pagePadding)
                    }
                    .background(Color.brandSecondary50)
                } else {
                    // 错误状态
                    VStack(spacing: Spacing.xl) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.brandWarning500)

                        Text("iCloud 服务初始化失败")
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)

                        Text("请检查您的 iCloud 设置")
                            .font(.bodyMedium)
                            .foregroundColor(.brandSecondary500)

                        Button("重试") {
                            initializeSyncService()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.brandSecondary50)
                }
            }
            .navigationTitle("iCloud 同步")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingInfo = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                    .disabled(isInitializing)
                }
            }
            .onAppear {
                initializeSyncService()
                loadLastSyncTime()
            }
            .sheet(isPresented: $showingInfo) {
                iCloudSyncInfoView()
            }
        }
    }

    // MARK: - 初始化方法

    private func initializeSyncService() {
        isInitializing = true

        Task {
            // 在后台线程初始化同步服务
            let service = iCloudSyncService(modelContainer: sharedModelContainer)

            await MainActor.run {
                self.syncService = service
                self.isInitializing = false
            }
        }
    }

    // MARK: - 状态卡片
    private func syncStatusCard(service: iCloudSyncService) -> some View {
        Card(shadow: true) {
            VStack(spacing: Spacing.lg) {
                HStack {
                    Image(systemName: statusIcon(for: service))
                        .font(.title2)
                        .foregroundColor(statusColor(for: service))

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("同步状态")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)

                        Text(statusText(for: service))
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                    }

                    Spacer()

                    if case .syncing = service.syncStatus {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                if case .syncing = service.syncStatus {
                    VStack(spacing: Spacing.sm) {
                        ProgressView(value: service.syncProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .brandPrimary500))

                        Text("\(Int(service.syncProgress * 100))% 完成")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }
                }

                if let lastSync = lastSyncTime {
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(.brandSecondary400)

                        Text("上次同步：\(formatDate(lastSync))")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)

                        Spacer()
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - 同步统计卡片
    private func syncStatsCard(_ stats: iCloudSyncStats) -> some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("同步统计")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                HStack(spacing: Spacing.xl) {
                    statItem(
                        title: "上传记录",
                        value: "\(stats.uploadedRecords)",
                        icon: "arrow.up.circle",
                        color: .brandPrimary500
                    )

                    statItem(
                        title: "下载记录",
                        value: "\(stats.downloadedRecords)",
                        icon: "arrow.down.circle",
                        color: .brandInfo500
                    )

                    statItem(
                        title: "数据大小",
                        value: formatDataSize(stats.totalDataSize),
                        icon: "externaldrive",
                        color: .brandSecondary600
                    )
                }

                if stats.syncDuration > 0 {
                    HStack {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(.brandSecondary400)

                        Text("耗时：\(String(format: "%.1f", stats.syncDuration))秒")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)

                        Spacer()
                    }
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - 同步操作区域
    private func syncActionsSection(service: iCloudSyncService) -> some View {
        VStack(spacing: Spacing.md) {
            // 完整同步
            Button(action: {
                Task {
                    do {
                        _ = try await service.performFullSync()
                        loadLastSyncTime()
                    } catch {
                        // 错误处理
                        print("同步失败: \(error)")
                    }
                }
            }) {
                actionButton(
                    title: "完整同步",
                    subtitle: "上传本地数据并下载云端数据",
                    icon: "icloud.and.arrow.up.and.arrow.down",
                    color: .brandPrimary500,
                    disabled: isSyncing(service: service)
                )
            }
            .disabled(isSyncing(service: service))

            // 仅上传
            Button(action: {
                Task {
                    do {
                        _ = try await service.uploadToiCloud()
                        loadLastSyncTime()
                    } catch {
                        print("上传失败: \(error)")
                    }
                }
            }) {
                actionButton(
                    title: "备份到云端",
                    subtitle: "仅上传本地数据到 iCloud",
                    icon: "icloud.and.arrow.up",
                    color: .brandInfo500,
                    disabled: isSyncing(service: service)
                )
            }
            .disabled(isSyncing(service: service))

            // 从云端恢复
            Button(action: {
                showingSyncOptions = true
            }) {
                actionButton(
                    title: "从云端恢复",
                    subtitle: "下载并合并云端数据到本地",
                    icon: "icloud.and.arrow.down",
                    color: .brandWarning500,
                    disabled: isSyncing(service: service)
                )
            }
            .disabled(isSyncing(service: service))
            .confirmationDialog("从云端恢复", isPresented: $showingSyncOptions, titleVisibility: .visible) {
                Button("确认恢复") {
                    Task {
                        do {
                            _ = try await service.restoreFromiCloud()
                            loadLastSyncTime()
                        } catch {
                            print("恢复失败: \(error)")
                        }
                    }
                }
                Button("取消", role: .cancel) { }
            } message: {
                Text("这将从 iCloud 下载数据并合并到本地。如果存在相同数据，可能会产生重复。确定要继续吗？")
            }
        }
    }

    // MARK: - 信息说明区域
    private var infoSection: some View {
        Card {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("同步说明")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    infoRow(
                        icon: "checkmark.circle",
                        text: "自动同步您的驾驶日志、检查记录等数据",
                        color: .brandPrimary500
                    )

                    infoRow(
                        icon: "shield",
                        text: "数据加密存储在您的 iCloud 私有数据库",
                        color: .brandInfo500
                    )

                    infoRow(
                        icon: "arrow.triangle.2.circlepath",
                        text: "支持多设备间的数据同步",
                        color: .brandSecondary600
                    )

                    infoRow(
                        icon: "exclamationmark.triangle",
                        text: "需要确保 iCloud 账户正常登录",
                        color: .brandWarning500
                    )
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - 计算属性

    private func isSyncing(service: iCloudSyncService) -> Bool {
        if case .syncing = service.syncStatus {
            return true
        }
        return false
    }

    // MARK: - 辅助方法

    private func actionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        disabled: Bool
    ) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(disabled ? .brandSecondary400 : color)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(disabled ? .brandSecondary400 : .brandSecondary900)

                Text(subtitle)
                    .font(.bodySmall)
                    .foregroundColor(disabled ? .brandSecondary300 : .brandSecondary500)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.bodySmall)
                .foregroundColor(disabled ? .brandSecondary300 : .brandSecondary400)
        }
        .padding(Spacing.md)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func statItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Text(title)
                .font(.caption)
                .foregroundColor(.brandSecondary500)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.bodySmall)
                .foregroundColor(color)
                .frame(width: 16, height: 16)

            Text(text)
                .font(.bodySmall)
                .foregroundColor(.brandSecondary700)

            Spacer()
        }
    }

    private func statusIcon(for service: iCloudSyncService) -> String {
        switch service.syncStatus {
        case .idle:
            return "icloud"
        case .syncing:
            return "icloud.and.arrow.up.and.arrow.down"
        case .success:
            return "icloud.and.arrow.up"
        case .failed:
            return "icloud.slash"
        }
    }

    private func statusColor(for service: iCloudSyncService) -> Color {
        switch service.syncStatus {
        case .idle:
            return .brandSecondary500
        case .syncing:
            return .brandInfo500
        case .success:
            return .brandPrimary500
        case .failed:
            return .brandDanger500
        }
    }

    private func statusText(for service: iCloudSyncService) -> String {
        switch service.syncStatus {
        case .idle:
            return "准备就绪"
        case .syncing:
            return "同步中..."
        case .success:
            return "同步成功"
        case .failed(let error):
            return "同步失败：\(error.localizedDescription)"
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: date)
    }

    private func formatDataSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    private func loadLastSyncTime() {
        lastSyncTime = UserDefaults.standard.object(forKey: "LastiCloudSyncTime") as? Date
    }
}

// MARK: - 同步信息详情视图
struct iCloudSyncInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xxxl) {
                    // 同步数据类型
                    syncDataTypesSection

                    // 数据结构说明
                    dataStructureSection

                    // 注意事项
                    noticesSection
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("同步详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var syncDataTypesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("同步的数据类型")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            VStack(spacing: Spacing.md) {
                ForEach(SyncableDataType.allCases, id: \.self) { dataType in
                    dataTypeRow(dataType)
                }
            }
        }
    }

    private var dataStructureSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("数据结构")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("iCloud 数据存储结构：")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("📁 私有数据库")
                        Text("├── SafeDriverNote_LogEntry (驾驶日志)")
                        Text("├── SafeDriverNote_ChecklistRecord (检查记录)")
                        Text("├── SafeDriverNote_ChecklistItem (检查项目)")
                        Text("├── SafeDriverNote_ChecklistPunch (打卡记录)")
                        Text("├── SafeDriverNote_KnowledgeProgress (学习进度)")
                        Text("├── SafeDriverNote_DriveRoute (行驶路线)")
                        Text("└── SafeDriverNote_UserProfile (用户资料)")
                    }
                    .font(.caption)
                    .foregroundColor(.brandSecondary600)
                    .padding(.leading, Spacing.md)
                }
                .padding(Spacing.lg)
            }
        }
    }

    private var noticesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("注意事项")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Card {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    noticeItem(
                        icon: "wifi.slash",
                        title: "网络要求",
                        description: "同步需要网络连接，建议在 WiFi 环境下进行"
                    )

                    Divider()

                    noticeItem(
                        icon: "externaldrive.badge.icloud",
                        title: "存储空间",
                        description: "数据存储在您的 iCloud 账户中，会占用 iCloud 存储空间"
                    )

                    Divider()

                    noticeItem(
                        icon: "lock.shield",
                        title: "隐私安全",
                        description: "所有数据都存储在您的私有 iCloud 数据库中，仅您可以访问"
                    )

                    Divider()

                    noticeItem(
                        icon: "arrow.triangle.merge",
                        title: "数据合并",
                        description: "从云端恢复时会与本地数据合并，可能产生重复记录"
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    private func dataTypeRow(_ dataType: SyncableDataType) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.bodySmall)
                .foregroundColor(.brandPrimary500)

            Text(dataType.displayName)
                .font(.bodyMedium)
                .foregroundColor(.brandSecondary900)

            Spacer()

            Text(dataType.rawValue)
                .font(.caption)
                .foregroundColor(.brandSecondary500)
        }
        .padding(.vertical, Spacing.xs)
    }

    private func noticeItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.bodyLarge)
                .foregroundColor(.brandInfo500)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)

                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary600)
            }

            Spacer()
        }
    }
}

#Preview {
    iCloudSyncView()
        .environmentObject(AppDI.shared)
}