import SwiftUI
import Foundation

struct DataExportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportDrivingRoutes = true
    @State private var exportDrivingLogs = true
    @State private var exportChecklistRecords = true
    @State private var exportKnowledgeProgress = false
    @State private var exportFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var showingExportComplete = false

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
            .alert("导出完成", isPresented: $showingExportComplete) {
                Button("确定") {
                    showingExportComplete = false
                    dismiss()
                }
            } message: {
                Text("您的数据已成功导出到文件app，可以通过邮件、AirDrop等方式分享。")
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
                        statRow(icon: "car", title: "驾驶路线", count: "23条记录")
                    }

                    if exportDrivingLogs {
                        statRow(icon: "list.bullet", title: "驾驶日志", count: "45条记录")
                    }

                    if exportChecklistRecords {
                        statRow(icon: "checklist", title: "检查记录", count: "67次检查")
                    }

                    if exportKnowledgeProgress {
                        statRow(icon: "book", title: "学习进度", count: "34个知识点")
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

    private func performExport() {
        isExporting = true

        // 模拟导出过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isExporting = false
            showingExportComplete = true
        }

        // TODO: 实现真实的导出逻辑
        // 1. 收集选中的数据
        // 2. 根据格式转换数据
        // 3. 保存到文件系统
        // 4. 显示完成提示
    }
}

#Preview {
    DataExportView()
}