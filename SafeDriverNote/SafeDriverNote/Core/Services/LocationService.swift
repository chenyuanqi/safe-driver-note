import Foundation
import CoreLocation
import Combine
#if canImport(UIKit)
import UIKit
#endif

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let locationUpdateSubject = PassthroughSubject<CLLocation, Never>()
    var locationPublisher: AnyPublisher<CLLocation, Never> { locationUpdateSubject.eraseToAnyPublisher() }
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    @Published var isLocationUpdating = false

    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
    private var locationTimeoutTask: Task<Void, Error>?
    private var isContinuousMode: Bool = false

    // 位置缓存队列，用于弱网/无网环境下的位置记录
    private var locationCache: [CLLocation] = []
    private let maxCacheSize = 100 // 最大缓存位置数量

    // 地址缓存，避免重复网络请求
    private var addressCache: [String: String] = [:] // coordinate -> address
    private let addressCacheTimeout: TimeInterval = 3600 // 1小时缓存有效期
    private var addressCacheTimestamps: [String: Date] = [:]

    /// 公开属性：是否正在连续定位
    var isContinuousTracking: Bool {
        return isContinuousMode
    }
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation // 使用导航级精度
        locationManager.distanceFilter = 5.0 // 5米更新一次，获得更详细的路径
        locationManager.pausesLocationUpdatesAutomatically = false // 防止系统自动暂停
        locationManager.activityType = .automotiveNavigation // 设置为汽车导航类型

        // 注意：allowsBackgroundLocationUpdates 只在 startContinuousUpdates 中设置
        // 避免在初始化时设置导致崩溃

        authorizationStatus = locationManager.authorizationStatus
    }
    
    /// 请求位置权限
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // 可以引导用户到设置页面
            break
        case .authorizedWhenInUse, .authorizedAlways:
            // 已有权限，可以开始定位
            break
        @unknown default:
            break
        }
    }

    /// 显式请求“使用期间”权限
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// 尝试直接请求“始终允许”权限（iOS 会自动引导完成所需的两步授权流程）
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// 后台连续定位：开始持续更新
    func startContinuousUpdates(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation, distanceFilter: CLLocationDistance = 5.0) {
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter // 使用传入的参数，默认为5米
        locationManager.activityType = .automotiveNavigation // 确保设置为汽车导航类型

        // 先开始定位更新
        locationManager.startUpdatingLocation()

        // 安全地设置后台定位（只在有权限且已经开始定位后设置）
        #if os(iOS)
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            // 检查是否配置了后台模式
            let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
            let hasBackgroundLocation = backgroundModes.contains("location")

            if hasBackgroundLocation {
                // 只在真正需要后台定位且有配置时才设置
                DispatchQueue.main.async { [weak self] in
                    self?.locationManager.allowsBackgroundLocationUpdates = true
                    self?.locationManager.pausesLocationUpdatesAutomatically = false

                    if #available(iOS 11.0, *) {
                        self?.locationManager.showsBackgroundLocationIndicator = true
                    }
                }

                // 后台模式下调整精度以节省电量
                #if canImport(UIKit)
                if UIApplication.shared.applicationState == .background {
                    locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    locationManager.distanceFilter = 10.0
                }
                #endif
            }
        }
        #endif

        // 同时启用显著位置变化监听作为备份（这个在后台也能工作）
        locationManager.startMonitoringSignificantLocationChanges()

        isContinuousMode = true
        print("开始连续定位 - 精度: \(desiredAccuracy), 距离过滤: \(distanceFilter)米")
    }
    
    /// 后台连续定位：停止持续更新
    func stopContinuousUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges() // 同时停止显著位置变化监听

        // 安全地关闭后台定位
        DispatchQueue.main.async { [weak self] in
            #if os(iOS)
            if #available(iOS 11.0, *) {
                self?.locationManager.showsBackgroundLocationIndicator = false
            }
            #endif
            // 恢复为默认（前台）模式
            self?.locationManager.allowsBackgroundLocationUpdates = false
            self?.locationManager.pausesLocationUpdatesAutomatically = true
        }

        isContinuousMode = false
    }
    
    /// 在已授权“使用期间”后，尝试申请“始终允许”权限
    func requestAlwaysAuthorizationIfEligible() {
        #if os(iOS)
        if authorizationStatus == .authorizedWhenInUse {
            print("请求始终允许权限")
            locationManager.requestAlwaysAuthorization()
        }
        #endif
    }
    
    /// 获取当前位置（一次性，尽快返回）：
    /// - 优先返回系统缓存的最近位置（若在 staleThreshold 内）
    /// - 否则短暂开启 startUpdatingLocation，加速首次定位
    func getCurrentLocation(timeout: TimeInterval = 15.0, staleThreshold: TimeInterval = 300.0) async throws -> CLLocation? {
        #if os(iOS)
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        #endif
        
        // 取消之前的超时任务
        locationTimeoutTask?.cancel()
        
        // 快速返回系统最近一次位置（可能来自系统缓存或其他App），提升首帧体验
        if let quick = locationManager.location {
            let age = Date().timeIntervalSince(quick.timestamp)
            if age <= staleThreshold {
                await MainActor.run { self.currentLocation = quick }
                return quick
            }
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.isLocationUpdating = true
            
            // 设置超时机制
            self.locationTimeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                if !Task.isCancelled {
                    // 超时处理
                    await MainActor.run {
                        if let continuation = self.locationContinuation {
                            continuation.resume(throwing: LocationError.timeout)
                            self.locationContinuation = nil
                            self.isLocationUpdating = false
                            // 仅在非连续模式下停止一次性更新
                            if !self.isContinuousMode { self.locationManager.stopUpdatingLocation() }
                        }
                    }
                }
            }
            
            // 为加速首次定位，临时开启连续更新；收到第一次回调后会在代理中结束（若非连续模式）
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBest // 使用最高精度
            self.locationManager.startUpdatingLocation()
        }
    }
    
    /// 获取当前位置的地址描述
    func getCurrentLocationDescription(timeout: TimeInterval = 10.0) async -> String {
        do {
            guard let location = try await getCurrentLocation(timeout: timeout) else {
                return "未知位置"
            }
            
            return await getLocationDescription(from: location)
        } catch {
            if let locationError = error as? LocationError {
                switch locationError {
                case .timeout:
                    return "位置获取超时"
                case .permissionDenied:
                    return "位置权限被拒绝"
                case .locationUnavailable:
                    return "无法获取位置信息"
                }
            }
            return "未知位置"
        }
    }
    
    /// 地址正向地理编码（将地址转为经纬度）
    func geocodeAddress(_ address: String) async throws -> CLLocation {
        let placemarks = try await geocoder.geocodeAddressString(address)
        if let pm = placemarks.first, let loc = pm.location {
            return loc
        } else {
            throw LocationError.locationUnavailable
        }
    }
    
    /// 从坐标获取地址描述（支持缓存和离线降级）
    func getLocationDescription(from location: CLLocation) async -> String {
        let coordinateKey = "\(location.coordinate.latitude),\(location.coordinate.longitude)"

        // 1. 检查缓存
        if let cachedAddress = getCachedAddress(for: coordinateKey) {
            return cachedAddress
        }

        // 2. 尝试网络请求（带超时）
        let geocodeTask = Task { () -> String? in
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                guard let placemark = placemarks.first else {
                    return nil
                }

                await MainActor.run {
                    self.currentPlacemark = placemark
                }

                return formatPlacemark(placemark)
            } catch {
                return nil
            }
        }

        // 3. 设置超时（弱网环境下快速降级）
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 增加到5秒超时，给地址解析更多时间
            geocodeTask.cancel()
        }

        if let address = await geocodeTask.value {
            timeoutTask.cancel()
            // 缓存地址
            cacheAddress(address, for: coordinateKey)
            return address
        }

        timeoutTask.cancel()

        // 4. 降级：尝试生成有意义的地址描述而不是纯坐标
        let fallbackAddress = generateMeaningfulAddress(from: location)
        // 也缓存降级地址，避免重复尝试
        cacheAddress(fallbackAddress, for: coordinateKey)
        return fallbackAddress
    }

    /// 获取缓存的地址
    private func getCachedAddress(for key: String) -> String? {
        guard let address = addressCache[key],
              let timestamp = addressCacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < addressCacheTimeout else {
            return nil
        }
        return address
    }

    /// 缓存地址
    private func cacheAddress(_ address: String, for key: String) {
        addressCache[key] = address
        addressCacheTimestamps[key] = Date()

        // 清理过期缓存
        if addressCache.count > 200 {
            let now = Date()
            addressCacheTimestamps = addressCacheTimestamps.filter { _, timestamp in
                now.timeIntervalSince(timestamp) < addressCacheTimeout
            }
            addressCache = addressCache.filter { key, _ in
                addressCacheTimestamps[key] != nil
            }
        }
    }
    
    /// 格式化地址信息
    private func formatPlacemark(_ placemark: CLPlacemark) -> String {
        var components: [String] = []
        
        // 优先使用更具体的位置信息
        if let name = placemark.name, !name.isEmpty {
            components.append(name)
        }
        
        if let subLocality = placemark.subLocality, !subLocality.isEmpty {
            components.append(subLocality)
        }
        
        if let locality = placemark.locality, !locality.isEmpty {
            components.append(locality)
        }
        
        if let subAdministrativeArea = placemark.subAdministrativeArea, !subAdministrativeArea.isEmpty {
            components.append(subAdministrativeArea)
        }
        
        // 如果没有任何有用信息，返回默认值
        if components.isEmpty {
            return "未知位置"
        }
        
        // 限制长度，取前2-3个最重要的组件
        let result = components.prefix(3).joined(separator: " ")
        return result.isEmpty ? "未知位置" : result
    }

    /// 生成有意义的地址描述（当网络地理编码失败时使用）
    private func generateMeaningfulAddress(from location: CLLocation) -> String {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        // 根据坐标范围判断大致区域（中国范围）
        if lat >= 18.0 && lat <= 54.0 && lon >= 73.0 && lon <= 135.0 {
            // 在中国境内，尝试提供更有意义的描述
            if lat >= 39.4 && lat <= 41.0 && lon >= 115.4 && lon <= 117.5 {
                return "北京地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 30.4 && lat <= 31.9 && lon >= 120.8 && lon <= 122.1 {
                return "上海地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 22.4 && lat <= 23.8 && lon >= 113.1 && lon <= 114.6 {
                return "深圳地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 23.0 && lat <= 23.6 && lon >= 113.0 && lon <= 113.6 {
                return "广州地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 30.4 && lat <= 31.4 && lon >= 120.0 && lon <= 121.0 {
                return "杭州地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 31.1 && lat <= 32.0 && lon >= 118.6 && lon <= 119.2 {
                return "南京地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 30.4 && lat <= 31.0 && lon >= 114.0 && lon <= 114.6 {
                return "武汉地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 29.4 && lat <= 30.0 && lon >= 106.3 && lon <= 106.8 {
                return "重庆地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 30.5 && lat <= 31.0 && lon >= 104.0 && lon <= 104.2 {
                return "成都地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else if lat >= 36.0 && lat <= 36.4 && lon >= 120.2 && lon <= 120.5 {
                return "青岛地区 (\(String(format: "%.4f, %.4f", lat, lon)))"
            } else {
                // 其他中国城市区域
                return "位置 (\(String(format: "%.4f, %.4f", lat, lon)))"
            }
        } else {
            // 海外位置
            return "位置 (\(String(format: "%.4f, %.4f", lat, lon)))"
        }
    }

    /// 检查是否有位置权限
    var hasLocationPermission: Bool {
        #if os(iOS)
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        #else
        return false
        #endif
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            isLocationUpdating = false
            // 取消超时任务
            locationTimeoutTask?.cancel()
            locationTimeoutTask = nil

            guard let location = locations.first else {
                locationContinuation?.resume(returning: nil)
                locationContinuation = nil
                return
            }

            currentLocation = location

            // 添加到位置缓存队列
            locationCache.append(location)
            if locationCache.count > maxCacheSize {
                locationCache.removeFirst(locationCache.count - maxCacheSize)
            }

            print("位置更新: (\(location.coordinate.latitude), \(location.coordinate.longitude)), 精度: \(location.horizontalAccuracy)米, 时间: \(location.timestamp)")

            // 发布连续定位的更新
            locationUpdateSubject.send(location)
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
            // 如果当前不是连续模式（一次性定位），拿到首个结果后立即停止
            if !isContinuousMode {
                manager.stopUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            isLocationUpdating = false
            // 取消超时任务
            locationTimeoutTask?.cancel()
            locationTimeoutTask = nil

            locationContinuation?.resume(throwing: error)
            locationContinuation = nil
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
}

// MARK: - LocationError
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationUnavailable
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "位置权限被拒绝"
        case .locationUnavailable:
            return "无法获取位置信息"
        case .timeout:
            return "位置获取超时"
        }
    }
}