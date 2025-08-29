import Foundation
import CoreLocation
import Combine

@MainActor
class DriveService: ObservableObject {
    static let shared = DriveService()
    
    @Published var isDriving: Bool = false
    @Published var currentRoute: DriveRoute?
    @Published var isStartingDrive: Bool = false
    @Published var isEndingDrive: Bool = false
    
    private let repository: DriveRouteRepository
    private let locationService: LocationService
    
    @MainActor
    init(repository: DriveRouteRepository? = nil,
         locationService: LocationService? = nil) {
        self.repository = repository ?? AppDI.shared.driveRouteRepository
        self.locationService = locationService ?? LocationService.shared
        checkForActiveRoute()
    }
    
    /// 检查是否有正在进行的路线
    private func checkForActiveRoute() {
        if let activeRoute = try? repository.getCurrentActiveRoute() {
            self.currentRoute = activeRoute
            self.isDriving = true
        }
    }
    
    /// 开始驾驶
    func startDriving() async {
        guard !isDriving else { return }
        
        isStartingDrive = true
        defer { isStartingDrive = false }
        
        do {
            // 获取当前位置
            let currentLocation = try await locationService.getCurrentLocation()
            let address = await locationService.getCurrentLocationDescription()
            
            let startLocation = currentLocation.map { location in
                RouteLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: address
                )
            }
            
            // 创建新的路线记录
            let route = try repository.startRoute(startLocation: startLocation)
            
            // 更新状态
            self.currentRoute = route
            self.isDriving = true
            
        } catch {
            print("开始驾驶失败: \(error)")
            // 即使位置获取失败，也允许开始驾驶
            do {
                let route = try repository.startRoute(startLocation: nil)
                self.currentRoute = route
                self.isDriving = true
            } catch {
                print("创建路线失败: \(error)")
            }
        }
    }
    
    /// 结束驾驶
    func endDriving() async {
        guard isDriving, let routeId = currentRoute?.id else { return }
        
        isEndingDrive = true
        defer { isEndingDrive = false }
        
        do {
            // 获取当前位置
            let currentLocation = try await locationService.getCurrentLocation()
            let address = await locationService.getCurrentLocationDescription()
            
            let endLocation = currentLocation.map { location in
                RouteLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: address
                )
            }
            
            // 结束路线记录
            try repository.endRoute(routeId: routeId, endLocation: endLocation)
            
            // 更新状态
            self.currentRoute = nil
            self.isDriving = false
            
        } catch {
            print("结束驾驶失败: \(error)")
            // 即使位置获取失败，也允许结束驾驶
            do {
                try repository.endRoute(routeId: routeId, endLocation: nil)
                self.currentRoute = nil
                self.isDriving = false
            } catch {
                print("结束路线失败: \(error)")
            }
        }
    }
    
    /// 取消当前驾驶
    func cancelDriving() {
        guard isDriving, let route = currentRoute else { return }
        
        do {
            try repository.updateRoute(route) { route in
                route.status = .cancelled
                route.endTime = Date()
            }
            
            self.currentRoute = nil
            self.isDriving = false
            
        } catch {
            print("取消驾驶失败: \(error)")
        }
    }
    
    /// 获取最近的路线记录
    func getRecentRoutes(limit: Int = 5) -> [DriveRoute] {
        return (try? repository.fetchRecentRoutes(limit: limit)) ?? []
    }
    
    /// 格式化驾驶时长
    func formatDuration(_ duration: TimeInterval?) -> String {
        guard let duration = duration else { return "--" }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    /// 格式化距离
    func formatDistance(_ distance: Double?) -> String {
        guard let distance = distance else { return "--" }
        
        if distance >= 1000 {
            return String(format: "%.1f公里", distance / 1000)
        } else {
            return String(format: "%.0f米", distance)
        }
    }
}

// MARK: - Drive Service Error
enum DriveServiceError: Error, LocalizedError {
    case alreadyDriving
    case notDriving
    case routeNotFound
    
    var errorDescription: String? {
        switch self {
        case .alreadyDriving:
            return "已经在驾驶中"
        case .notDriving:
            return "当前没有在驾驶"
        case .routeNotFound:
            return "找不到路线记录"
        }
    }
}