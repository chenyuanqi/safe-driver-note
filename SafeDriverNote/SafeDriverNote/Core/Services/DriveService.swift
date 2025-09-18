import Foundation
import CoreLocation
import Combine
import UIKit

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
    @Published var currentWaypointCount: Int = 0
    
    private let repository: DriveRouteRepository
    private let locationService: LocationService
    private var drivingTimer: Timer?
    private var locationTrackingTimer: Timer? // 位置跟踪定时器
    private var currentWaypoints: [RouteLocation] = [] // 当前路径点集合
    private var locationCancellable: AnyCancellable?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid // 后台任务标识

    /// 定时采集位置的时间间隔（秒）
    private let locationTrackingInterval: TimeInterval = 10 // 每10秒强制采集一次位置，确保轨迹完整
    
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

            // 恢复已保存的路径点
            if let waypoints = activeRoute.waypoints, !waypoints.isEmpty {
                self.currentWaypoints = waypoints
                self.currentWaypointCount = waypoints.count
                print("恢复已保存的路径点: \(waypoints.count)个")
            }

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

        // 调试信息：显示收集到的坐标数据
        printDebugInfo()

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

        // 调试信息：显示收集到的坐标数据
        printDebugInfo()

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

        // 开始后台任务，确保应用在后台能继续记录
        startBackgroundTask()
    }
    
    /// 停止驾驶计时器
    private func stopDrivingTimer() {
        drivingTimer?.invalidate()
        drivingTimer = nil
        currentDrivingTime = ""

        // 停止位置跟踪
        stopLocationTracking()

        // 结束后台任务
        endBackgroundTask()
    }
    
    /// 启动位置跟踪
    private func startLocationTracking() {
        stopLocationTracking()

        // 如果已有路径点（从持久化恢复的），不要清空
        if currentWaypoints.isEmpty {
            currentWaypoints = []
            currentWaypointCount = 0
        }

        // 启动连续定位，使用导航级精度和更小的距离过滤器
        locationService.startContinuousUpdates(desiredAccuracy: kCLLocationAccuracyBestForNavigation, distanceFilter: 5) // 5米更新一次，获得更详细的轨迹

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
                    // 检查位置精度，放宽精度过滤条件以避免丢失轨迹点
                    guard location.horizontalAccuracy <= 50 && location.horizontalAccuracy >= 0 else {
                        print("位置精度太差，跳过: 精度=\(location.horizontalAccuracy)米")
                        return
                    }

                    // 检查是否与上一个位置太近，避免重复记录
                    if let lastWaypoint = self.currentWaypoints.last {
                        let lastLocation = CLLocation(latitude: lastWaypoint.latitude, longitude: lastWaypoint.longitude)
                        let distance = location.distance(from: lastLocation)
                        if distance < 5 { // 小于5米的移动不记录，与distanceFilter保持一致
                            return
                        }
                    }

                    let address = await self.locationService.getLocationDescription(from: location)
                    let waypoint = RouteLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, address: address)
                    self.currentWaypoints.append(waypoint)
                    self.currentWaypointCount = self.currentWaypoints.count
                    print("移动触发路径点: \(waypoint.latitude), \(waypoint.longitude), 精度: \(location.horizontalAccuracy)米")

                    // 实时更新路线的路径点（每10个点保存一次，减少IO操作）
                    if self.currentWaypoints.count % 10 == 0 {
                        if let route = self.currentRoute {
                            try? self.repository.updateRoute(route) { r in
                                r.waypoints = self.currentWaypoints
                            }
                            print("定期保存路径点：\(self.currentWaypoints.count)个")
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
        // 不清空 currentWaypointCount，保持已记录的路径点数量
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
                currentWaypointCount = currentWaypoints.count
                print("立即采集路径点: \(routeLocation.latitude), \(routeLocation.longitude)")

                // 立即保存路径点（采集时需要立即保存）
                if let route = currentRoute {
                    try repository.updateRoute(route) { route in
                        route.waypoints = self.currentWaypoints
                    }
                    print("保存路径点：\(currentWaypoints.count)个")
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

                // 检查位置精度（定时采集时放宽标准，确保即使信号差也能记录）
                guard location.horizontalAccuracy <= 100 && location.horizontalAccuracy >= 0 else {
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
                currentWaypointCount = currentWaypoints.count
                print("定时采集路径点: \(routeLocation.latitude), \(routeLocation.longitude), 精度: \(location.horizontalAccuracy)米")

                // 立即保存路径点（采集时需要立即保存）
                if let route = currentRoute {
                    try repository.updateRoute(route) { route in
                        route.waypoints = self.currentWaypoints
                    }
                    print("保存路径点：\(currentWaypoints.count)个")
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

    /// 打印调试信息
    private func printDebugInfo() {
        print("================== 驾驶调试信息 ==================")
        print("驾驶开始时间: \(currentRoute?.startTime ?? Date())")
        print("驾驶结束时间: \(Date())")
        print("总共收集坐标点数量: \(currentWaypoints.count)")

        if currentWaypoints.isEmpty {
            print("警告：没有收集到任何坐标点！")
        } else {
            print("第一个坐标点: \(currentWaypoints.first!.latitude), \(currentWaypoints.first!.longitude)")
            print("最后一个坐标点: \(currentWaypoints.last!.latitude), \(currentWaypoints.last!.longitude)")

            // 显示前5个和后5个坐标点
            let showCount = min(5, currentWaypoints.count)
            print("\n前\(showCount)个坐标点:")
            for i in 0..<showCount {
                let wp = currentWaypoints[i]
                print("  [\(i+1)] \(wp.latitude), \(wp.longitude) - \(wp.address)")
            }

            if currentWaypoints.count > 10 {
                print("\n后5个坐标点:")
                for i in (currentWaypoints.count-5)..<currentWaypoints.count {
                    let wp = currentWaypoints[i]
                    print("  [\(i+1)] \(wp.latitude), \(wp.longitude) - \(wp.address)")
                }
            }
        }

        // 检查定位服务状态
        print("\n定位服务状态:")
        print("  当前定位权限: \(locationService.authorizationStatus)")
        print("  是否正在连续定位: \(locationService.isContinuousTracking)")
        print("  最近缓存位置: \(locationService.currentLocation != nil ? "有" : "无")")

        print("================================================\n")
    }

    /// 获取调试信息字符串（供UI显示）
    func getDebugInfo() -> String {
        var info = "驾驶调试信息\n"
        info += "==================\n"
        info += "开始时间: \(currentRoute?.startTime ?? Date())\n"
        info += "收集坐标点: \(currentWaypoints.count) 个\n"

        if currentWaypoints.isEmpty {
            info += "⚠️ 没有收集到任何坐标点\n"
        } else {
            if let first = currentWaypoints.first {
                info += "起点: \(String(format: "%.6f, %.6f", first.latitude, first.longitude))\n"
            }
            if let last = currentWaypoints.last {
                info += "终点: \(String(format: "%.6f, %.6f", last.latitude, last.longitude))\n"
            }
        }

        info += "\n定位状态:\n"
        info += "权限: \(locationService.authorizationStatus)\n"
        info += "连续定位: \(locationService.isContinuousTracking ? "开启" : "关闭")\n"

        return info
    }

    // MARK: - Background Task Management

    /// 获取当前路径点（供外部访问）
    func getCurrentWaypoints() -> [RouteLocation] {
        return currentWaypoints
    }

    /// 恢复位置跟踪（如果需要）
    func resumeLocationTrackingIfNeeded() {
        guard isDriving else { return }

        // 如果没有在连续跟踪，重新启动
        if !locationService.isContinuousTracking {
            print("恢复位置跟踪")
            startLocationTracking()
        }
    }

    /// 立即保存当前路径点到持久化存储
    func saveWaypointsImmediately() {
        guard let route = currentRoute else { return }

        do {
            try repository.updateRoute(route) { r in
                r.waypoints = self.currentWaypoints
            }
            print("已保存 \(currentWaypoints.count) 个路径点到持久化存储")
        } catch {
            print("保存路径点失败: \(error)")
        }
    }

    /// 开始后台任务
    private func startBackgroundTask() {
        // 先结束之前的后台任务（如果存在）
        endBackgroundTask()

        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "DriveTracking") { [weak self] in
            // 后台任务即将过期时的处理
            print("后台任务即将过期，尝试重新申请...")
            self?.endBackgroundTask()
            // 尝试重新申请后台任务
            self?.startBackgroundTask()
        }

        if backgroundTask != .invalid {
            print("后台任务开始，ID: \(backgroundTask)")
        }
    }

    /// 结束后台任务
    private func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            print("后台任务结束，ID: \(backgroundTask)")
            backgroundTask = .invalid
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