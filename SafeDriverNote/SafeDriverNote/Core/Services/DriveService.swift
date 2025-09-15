import Foundation
import CoreLocation
import Combine

extension Notification.Name {
    static let driveServiceError = Notification.Name("driveServiceError")
}

@MainActor
class DriveService: ObservableObject {
    static let shared = DriveService()
    
    @Published var isDriving: Bool = false
    @Published var currentRoute: DriveRoute?
    @Published var isStartingDrive: Bool = false
    @Published var isEndingDrive: Bool = false
    @Published var currentDrivingTime: String = ""
    
    private let repository: DriveRouteRepository
    private let locationService: LocationService
    private var drivingTimer: Timer?
    private var locationTrackingTimer: Timer? // 位置跟踪定时器
    private var currentWaypoints: [RouteLocation] = [] // 当前路径点集合
    private var locationCancellable: AnyCancellable?

    /// 定时采集位置的时间间隔（秒）
    private let locationTrackingInterval: TimeInterval = 60 // 每60秒采集一次位置，符合设计要求
    
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
            
            // 如果有正在进行的路线，启动定时器
            startDrivingTimer()
        }
    }
    
    /// 开始驾驶
    func startDriving() async {
        guard !isDriving else { return }
        
        isStartingDrive = true
        defer { isStartingDrive = false }
        
        do {
            // 使用最近一次已知位置，避免并发一次性定位造成挂起
            var startLocation: RouteLocation? = nil
            if let loc = locationService.currentLocation {
                let address = await locationService.getLocationDescription(from: loc)
                startLocation = RouteLocation(latitude: loc.coordinate.latitude, longitude: loc.coordinate.longitude, address: address)
            }
            let route = try repository.startRoute(startLocation: startLocation)
            
            // 更新状态
            self.currentRoute = route
            self.isDriving = true
            
            // 升级为Always并启动连续定位
            locationService.requestAlwaysAuthorizationIfEligible()
            // 等待一小段时间确保权限申请完成
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            startDrivingTimer()
            
        } catch {
            print("创建路线失败: \(error)")
        }
    }
    
    /// 使用外部提供的起点位置启动驾驶（用于手动输入位置）
    func startDriving(with startLocationOverride: RouteLocation?) async {
        guard !isDriving else { return }
        isStartingDrive = true
        defer { isStartingDrive = false }
        do {
            let route = try repository.startRoute(startLocation: startLocationOverride)
            self.currentRoute = route
            self.isDriving = true
            locationService.requestAlwaysAuthorizationIfEligible()
            startDrivingTimer()
        } catch {
            print("创建路线失败: \(error)")
        }
    }
    
    /// 结束驾驶
    func endDriving() async {
        guard isDriving, let routeId = currentRoute?.id else { return }
        
        isEndingDrive = true
        defer { isEndingDrive = false }
        
        do {
            // 使用最近一次已知位置作为终点（获取实际地址而不是坐标）
            var endLocation: RouteLocation? = nil
            if let loc = locationService.currentLocation {
                let lat = loc.coordinate.latitude
                let lon = loc.coordinate.longitude
                // 获取实际地址描述而不是坐标字符串
                let address = await locationService.getLocationDescription(from: loc)
                endLocation = RouteLocation(latitude: lat, longitude: lon, address: address)
            }
            
            // 结束路线记录，并传递收集到的路径点
            try repository.endRoute(routeId: routeId, endLocation: endLocation, waypoints: currentWaypoints)
            
            // 更新状态
            self.currentRoute = nil
            self.isDriving = false
            
            // 停止定时器
            stopDrivingTimer()
            
        } catch {
            print("结束路线失败: \(error)")
            NotificationCenter.default.post(name: .driveServiceError, object: "结束驾驶失败: \(error.localizedDescription)")
        }
    }

    /// 结束驾驶（手动终点覆盖）
    func endDriving(with endLocationOverride: RouteLocation) async {
        guard isDriving, let routeId = currentRoute?.id else { return }
        isEndingDrive = true
        defer { isEndingDrive = false }
        do {
            try repository.endRoute(routeId: routeId, endLocation: endLocationOverride, waypoints: currentWaypoints)
            self.currentRoute = nil
            self.isDriving = false
            stopDrivingTimer()
        } catch {
            print("结束驾驶失败: \(error)")
            NotificationCenter.default.post(name: .driveServiceError, object: "结束驾驶失败: \(error.localizedDescription)")
        }
    }

    /// 在信号不佳时的结束驾驶：重试 x 次 + 超时控制；失败则提示或交给用户手动输入
    func endDrivingWithRetries(maxAttempts: Int = 3, perAttemptTimeout: TimeInterval = 5.0) async {
        guard isDriving else { return }
        var attempt = 0
        while attempt < maxAttempts {
            attempt += 1
            // 为每次尝试设置超时：优先使用最近位置；若没有，再等待一次性定位（带超时）
            if let loc = locationService.currentLocation {
                await endDrivingUsing(location: loc)
                return
            }
            do {
                let loc = try await locationService.getCurrentLocation(timeout: perAttemptTimeout)
                if let loc = loc {
                    await endDrivingUsing(location: loc)
                    return
                }
            } catch {
                // ignore and retry
            }
        }
        // 三次失败：发通知由界面弹出手动输入
        NotificationCenter.default.post(name: .driveServiceError, object: "结束驾驶定位超时，请手动输入终点位置")
    }

    private func endDrivingUsing(location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        // 获取实际地址描述而不是坐标字符串
        let address = await locationService.getLocationDescription(from: location)
        let endLoc = RouteLocation(latitude: lat, longitude: lon, address: address)
        await endDriving(with: endLoc)
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
            
            // 停止定时器
            stopDrivingTimer()
            
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
    
    // MARK: - Timer Management
    
    /// 启动驾驶计时器
    private func startDrivingTimer() {
        stopDrivingTimer() // 确保旧的定时器停止
        
        // 立即更新一次
        updateDrivingTime()
        
        // 启动定时器，每60秒更新一次驾驶时间
        drivingTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateDrivingTime()
            }
        }
        
        // 启动位置跟踪（使用连续定位而不是定时器）
        startLocationTracking()
    }
    
    /// 停止驾驶计时器
    private func stopDrivingTimer() {
        drivingTimer?.invalidate()
        drivingTimer = nil
        currentDrivingTime = ""
        
        // 停止位置跟踪
        stopLocationTracking()
    }
    
    /// 启动位置跟踪
    private func startLocationTracking() {
        stopLocationTracking()
        currentWaypoints = []

        // 启动连续定位，使用更高精度和更低的距离过滤器以获得更详细的路径
        locationService.startContinuousUpdates(desiredAccuracy: kCLLocationAccuracyBest, distanceFilter: 5) // 5米更新一次，提高精度

        // 立即采集一次
        captureCurrentLocation()

        // 添加定时器，每分钟强制记录一次位置（即使车辆未移动）
        locationTrackingTimer = Timer.scheduledTimer(withTimeInterval: locationTrackingInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.captureCurrentLocationForced()
            }
        }

        // 订阅连续定位（基于移动距离的实时更新）
        locationCancellable = locationService.locationPublisher
            .sink { [weak self] location in
                guard let self = self else { return }
                Task { @MainActor in
                    // 检查位置精度，过滤掉精度太差的位置
                    guard location.horizontalAccuracy <= 20 && location.horizontalAccuracy >= 0 else {
                        print("位置精度太差，跳过: 精度=\(location.horizontalAccuracy)米")
                        return
                    }

                    // 检查是否与上一个位置太近，避免重复记录
                    if let lastWaypoint = self.currentWaypoints.last {
                        let lastLocation = CLLocation(latitude: lastWaypoint.latitude, longitude: lastWaypoint.longitude)
                        let distance = location.distance(from: lastLocation)
                        if distance < 5 { // 小于5米的移动不记录
                            return
                        }
                    }

                    let address = await self.locationService.getLocationDescription(from: location)
                    let waypoint = RouteLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, address: address)
                    self.currentWaypoints.append(waypoint)
                    print("移动触发路径点: \(waypoint.latitude), \(waypoint.longitude), 精度: \(location.horizontalAccuracy)米")

                    // 实时更新路线的路径点
                    if let route = self.currentRoute {
                        try? self.repository.updateRoute(route) { r in
                            r.waypoints = self.currentWaypoints
                        }
                    }
                }
            }
    }
    
    /// 停止位置跟踪
    private func stopLocationTracking() {
        locationTrackingTimer?.invalidate()
        locationTrackingTimer = nil
        locationCancellable?.cancel()
        locationCancellable = nil
        locationService.stopContinuousUpdates()
    }
    
    /// 采集当前位置并保存到路径点集合
    private func captureCurrentLocation() {
        Task {
            do {
                // 获取当前位置
                guard let currentLocation = try await locationService.getCurrentLocation() else { return }

                let address = await locationService.getLocationDescription(from: currentLocation)

                // 创建路径点
                let routeLocation = RouteLocation(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude,
                    address: address
                )

                // 添加到路径点集合
                currentWaypoints.append(routeLocation)
                print("立即采集路径点: \(routeLocation.latitude), \(routeLocation.longitude)")

                // 更新当前路线的路径点
                if let route = currentRoute {
                    try repository.updateRoute(route) { route in
                        route.waypoints = self.currentWaypoints
                    }
                }

            } catch {
                print("采集位置失败: \(error)")
            }
        }
    }

    /// 强制采集当前位置（定时器使用，即使车辆未移动也记录）
    private func captureCurrentLocationForced() {
        Task {
            do {
                // 优先使用缓存位置，如果没有则尝试获取新位置
                var currentLocation = locationService.currentLocation

                // 如果没有缓存位置，尝试获取（短超时）
                if currentLocation == nil {
                    currentLocation = try? await locationService.getCurrentLocation(timeout: 3.0)
                }

                guard let location = currentLocation else {
                    print("定时采集位置失败：无法获取位置")
                    return
                }

                // 检查位置精度
                guard location.horizontalAccuracy <= 30 && location.horizontalAccuracy >= 0 else {
                    print("定时采集位置精度太差，跳过: 精度=\(location.horizontalAccuracy)米")
                    return
                }

                let address = await locationService.getLocationDescription(from: location)

                // 创建路径点
                let routeLocation = RouteLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    address: address
                )

                // 添加到路径点集合
                currentWaypoints.append(routeLocation)
                print("定时采集路径点: \(routeLocation.latitude), \(routeLocation.longitude), 精度: \(location.horizontalAccuracy)米")

                // 更新当前路线的路径点
                if let route = currentRoute {
                    try repository.updateRoute(route) { route in
                        route.waypoints = self.currentWaypoints
                    }
                }

            } catch {
                print("定时采集位置失败: \(error)")
            }
        }
    }
    
    /// 更新驾驶时间显示
    private func updateDrivingTime() {
        guard let route = currentRoute else {
            currentDrivingTime = ""
            return
        }
        
        let elapsed = Date().timeIntervalSince(route.startTime)
        currentDrivingTime = formatDrivingTime(elapsed)
    }
    
    /// 格式化驾驶时间
    private func formatDrivingTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
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