import SwiftUI
import Foundation

struct ChecklistView: View {
    let initialMode: ChecklistViewModel.Mode?
    @StateObject private var vm: ChecklistViewModel
    @State private var showingAdd = false
    @State private var newTitle: String = ""
    @State private var itemPendingEdit: ChecklistItem? = nil
    @State private var showingPunch = false
    @State private var tempSelectedIds = Set<UUID>()
    @State private var showingHistory = false
    @State private var showSavedAlert = false
    @State private var editMode: EditMode = .inactive
    @State private var editingItemId: UUID? = nil
    @State private var editingText: String = ""
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ChecklistItem? = nil
    @State private var showingPunchCompleteAlert = false
    @State private var showingManagement = false
    @State private var dailySummary: DailyCheckinSummary? = nil
    @State private var showPunchSuccessAlert = false
    @State private var lastPunchScore = 0
    @Environment(\.colorScheme) private var colorScheme
    
    init(initialMode: ChecklistViewModel.Mode? = nil) {
        self.initialMode = initialMode
        self._vm = StateObject(wrappedValue: ChecklistViewModel(repository: AppDI.shared.checklistRepository))
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                StandardNavigationBar(
                    title: "检查清单",
                    showBackButton: false,
                    trailingButtons: [
                        StandardNavigationBar.NavBarButton(icon: "chart.bar") {
                            showingHistory = true
                        }
                    ]
                )
                
                ScrollView {
                    VStack(spacing: Spacing.xxxl) {
                        modeSwitchSection
                        checkinButtonSection
                        dailySummarySection
                        managementSection
                    }
                    .padding(.horizontal, Spacing.pagePadding)
                    .padding(.vertical, Spacing.lg)
                }
                .refreshable {
                    await refreshChecklistData()
                }
                .background(Color.gray.opacity(0.1))
            }
            
            // 打卡弹框
            if showingPunch {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingPunch = false
                    }
                
                CheckinModal(
                    isPresented: $showingPunch,
                    mode: vm.mode,
                    items: currentModeItems,
                    onSave: handlePunchSave
                )
                .padding(.horizontal, Spacing.lg)
            }
            
            // 管理检查项弹框
            if showingManagement {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showingManagement = false
                    }
                
                ChecklistManagementModal(
                    isPresented: $showingManagement,
                    mode: vm.mode,
                    items: currentModeItems,
                    itemToEdit: itemPendingEdit,
                    onSave: handleManagementSave
                )
            }
        }
        .onAppear {
            initializeChecklistItems()
            if let initialMode = initialMode {
                vm.mode = initialMode
            }
            loadDailySummary()
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                VStack(spacing: 0) {
                    // 自定义导航栏
                    HStack {
                        Button("取消") {
                            showingAdd = false
                        }
                        .foregroundColor(.brandPrimary500)
                        
                        Spacer()
                        
                        Text("添加项目")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button("保存") {
                            vm.addItem(title: newTitle, mode: vm.mode)
                            showingAdd = false
                        }
                        .foregroundColor(.brandPrimary500)
                        .disabled(newTitle.isEmpty)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(Color(.systemBackground))
                    
                    Divider()
                    
                    // 表单内容
                    Form {
                        TextField("项目名称", text: $newTitle)
                    }
                }
                .navigationBarHidden(true)
            }
        }
        .sheet(isPresented: $showingHistory) {
            NavigationStack {
                ChecklistHistoryView()
                    .environmentObject(AppDI.shared)
                    .navigationTitle("历史打卡")
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let item = itemToDelete {
                    vm.deleteItem(item)
                    itemToDelete = nil
                }
            }
        } message: {
            Text("确定要删除这个检查项吗？此操作无法撤销。")
        }
        .alert("打卡完成", isPresented: $showingPunchCompleteAlert) {
            Button("确定") {
                // 这里可以执行打卡完成后的逻辑
                showSavedAlert = true
            }
        } message: {
            Text("成功记录本次打卡！")
        }
        .alert("打卡成功", isPresented: $showPunchSuccessAlert) {
            Button("确定") { }
        } message: {
            Text("成功记录本次打卡，得分 \(lastPunchScore)分！")
        }
        .onChange(of: showingManagement) { isPresented in
            if !isPresented {
                itemPendingEdit = nil
            }
        }
    }
    
    private var modeSwitchSection: some View {
        HStack(spacing: Spacing.lg) {
            modeCard(
                icon: "car",
                title: "行前检查",
                itemCount: vm.itemsPre.count,
                completedCount: 0,
                isSelected: vm.mode == .pre
            ) {
                vm.mode = .pre
            }
            
            modeCard(
                icon: "parkingsign",
                title: "行后检查",
                itemCount: vm.itemsPost.count,
                completedCount: 0,
                isSelected: vm.mode == .post
            ) {
                vm.mode = .post
            }
        }
    }
    
    private var checkinButtonSection: some View {
        Button(action: {
            showingPunch = true
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                
                Text("打卡")
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.lg)
            .background(Color.brandPrimary500)
            .cornerRadius(CornerRadius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var dailySummarySection: some View {
        Group {
            if let summary = dailySummary {
                DailyCheckinSummaryView(summary: summary, items: vm.itemsPre + vm.itemsPost)
            } else {
                // 加载中或无数据的占位符
                VStack(spacing: Spacing.md) {
                    Text("今日打卡记录")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)
                    
                    Text("正在加载...")
                        .font(.bodyMedium)
                        .foregroundColor(.brandSecondary500)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xl)
                .background(Color.cardBackground)
                .cornerRadius(CornerRadius.lg)
            }
        }
    }
    
    private var managementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            managementSectionHeader
            checklistCard
            managementSectionFooter
        }
    }

    private var managementSectionHeader: some View {
        HStack {
            Label("管理检查项", systemImage: "checklist")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Spacer()
        }
    }

    private var checklistCard: some View {
        VStack(spacing: 0) {
            checklistCardHeader
            Divider()
            checklistItemsList
        }
        .background(cardBackgroundColor)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: cardShadowColor, radius: 8, x: 0, y: 2)
    }

    private var checklistCardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vm.mode == .pre ? "出行前检查" : "归来后检查")
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Text("共 \(currentModeItems.count) 项")
                    .font(.caption)
                    .foregroundColor(.brandSecondary500)
            }

            Spacer()

            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("已配置")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(cardHeaderBackgroundColor)
    }

    private var checklistItemsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(currentModeItems.prefix(4).enumerated()), id: \.element.id) { index, item in
                checklistItemRow(item: item, index: index)

                if index < min(3, currentModeItems.count - 1) {
                    Divider()
                        .padding(.leading, 48)
                        .background(Color.separatorColor.opacity(colorScheme == .dark ? 0.4 : 1))
                }
            }

            if currentModeItems.count > 4 {
                expandMoreButton
            }
        }
    }

    private func checklistItemRow(item: ChecklistItem, index: Int) -> some View {
        Button {
            itemPendingEdit = item
            showingManagement = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(circleBackgroundColor)
                        .frame(width: 24, height: 24)
                    Text("\(index + 1)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(circleTextColor)
                }

                Text(item.title)
                    .font(.bodyMedium)
                    .foregroundColor(.brandSecondary700)
                    .lineLimit(1)

                Spacer()

                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var expandMoreButton: some View {
        Button(action: { showingManagement = true }) {
            HStack {
                Spacer()
                Text("查看全部 \(currentModeItems.count) 项")
                    .font(.bodySmall)
                    .foregroundColor(expandButtonForeground)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(expandButtonForeground)
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
        .background(expandButtonBackground)
    }

    private var managementSectionFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundColor(.brandSecondary400)

            Text("点击检查项即可编辑、调整或删除")
                .font(.caption)
                .foregroundColor(.brandSecondary500)
        }
        .padding(.horizontal, 4)
    }
    
    private var cardBackgroundColor: Color {
        Color.cardBackground.opacity(colorScheme == .dark ? 0.9 : 1.0)
    }
    
    private var cardShadowColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05)
    }
    
    private var cardHeaderBackgroundColor: Color {
        colorScheme == .dark ? Color.brandSecondary700.opacity(0.45) : Color.brandSecondary100
    }
    
    private var expandButtonBackground: Color {
        colorScheme == .dark ? Color.brandSecondary700.opacity(0.4) : Color.brandPrimary50
    }
    
    private var expandButtonForeground: Color {
        colorScheme == .dark ? Color.white.opacity(0.85) : Color.brandPrimary500
    }
    
    private var circleBackgroundColor: Color {
        colorScheme == .dark ? Color.brandPrimary500.opacity(0.25) : Color.brandPrimary100
    }
    
    private var circleTextColor: Color {
        colorScheme == .dark ? Color.brandPrimary100 : Color.brandPrimary600
    }

    // 计算属性
    private var currentModeItems: [ChecklistItem] {
        return vm.mode == .pre ? vm.itemsPre : vm.itemsPost
    }
    
    // 事件处理方法
    private func handlePunchSave(_ punch: ChecklistPunch) {
        do {
            // 保存打卡记录到ViewModel
            try vm.savePunch(punch)
            // 记录得分以便显示
            lastPunchScore = punch.score
            // 显示成功提示
            showPunchSuccessAlert = true
            // 重新加载今日记录摘要
            loadDailySummary()
        } catch {
            // 处理保存失败的情况
            print("保存打卡记录失败: \(error)")
            // 可以在这里添加用户提示
        }
    }
    
    private func handleManagementSave(_ items: [ChecklistItem]) {
        // 保存管理的检查项
        vm.saveItems(items, for: vm.mode)
    }
    
    private func loadDailySummary() {
        // 从ViewModel获取今日摘要
        dailySummary = vm.getDailySummary()
    }
    
    private func initializeChecklistItems() {
        // 初始化检查项数据（现在直接使用 ViewModel 中的数据）
        // 不需要额外操作
    }
    
    private func modeCard(
        icon: String,
        title: String,
        itemCount: Int,
        completedCount: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .brandPrimary500)
                
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white : .brandSecondary900)
                
                Text("\(itemCount)项")
                    .font(.bodySmall)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .brandSecondary600)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xl)
            .background(isSelected ? Color.brandPrimary500 : Color.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Pull to Refresh
    private func refreshChecklistData() async {
        // 重新加载清单数据
        vm.reloadItems()
        vm.reloadPunchesToday()

        // 添加轻微延迟以提供更好的用户体验
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
    }
}

#Preview {
    ChecklistView()
}
