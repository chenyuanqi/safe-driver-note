import SwiftUI

struct DrivingRulesManagementModal: View {
    @Binding var isPresented: Bool
    @State private var rules: [DrivingRule]
    @State private var editingRule: DrivingRule?
    @State private var editingContent = ""
    @State private var newRuleContent = ""
    @State private var showingNewRuleForm = false
    @State private var showingEditForm = false
    @State private var showingDeleteAlert = false
    @State private var ruleToDelete: DrivingRule?

    let onSave: ([DrivingRule]) -> Void

    init(
        isPresented: Binding<Bool>,
        rules: [DrivingRule],
        onSave: @escaping ([DrivingRule]) -> Void
    ) {
        self._isPresented = isPresented
        self._rules = State(initialValue: rules.sorted { $0.sortOrder < $1.sortOrder })
        self.onSave = onSave
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerSection

                List {
                    // 新增守则按钮
                    Section {
                        addNewRuleButton
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)

                    // 守则列表
                    Section {
                        ForEach(rules.indices, id: \.self) { index in
                            ruleRow(rule: rules[index], index: index)
                        }
                        .onMove(perform: moveRules)
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
        .sheet(isPresented: $showingNewRuleForm) {
            ruleFormView(isEditing: false)
        }
        .sheet(isPresented: $showingEditForm) {
            ruleFormView(isEditing: true)
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                if let rule = ruleToDelete {
                    deleteRule(rule)
                }
            }
        } message: {
            Text("确定要删除这条开车守则吗？此操作无法撤销。")
        }
    }

    private var headerSection: some View {
        VStack(spacing: Spacing.lg) {
            HStack {
                Text("管理开车守则")
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

    private var addNewRuleButton: some View {
        Button(action: {
            resetNewRuleForm()
            showingNewRuleForm = true
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(.brandPrimary500)

                Text("新增守则")
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

    private func ruleRow(rule: DrivingRule, index: Int) -> some View {
        HStack(spacing: Spacing.md) {
            // 拖动手柄
            Image(systemName: "line.3.horizontal")
                .font(.body)
                .foregroundColor(.brandSecondary400)
                .frame(width: 20)

            HStack(alignment: .top, spacing: Spacing.md) {
                Text("\(index + 1).")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandPrimary600)
                    .frame(minWidth: 20, alignment: .leading)

                Text(rule.content)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)
                    .lineLimit(3)
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
                ruleToDelete = rule
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
            }
            .tint(.brandDanger500)

            // 编辑按钮
            Button {
                editRule(rule)
            } label: {
                Image(systemName: "pencil")
            }
            .tint(.brandInfo500)
        }
        .onTapGesture {
            // 点击编辑
            editRule(rule)
        }
    }

    private func ruleFormView(isEditing: Bool) -> some View {
        NavigationView {
            Form {
                Section("守则内容") {
                    if isEditing {
                        TextField("守则内容", text: $editingContent, axis: .vertical)
                            .lineLimit(5...10)
                    } else {
                        TextField("守则内容", text: $newRuleContent, axis: .vertical)
                            .lineLimit(5...10)
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑守则" : "新增守则")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        if isEditing {
                            showingEditForm = false
                        } else {
                            showingNewRuleForm = false
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveRule(isEditing: isEditing)
                    }
                    .disabled(isEditing ? editingContent.isEmpty : newRuleContent.isEmpty)
                }
            }
        }
    }

    private func resetNewRuleForm() {
        newRuleContent = ""
    }

    private func editRule(_ rule: DrivingRule) {
        editingRule = rule
        editingContent = rule.content
        showingEditForm = true
    }

    private func saveRule(isEditing: Bool) {
        if isEditing {
            // 更新现有守则
            if let originalRule = editingRule,
               let index = rules.firstIndex(where: { $0.id == originalRule.id }) {
                rules[index].content = editingContent
                rules[index].updatedAt = Date()
            }
            showingEditForm = false
        } else {
            // 添加新守则
            let newRule = DrivingRule(
                content: newRuleContent,
                sortOrder: rules.count,
                isCustom: true
            )
            rules.append(newRule)
            showingNewRuleForm = false
        }
    }

    private func deleteRule(_ rule: DrivingRule) {
        rules.removeAll { $0.id == rule.id }
        // 重新排序
        for (index, _) in rules.enumerated() {
            rules[index].sortOrder = index
        }
        ruleToDelete = nil
    }

    private func moveRules(from source: IndexSet, to destination: Int) {
        rules.move(fromOffsets: source, toOffset: destination)

        // 更新排序
        for (index, _) in rules.enumerated() {
            rules[index].sortOrder = index
        }
    }

    private func saveAndClose() {
        onSave(rules)
        isPresented = false
    }
}

#Preview {
    DrivingRulesManagementModal(
        isPresented: .constant(true),
        rules: [
            DrivingRule(content: "慢出稳，练出精，思出透！敬畏生命，安全驾驶！", sortOrder: 0, isCustom: false),
            DrivingRule(content: "保持车距，专注前方，快速扫描周围环境(2s)", sortOrder: 1, isCustom: false)
        ],
        onSave: { _ in }
    )
}
