import Foundation
import CoreLocation

// 定义LocationService协议
protocol LocationServiceProtocol {
    var hasLocationPermission: Bool { get }
    func getCurrentLocation(timeout: TimeInterval) async throws -> CLLocation?
    func getLocationDescription(from location: CLLocation) async -> String
}