import SwiftUI

struct CheckinModal: View {
    @StateObject private var viewModel: CheckinModalViewModel
    @Binding var isPresented: Bool
    let mode: ChecklistViewModel.Mode
    let items: [ChecklistItem]
    let onSave: (ChecklistPunch) -> Void
    
    init(
        isPresented: Binding<Bool>,
        mode: ChecklistViewModel.Mode,
        items: [ChecklistItem],
        onSave: @escaping (ChecklistPunch) -> Void
    ) {
        self._isPresented = isPresented
        self.mode = mode
        self.items = items
        self.onSave = onSave
        self._viewModel = StateObject(wrappedValue: CheckinModalViewModel(items: items))
    }
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 标题栏
            titleHeader
            
            // 快速完成按钮
            quickCompleteButton
            
            // 分隔线
            dividerWithText
            
            // 检查项列表
            checklistItemsSection
            
            // 底部按钮
            bottomButtons
        }
        .padding(Spacing.xl)
        .background(Color(.systemBackground))
        .cornerRadius(CornerRadius.xl)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: UIScreen.main.bounds.height * 0.8)
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedItemIds)
    }
    
    private var titleHeader: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: mode == .pre ? "car" : "parkingsign.circle")
                .font(.title2)
                .foregroundColor(.brandPrimary500)
            
            Text(mode == .pre ? "行前检查" : "行后检查")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
            
            Spacer()
        }
    }
    
    private var quickCompleteButton: some View {
        Button(action: viewModel.quickCompleteAll) {
            HStack(spacing: Spacing.md) {
                Image(systemName: "bolt.fill")
                    .font(.title3)
                
                Text("快速完成全部检查")
                    .font(.bodyLarge)
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
    
    private var dividerWithText: some View {
        HStack {
            Rectangle()
                .fill(Color.brandSecondary200)
                .frame(height: 1)
            
            Text("或选择检查项")
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)
                .padding(.horizontal, Spacing.md)
            
            Rectangle()
                .fill(Color.brandSecondary200)
                .frame(height: 1)
        }
    }
    
    private var checklistItemsSection: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(items, id: \.id) { item in
                    checklistItemRow(item: item)
                }
            }
        }
        .frame(maxHeight: 300)
    }
    
    private func checklistItemRow(item: ChecklistItem) -> some View {
        Button(action: {
            viewModel.toggleItem(item.id)
        }) {
            HStack(spacing: Spacing.md) {
                Image(systemName: viewModel.selectedItemIds.contains(item.id) ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(viewModel.selectedItemIds.contains(item.id) ? .brandPrimary500 : .brandSecondary300)
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(item.title)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let itemDescription = item.itemDescription, !itemDescription.isEmpty {
                        Text(itemDescription)
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var bottomButtons: some View {
        HStack(spacing: Spacing.md) {
            Button("取消") {
                isPresented = false
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(Color.brandSecondary100)
            .foregroundColor(.brandSecondary700)
            .cornerRadius(CornerRadius.md)
            
            Button("保存打卡") {
                viewModel.saveCheckin(mode: mode) { punch in
                    onSave(punch)
                    isPresented = false
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(viewModel.selectedItemIds.isEmpty ? Color.brandSecondary200 : Color.brandPrimary500)
            .foregroundColor(viewModel.selectedItemIds.isEmpty ? .brandSecondary400 : .white)
            .cornerRadius(CornerRadius.md)
            .disabled(viewModel.selectedItemIds.isEmpty)
        }
    }
}

#Preview {
    CheckinModal(
        isPresented: .constant(true),
        mode: .pre,
        items: [
            ChecklistItem(title: "胎压检查", itemDescription: "检查四轮胎压是否正常", mode: .pre),
            ChecklistItem(title: "灯光检查", itemDescription: "检查远近光灯、转向灯、刹车灯", mode: .pre)
        ],
        onSave: { _ in }
    )
}