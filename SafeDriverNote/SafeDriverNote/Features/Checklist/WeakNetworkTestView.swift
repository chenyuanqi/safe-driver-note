import SwiftUI

/// 弱网环境测试视图
/// 用于演示和测试在弱网环境下打卡功能的行为
struct WeakNetworkTestView: View {
    @State private var showingCheckinModal = false
    @State private var networkStatus: NetworkMonitor.NetworkStatus = .good
    @State private var isNetworkMonitoringEnabled = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // 网络状态模拟器
                networkSimulatorSection
                
                // 功能说明
                descriptionSection
                
                // 测试按钮
                testButton
                
                Spacer()
            }
            .padding()
            .navigationTitle("弱网测试")
            .sheet(isPresented: $showingCheckinModal) {
                // 模拟检查项
                let mockItems = [
                    ChecklistItem(title: "检查轮胎气压", itemDescription: "确保四个轮胎气压正常", mode: .pre),
                    ChecklistItem(title: "检查车灯", itemDescription: "确认所有车灯工作正常", mode: .pre),
                    ChecklistItem(title: "调整后视镜", itemDescription: "调整内外后视镜到合适位置", mode: .pre)
                ]
                
                CheckinModal(
                    isPresented: $showingCheckinModal,
                    mode: .pre,
                    items: mockItems
                ) { punch in
                    // 处理保存的打卡记录
                    print("打卡记录已保存: \(punch)")
                }
                .onAppear {
                    // 设置模拟的网络状态
                    NetworkMonitor.shared.simulatedNetworkStatus = networkStatus
                }
            }
        }
    }
    
    private var networkSimulatorSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("网络状态模拟器")
                .font(.headline)
                .fontWeight(.semibold)
            
            Picker("网络状态", selection: $networkStatus) {
                Text("良好").tag(NetworkMonitor.NetworkStatus.good)
                Text("弱网").tag(NetworkMonitor.NetworkStatus.weak)
                Text("断网").tag(NetworkMonitor.NetworkStatus.disconnected)
            }
            .pickerStyle(.segmented)
            
            Toggle("启用网络监控", isOn: $isNetworkMonitoringEnabled)
                .toggleStyle(SwitchToggleStyle())
            
            switch networkStatus {
            case .good:
                Text("模拟良好网络环境：网络连接稳定")
                    .font(.caption)
                    .foregroundColor(.green)
                    .multilineTextAlignment(.leading)
            case .weak:
                Text("模拟弱网环境：网络连接不稳定，可能出现延迟或丢包")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.leading)
            case .disconnected:
                Text("模拟断网环境：网络连接完全中断")
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("功能说明")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("点击「开始测试」打开打卡弹窗")
                bulletPoint("选择不同的网络状态来测试功能")
                bulletPoint("在网络断开时尝试保存打卡，会显示重试提示")
                bulletPoint("在网络恢复后可以重试保存操作")
                bulletPoint("保存过程中会显示加载指示器")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top) {
            Text("•")
                .fontWeight(.bold)
                .padding(.top, 2)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var testButton: some View {
        Button(action: {
            showingCheckinModal = true
        }) {
            Text("开始测试")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
        }
    }
}

#Preview {
    WeakNetworkTestView()
}