import SwiftUI
import Foundation

struct ChecklistView: View {
    let initialMode: ChecklistViewModel.Mode?
    @StateObject private var vm: ChecklistViewModel
    @State private var showingAdd = false
    @State private var newTitle: String = ""
    @State private var editingItem: ChecklistItem? = nil
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
                .background(Color.brandSecondary50)
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
            HStack {
                Text("管理检查项")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                
                Spacer()
                
                Button("编辑") {
                    showingManagement = true
                }
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.brandPrimary500)
            }
            
            // 显示当前模式的检查项数量
            VStack(alignment: .leading, spacing: Spacing.sm) {
                ForEach(currentModeItems.prefix(3), id: \.id) { item in
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .font(.body)
                            .foregroundColor(.brandSecondary400)
                        
                        Text(item.title)
                            .font(.bodyMedium)
                            .foregroundColor(.brandSecondary700)
                        
                        Spacer()
                    }
                }
                
                if currentModeItems.count > 3 {
                    Text("及其他 \(currentModeItems.count - 3) 项...")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                        .padding(.leading, 24) // 对齐图标
                }
            }
            .padding(Spacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.lg)
        }
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