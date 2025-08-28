import Foundation
import CoreLocation
import Combine

@MainActor
class LocationService: NSObject, ObservableObject {
    static let shared = LocationService()
    
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var currentPlacemark: CLPlacemark?
    @Published var isLocationUpdating = false
    
    private var locationContinuation: CheckedContinuation<CLLocation?, Error>?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // 10米更新一次
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
    
    /// 获取当前位置（一次性）
    func getCurrentLocation() async throws -> CLLocation? {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.permissionDenied
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            self.isLocationUpdating = true
            locationManager.requestLocation()
        }
    }
    
    /// 获取当前位置的地址描述
    func getCurrentLocationDescription() async -> String {
        do {
            guard let location = try await getCurrentLocation() else {
                return "未知位置"
            }
            
            return await getLocationDescription(from: location)
        } catch {
            return "未知位置"
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
        
        guard let location = locations.first else {
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
            return
        }
        
        currentLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLocationUpdating = false
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