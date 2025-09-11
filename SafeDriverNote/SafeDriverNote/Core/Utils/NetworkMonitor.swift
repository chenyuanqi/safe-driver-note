import Foundation
import Network

@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected = true
    @Published private(set) var isCellular = false
    
    // 用于测试的模拟网络状态
    @Published var simulatedNetworkStatus: NetworkStatus = .good
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum NetworkStatus {
        case good, weak, disconnected
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                // 在实际应用中使用真实的网络状态
                // 在测试模式下使用模拟的网络状态
                #if DEBUG
                self?.updateSimulatedNetworkStatus()
                #else
                self?.isConnected = path.status == .satisfied
                self?.isCellular = path.usesInterfaceType(.cellular)
                #endif
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateSimulatedNetworkStatus() {
        switch simulatedNetworkStatus {
        case .good:
            isConnected = true
            isCellular = false
        case .weak:
            // 弱网状态下仍然连接，但可能不稳定
            isConnected = true
            isCellular = true
        case .disconnected:
            isConnected = false
            isCellular = false
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    deinit {
        monitor.cancel()
    }
}