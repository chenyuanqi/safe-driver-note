import SwiftUI

struct ChecklistManagementModal: View {
    @Binding var isPresented: Bool
    let mode: ChecklistViewModel.Mode
    @State private var items: [ChecklistItem]
    @State private var editingItem: ChecklistItem?
    @State private var editingTitle = ""
    @State private var editingDescription = ""
    @State private var editingPriority = ChecklistPriority.medium
    @State private var newItemTitle = ""
    @State private var newItemDescription = ""
    @State private var newItemPriority = ChecklistPriority.medium
    @State private var showingNewItemForm = false
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false
    @State private var itemToDelete: ChecklistItem?
    
    let onSave: ([ChecklistItem]) -> Void
    
    init(
        isPresented: Binding<Bool>,
        mode: ChecklistViewModel.Mode,
        items: [ChecklistItem],
        onSave: @escaping ([ChecklistItem]) -> Void
    ) {
        self._isPresented = isPresented
        self.mode = mode
        self._items = State(initialValue: items.sorted { ($0.sortOrder ?? 0) < ($1.sortOrder ?? 0) })
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection
                
                List {
                    // 新增检查项按钮
                    Section {
                        addNewItemButton
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    
                    // 检查项列表
                    Section {
                        ForEach(items.indices, id: \.self) { index in
                            checklistItemRow(item: items[index], index: index)
                        }
                        .onMove(perform: moveItems)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .listStyle(PlainListStyle())
                .background(Color.brandSecondary25)
            }
            .background(Color.brandSecondary25)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingNewItemForm) {
            itemFormView(isEditing: false)
        }
        .sheet(isPresented: $showingEditForm) {
            itemFormView(isEditing: true)
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let item = itemToDelete {
                    deleteItem(item)
                }
            }
        } message: {
            Text("确定要删除这个检查项吗？此操作无法撤销。")
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("管理检查项")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandSecondary900)
                
                Spacer()
                
                Button("完成") {
                    saveAndClose()
                }
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandPrimary500)
            }
            
            Rectangle()
                .fill(Color.brandSecondary200)
                .frame(height: 1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.lg)
        .background(Color.cardBackground)
    }
    
    private var addNewItemButton: some View {
        Button(action: {
            resetNewItemForm()
            showingNewItemForm = true
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.brandPrimary500)
                
                Text("新增检查项")
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.brandPrimary500)
                
                Spacer()
            }
            .padding(Spacing.lg)
            .background(Color.cardBackground)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.brandPrimary500, lineWidth: 2)
                    .scaleEffect(1.02)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, Spacing.lg)
    }
    
    private func checklistItemRow(item: ChecklistItem, index: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // 拖动手柄（始终显示）
            Image(systemName: "line.3.horizontal")
                .font(.body)
                .foregroundColor(.brandSecondary400)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(item.title)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                    
                    Spacer()
                    
                    // 优先级标记
                    priorityLabel(item.priority)
                }
                
                if let itemDescription = item.itemDescription, !itemDescription.isEmpty {
                    Text(itemDescription)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary600)
                        .lineLimit(2)
                }
            }
            
            Spacer()
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // 删除按钮
            Button {
                itemToDelete = item
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }
            .tint(.brandDanger500)
            
            // 编辑按钮
            Button {
                editItem(item)
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.brandInfo500)
        }
        .onTapGesture {
            // 点击编辑
            editItem(item)
        }
    }
    
    private func priorityLabel(_ priority: ChecklistPriority) -> some View {
        Text(priority.displayName)
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(priorityColor(priority))
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(priorityColor(priority).opacity(0.1))
            .cornerRadius(CornerRadius.sm)
    }
    
    private func priorityColor(_ priority: ChecklistPriority) -> Color {
        switch priority {
        case .high:
            return .brandDanger500
        case .medium:
            return .brandWarning500
        case .low:
            return .brandSecondary400
        }
    }
    
    private func itemFormView(isEditing: Bool) -> some View {
        NavigationView {
            Form {
                Section("基本信息") {
                    if isEditing {
                        TextField("检查项标题", text: $editingTitle)
                        
                        TextField("检查项描述", text: $editingDescription, axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        TextField("检查项标题", text: $newItemTitle)
                        
                        TextField("检查项描述", text: $newItemDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
                
                Section("设置") {
                    if isEditing {
                        Picker("优先级", selection: $editingPriority) {
                            ForEach(ChecklistPriority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    } else {
                        Picker("优先级", selection: $newItemPriority) {
                            ForEach(ChecklistPriority.allCases, id: \.self) { priority in
                                Text(priority.displayName).tag(priority)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑检查项" : "新增检查项")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        if isEditing {
                            showingEditForm = false
                        } else {
                            showingNewItemForm = false
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveItem(isEditing: isEditing)
                    }
                    .disabled(isEditing ? editingTitle.isEmpty : newItemTitle.isEmpty)
                }
            }
        }
    }
    
    private func resetNewItemForm() {
        newItemTitle = ""
        newItemDescription = ""
        newItemPriority = .medium
    }
    
    private func editItem(_ item: ChecklistItem) {
        // 设置编辑状态
        editingItem = item
        editingTitle = item.title
        editingDescription = item.itemDescription ?? ""
        editingPriority = item.priority
        showingEditForm = true
    }
    
    private func saveItem(isEditing: Bool) {
        if isEditing {
            // 更新现有项目
            if let originalItem = editingItem,
               let index = items.firstIndex(where: { $0.id == originalItem.id }) {
                items[index].title = editingTitle
                items[index].itemDescription = editingDescription.isEmpty ? nil : editingDescription
                items[index].priority = editingPriority
                items[index].updatedAt = Date()
            }
            showingEditForm = false
        } else {
            // 添加新项目
            let newItem = ChecklistItem(
                title: newItemTitle,
                itemDescription: newItemDescription.isEmpty ? nil : newItemDescription,
                mode: mode == .pre ? .pre : .post,
                priority: newItemPriority,
                sortOrder: items.count
            )
            items.append(newItem)
            showingNewItemForm = false
        }
    }
    
    private func deleteItem(_ item: ChecklistItem) {
        items.removeAll { $0.id == item.id }
        // 重新排序
        for (index, item) in items.enumerated() {
            items[index].sortOrder = index
        }
        itemToDelete = nil
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        
        // 更新排序
        for (index, item) in items.enumerated() {
            items[index].sortOrder = index
        }
    }
    
    private func saveAndClose() {
        onSave(items)
        isPresented = false
    }
}

#Preview {
    ChecklistManagementModal(
        isPresented: .constant(true),
        mode: .pre,
        items: [
            ChecklistItem(title: "胎压检查", itemDescription: "检查四轮胎压是否正常", mode: .pre, priority: .high),
            ChecklistItem(title: "灯光检查", itemDescription: "检查远近光灯、转向灯、刹车灯", mode: .pre, priority: .medium)
        ],
        onSave: { _ in }
    )
}