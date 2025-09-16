import Foundation
import CoreLocation
import Combine

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
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5.0 // 改为5米更新一次，获得更详细的路径
        locationManager.pausesLocationUpdatesAutomatically = false // 改为false，防止系统自动暂停
        locationManager.activityType = .automotiveNavigation // 设置为汽车导航类型
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
    
    /// 后台连续定位：开始持续更新
    func startContinuousUpdates(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest, distanceFilter: CLLocationDistance = 10.0) {
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter // 使用传入的参数，默认为10米
        locationManager.activityType = .automotiveNavigation // 确保设置为汽车导航类型
        // 仅当 Info.plist 开启了 Background Modes -> location 时，才允许后台定位
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        let canBackgroundLocation = backgroundModes.contains("location")
        locationManager.allowsBackgroundLocationUpdates = canBackgroundLocation
        locationManager.pausesLocationUpdatesAutomatically = false // 确保不会自动暂停
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = canBackgroundLocation
        }
        locationManager.startUpdatingLocation()
        isContinuousMode = true
        print("开始连续定位 - 精度: \(desiredAccuracy), 距离过滤: \(distanceFilter)米, 后台定位: \(canBackgroundLocation)")
    }
    
    /// 后台连续定位：停止持续更新
    func stopContinuousUpdates() {
        locationManager.stopUpdatingLocation()
        if #available(iOS 11.0, *) {
            locationManager.showsBackgroundLocationIndicator = false
        }
        // 恢复为默认（前台）模式
        locationManager.allowsBackgroundLocationUpdates = false
        locationManager.pausesLocationUpdatesAutomatically = true
        isContinuousMode = false
    }
    
    /// 在已授权“使用期间”后，尝试申请“始终允许”权限
    func requestAlwaysAuthorizationIfEligible() {
        if authorizationStatus == .authorizedWhenInUse {
            print("请求始终允许权限")
            locationManager.requestAlwaysAuthorization()
        }
    }
    
    /// 获取当前位置（一次性，尽快返回）：
    /// - 优先返回系统缓存的最近位置（若在 staleThreshold 内）
    /// - 否则短暂开启 startUpdatingLocation，加速首次定位
    func getCurrentLocation(timeout: TimeInterval = 8.0, staleThreshold: TimeInterval = 120.0) async throws -> CLLocation? {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
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
    
    /// 从坐标获取地址描述
    func getLocationDescription(from location: CLLocation) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return "未知位置"
            }
            
            await MainActor.run {
                self.currentPlacemark = placemark
            }
            
            return formatPlacemark(placemark)
        } catch {
            return "未知位置"
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
    
    /// 检查是否有位置权限
    var hasLocationPermission: Bool {
        return authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
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
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocationUpdating = false
        // 取消超时任务
        locationTimeoutTask?.cancel()
        locationTimeoutTask = nil
        
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
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