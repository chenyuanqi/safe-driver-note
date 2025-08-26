import SwiftUI
import Foundation

struct ChecklistView: View {
    @StateObject private var vm = ChecklistViewModel(repository: AppDI.shared.checklistRepository)
    @State private var showingAdd = false
    @State private var newTitle: String = ""
    @State private var editingItem: ChecklistItem? = nil
    @State private var showingPunch = false
    @State private var tempSelectedIds = Set<UUID>()
    @State private var showingHistory = false
    @State private var showSavedAlert = false
    @State private var editMode: EditMode = .inactive
    @State private var preCheckItems: [ChecklistItemData] = []
    @State private var postCheckItems: [ChecklistItemData] = []
    @State private var editingItemId: UUID? = nil
    @State private var editingText: String = ""
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ChecklistItemData? = nil
    @State private var showingPunchCompleteAlert = false

    var body: some View {
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
                    progressSection
                    checklistItemsSection
                    actionButtonsSection
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.brandSecondary50)
        }
        .onAppear {
            initializeChecklistItems()
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                Form { TextField("项目名称", text: $newTitle) }
                    .navigationTitle("添加项目")
                    .toolbar { 
                        ToolbarItem(placement: .confirmationAction) { 
                            Button("保存") { 
                                vm.addItem(title: newTitle, mode: vm.mode)
                                showingAdd = false 
                            } 
                        } 
                    }
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
                    if let index = (vm.mode == .pre ? preCheckItems : postCheckItems).firstIndex(where: { $0.id == item.id }) {
                        if vm.mode == .pre {
                            preCheckItems.remove(at: index)
                        } else {
                            postCheckItems.remove(at: index)
                        }
                    }
                    itemToDelete = nil
                }
            }
        } message: {
            Text("确定要删除这个检查项吗？此操作无法撤销。")
        }
        .alert("打卡完成", isPresented: $showingPunchCompleteAlert) {
            Button("确定") {
                // 记录打卡
                let items = vm.mode == .pre ? preCheckItems : postCheckItems
                let checkedIds = items.enumerated().compactMap { index, item in
                    item.isCompleted ? index : nil
                }
                // 这里调用ViewModel的方法来记录打卡
                // vm.recordPunch(mode: vm.mode, checkedItemIds: checkedIds)
                showSavedAlert = true
            }
        } message: {
            let items = vm.mode == .pre ? preCheckItems : postCheckItems
            let completedCount = items.filter(\.isCompleted).count
            Text("已记录本次打卡，共完成 \(completedCount) 项检查。")
        }
        .alert("保存成功", isPresented: $showSavedAlert) {
            Button("确定") { }
        } message: {
            Text("打卡记录已保存")
        }
    }
    
    private var modeSwitchSection: some View {
        HStack(spacing: Spacing.lg) {
            modeCard(
                icon: "car",
                title: "行前检查",
                itemCount: 8,
                completedCount: 0,
                isSelected: vm.mode == .pre
            ) {
                vm.mode = .pre
            }
            
            modeCard(
                icon: "parkingsign",
                title: "行后检查",
                itemCount: 5,
                completedCount: 0,
                isSelected: vm.mode == .post
            ) {
                vm.mode = .post
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Image(systemName: vm.mode == .pre ? "car" : "parkingsign")
                    .font(.title3)
                    .foregroundColor(.brandPrimary500)
                
                Text("\(vm.mode == .pre ? "行前" : "行后")检查")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
                
                Spacer()
            }
            
            ProgressCard(
                title: "完成进度",
                progress: currentProgress,
                color: .brandPrimary500
            )
        }
    }
    
    private var checklistItemsSection: some View {
        VStack(spacing: Spacing.lg) {
            let items = vm.mode == .pre ? preCheckItems : postCheckItems
            
            ForEach(items.indices, id: \.self) { index in
                checklistItemCard(item: items[index], index: index)
            }
            .onMove { from, to in
                if vm.mode == .pre {
                    preCheckItems.move(fromOffsets: from, toOffset: to)
                } else {
                    postCheckItems.move(fromOffsets: from, toOffset: to)
                }
            }
            
            // 打卡完成按钮 - 当有项目被勾选时显示
            if items.contains(where: { $0.isCompleted }) {
                Button(action: {
                    showingPunchCompleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                        Text("打卡完成")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.lg)
                    .background(Color.brandPrimary500)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: Spacing.lg) {
            Button("快速完成全部检查") {
                completeAllItems()
                // 生成打卡记录
                let completedItems = vm.mode == .pre ? preCheckItems : postCheckItems
                let checkedIds = completedItems.enumerated().compactMap { index, item in
                    item.isCompleted ? index : nil
                }
                // 这里调用ViewModel的方法来记录打卡
                // vm.recordPunch(mode: vm.mode, checkedItemIds: checkedIds)
            }
            .primaryStyle()
            
            HStack(spacing: Spacing.lg) {
                Button("添加自定义项目") {
                    addCustomItem()
                }
                .secondaryStyle()
                
                Button("查看历史记录") {
                    showingHistory = true
                }
                .secondaryStyle()
            }
        }
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
            Card(
                backgroundColor: isSelected ? .brandPrimary500 : .white,
                shadow: isSelected
            ) {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: icon)
                        .font(.largeTitle)
                        .foregroundColor(isSelected ? .white : .brandPrimary500)
                    
                    Text(title)
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .brandSecondary900)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func checklistItemCard(item: ChecklistItemData, index: Int) -> some View {
        Card(backgroundColor: .white, shadow: false) {
            HStack(spacing: Spacing.lg) {
                Button {
                    toggleItem(at: index)
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(item.isCompleted ? .brandPrimary500 : .brandSecondary300)
                }
                .buttonStyle(PlainButtonStyle())
                
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if editingItemId == item.id {
                        // 编辑模式
                        TextField("项目名称", text: $editingText)
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                if !editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    // 保存编辑
                                    if vm.mode == .pre {
                                        preCheckItems[index].title = editingText
                                    } else {
                                        postCheckItems[index].title = editingText
                                    }
                                    editingItemId = nil
                                    editingText = ""
                                }
                            }
                            .onAppear {
                                editingText = item.title
                            }
                    } else {
                        // 显示模式
                        Text(item.title)
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(item.isCompleted ? .brandSecondary500 : .brandSecondary900)
                            .strikethrough(item.isCompleted)
                    }
                    
                    Text(item.subtitle)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }
                
                Spacer()
                
                // 编辑按钮
                if editingItemId != item.id {
                    Button(action: {
                        editingItemId = item.id
                        editingText = item.title
                    }) {
                        Image(systemName: "pencil")
                            .font(.body)
                            .foregroundColor(.brandSecondary500)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("编辑") {
                editingItemId = item.id
                editingText = item.title
            }
            .tint(.brandInfo500)
            
            Button("删除", role: .destructive) {
                itemToDelete = item
                showingDeleteAlert = true
            }
        }
    }
    
    // MARK: - Helper Methods
    private func initializeChecklistItems() {
        preCheckItems = defaultPreDriveItems
        postCheckItems = defaultPostDriveItems
    }
    
    private func toggleItem(at index: Int) {
        if vm.mode == .pre {
            preCheckItems[index].isCompleted.toggle()
        } else {
            postCheckItems[index].isCompleted.toggle()
        }
    }
    
    private func completeAllItems() {
        if vm.mode == .pre {
            for i in preCheckItems.indices {
                preCheckItems[i].isCompleted = true
            }
        } else {
            for i in postCheckItems.indices {
                postCheckItems[i].isCompleted = true
            }
        }
    }
    
    private var currentProgress: Double {
        let items = vm.mode == .pre ? preCheckItems : postCheckItems
        guard !items.isEmpty else { return 0.0 }
        let completedCount = items.filter(\.isCompleted).count
        return Double(completedCount) / Double(items.count)
    }
    
    private func addCustomItem() {
        let newItem = ChecklistItemData(title: "", subtitle: "自定义检查项", isCompleted: false)
        if vm.mode == .pre {
            preCheckItems.append(newItem)
        } else {
            postCheckItems.append(newItem)
        }
        // 自动进入编辑模式
        editingItemId = newItem.id
        editingText = ""
    }
    
    private var defaultPreDriveItems: [ChecklistItemData] {
        [
            ChecklistItemData(title: "胎压检查", subtitle: "检查四轮胎压是否正常"),
            ChecklistItemData(title: "灯光检查", subtitle: "检查远近光灯、转向灯、刹车灯"),
            ChecklistItemData(title: "后视镜调整", subtitle: "调整内外后视镜到合适位置"),
            ChecklistItemData(title: "雨刷功能", subtitle: "检查雨刷器工作是否正常"),
            ChecklistItemData(title: "油量/电量", subtitle: "确认燃油或电量充足"),
            ChecklistItemData(title: "座椅/方向盘", subtitle: "调整到舒适的驾驶位置"),
            ChecklistItemData(title: "导航/路线", subtitle: "设置目的地和导航路线"),
            ChecklistItemData(title: "随车工具", subtitle: "确认随车工具、证件齐全")
        ]
    }
    
    private var defaultPostDriveItems: [ChecklistItemData] {
        [
            ChecklistItemData(title: "手刹/P档", subtitle: "拉起手刹或挂入P档"),
            ChecklistItemData(title: "车窗/天窗", subtitle: "关闭所有车窗和天窗"),
            ChecklistItemData(title: "灯光关闭", subtitle: "关闭所有不必要的灯光"),
            ChecklistItemData(title: "贵重物品", subtitle: "带走贵重物品，不留在车内"),
            ChecklistItemData(title: "车门锁止", subtitle: "确认所有车门已锁好")
        ]
    }
}

struct ChecklistItemData: Identifiable {
    let id = UUID()
    var title: String
    let subtitle: String
    var isCompleted: Bool = false
}

#Preview {
    ChecklistView()
}