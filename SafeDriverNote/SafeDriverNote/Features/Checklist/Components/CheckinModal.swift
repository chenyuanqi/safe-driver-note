import SwiftUI

struct CheckinModal: View {
    @StateObject private var viewModel: CheckinModalViewModel
    @StateObject private var locationService = LocationService.shared
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @Binding var isPresented: Bool
    let mode: ChecklistViewModel.Mode
    let items: [ChecklistItem]
    let onSave: (ChecklistPunch) -> Void
    
    @State private var isGettingLocation = false
    @State private var currentLocationText = "获取位置中..."
    
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
            
            // 位置信息
            locationSection
            
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
        .onAppear {
            getCurrentLocation()
        }
        .alert("网络错误", isPresented: $viewModel.showRetryAlert) {
            Button("取消") {
                viewModel.cancelSave()
                isPresented = false
            }
            Button("重试") {
                viewModel.retrySave()
            }
        } message: {
            Text("保存打卡记录时遇到网络问题，请检查网络连接后重试。")
        }
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
    
    private var locationSection: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "location.fill")
                .font(.body)
                .foregroundColor(.brandInfo500)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("打卡位置")
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary500)
                
                if isGettingLocation {
                    HStack(spacing: Spacing.xs) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("获取位置中...")
                            .font(.bodyMedium)
                            .foregroundColor(.brandSecondary600)
                    }
                } else {
                    Text(currentLocationText)
                        .font(.bodyMedium)
                        .foregroundColor(.brandSecondary900)
                }
            }
            
            Spacer()
            
            Button(action: getCurrentLocation) {
                Image(systemName: "location.circle")
                    .font(.title3)
                    .foregroundColor(.brandPrimary500)
            }
            .disabled(isGettingLocation)
        }
        .padding(Spacing.md)
        .background(Color.brandSecondary50)
        .cornerRadius(CornerRadius.md)
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
                // 检查网络状态
                if !networkMonitor.isConnected {
                    // 显示网络错误提示
                    viewModel.showRetryAlert = true
                    return
                }
                
                let locationNote = currentLocationText == "获取位置中..." ? nil : currentLocationText
                viewModel.saveCheckin(mode: mode, locationNote: locationNote) { punch in
                    onSave(punch)
                    isPresented = false
                }
            }
            .overlay(
                Group {
                    if viewModel.isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(viewModel.selectedItemIds.isEmpty ? Color.brandSecondary200 : Color.brandPrimary500)
            .foregroundColor(viewModel.selectedItemIds.isEmpty ? .brandSecondary400 : .white)
            .cornerRadius(CornerRadius.md)
            .disabled(viewModel.selectedItemIds.isEmpty || viewModel.isSaving)
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

// MARK: - 位置获取
extension CheckinModal {
    private func getCurrentLocation() {
        guard !isGettingLocation else { return }
        
        isGettingLocation = true
        currentLocationText = "获取位置中..."
        
        Task {
            // 首先检查权限
            if !locationService.hasLocationPermission {
                locationService.requestLocationPermission()
            }
            
            // 获取位置描述
            let locationDescription = await locationService.getCurrentLocationDescription()
            
            await MainActor.run {
                self.isGettingLocation = false
                self.currentLocationText = locationDescription
            }
        }
    }
}