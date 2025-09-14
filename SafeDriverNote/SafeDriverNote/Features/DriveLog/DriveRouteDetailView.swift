import SwiftUI
import MapKit

struct DriveRouteDetailView: View {
    let route: DriveRoute
    @EnvironmentObject private var di: AppDI
    
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // 路线概览卡片
                routeOverviewCard
                
                // 路线地图卡片
                if route.startLocation != nil || route.endLocation != nil {
                    routeMapCard
                }
                
                // 时间信息卡片
                timeInfoCard
                
                // 位置信息卡片
                if route.startLocation != nil || route.endLocation != nil {
                    locationInfoCard
                }
                
                // 状态信息卡片
                statusInfoCard
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.brandSecondary50)
        .navigationTitle("驾驶记录详情")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Route Overview Card
    private var routeOverviewCard: some View {
        Card(shadow: true) {
            VStack(spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "car.fill")
                        .font(.title2)
                        .foregroundColor(Color.brandPrimary500)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("驾驶路线")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.brandSecondary900)
                        
                        Text(routeTitle)
                            .font(.body)
                            .foregroundColor(Color.brandSecondary700)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                }
                
                if let duration = route.duration, let distance = route.distance {
                    HStack(spacing: Spacing.xl) {
                        VStack(spacing: Spacing.xs) {
                            Text("驾驶时长")
                                .font(.caption)
                                .foregroundColor(Color.brandSecondary500)
                            
                            Text(formatDuration(duration))
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.brandSecondary900)
                        }
                        
                        VStack(spacing: Spacing.xs) {
                            Text("行驶距离")
                                .font(.caption)
                                .foregroundColor(Color.brandSecondary500)
                            
                            Text(formatDistance(distance))
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.brandSecondary900)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    // MARK: - Time Info Card
    private var timeInfoCard: some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "clock")
                        .font(.title3)
                        .foregroundColor(Color.brandInfo500)
                    
                    Text("时间信息")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.brandSecondary900)
                    
                    Spacer()
                }
                
                VStack(spacing: Spacing.md) {
                    timeInfoRow(
                        icon: "play.circle",
                        title: "开始时间",
                        value: formatDateTime(route.startTime),
                        color: Color.brandPrimary500
                    )
                    
                    if let endTime = route.endTime {
                        timeInfoRow(
                            icon: "stop.circle",
                            title: "结束时间",
                            value: formatDateTime(endTime),
                            color: Color.brandDanger500
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Location Info Card
    private var locationInfoCard: some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "location")
                        .font(.title3)
                        .foregroundColor(Color.brandWarning500)
                    
                    Text("位置信息")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.brandSecondary900)
                    
                    Spacer()
                }
                
                VStack(spacing: Spacing.md) {
                    if let startLocation = route.startLocation {
                        locationInfoRow(
                            icon: "location.circle",
                            title: "出发地点",
                            address: startLocation.address,
                            coordinates: "(\(String(format: "%.6f", startLocation.latitude)), \(String(format: "%.6f", startLocation.longitude)))",
                            color: Color.brandPrimary500
                        )
                    }
                    
                    if let endLocation = route.endLocation {
                        locationInfoRow(
                            icon: "location.circle.fill",
                            title: "到达地点",
                            address: endLocation.address,
                            coordinates: "(\(String(format: "%.6f", endLocation.latitude)), \(String(format: "%.6f", endLocation.longitude)))",
                            color: Color.brandDanger500
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Route Map Card
    private var routeMapCard: some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "map")
                        .font(.title3)
                        .foregroundColor(Color.brandPrimary500)
                    
                    Text("路线地图")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.brandSecondary900)
                    
                    Spacer()
                }
                
                // 地图视图
                RouteMapView(route: route)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous))
            }
        }
    }
    
    // MARK: - Status Info Card
    private var statusInfoCard: some View {
        Card(shadow: true) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Image(systemName: "info.circle")
                        .font(.title3)
                        .foregroundColor(Color.brandSecondary500)
                    
                    Text("状态信息")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.brandSecondary900)
                    
                    Spacer()
                }
                
                HStack {
                    Text("记录状态")
                        .font(.body)
                        .foregroundColor(Color.brandSecondary700)
                    
                    Spacer()
                    
                    Text(route.status.displayName)
                        .tagStyle(statusTagType)
                }
                
                if let notes = route.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("备注")
                            .font(.body)
                            .foregroundColor(Color.brandSecondary700)
                        
                        Text(notes)
                            .font(.body)
                            .foregroundColor(Color.brandSecondary900)
                            .padding(.top, Spacing.xs)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Views
    private func timeInfoRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.brandSecondary500)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(Color.brandSecondary900)
            }
            
            Spacer()
        }
    }
    
    private func locationInfoRow(icon: String, title: String, address: String, coordinates: String, color: Color) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(Color.brandSecondary500)
                
                Text(address)
                    .font(.body)
                    .foregroundColor(Color.brandSecondary900)
                
                Text(coordinates)
                    .font(.caption)
                    .foregroundColor(Color.brandSecondary400)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Computed Properties
    private var routeTitle: String {
        if let start = route.startLocation?.address, let end = route.endLocation?.address {
            return "\(start) → \(end)"
        } else if let start = route.startLocation?.address {
            return "从 \(start) 出发"
        } else if let end = route.endLocation?.address {
            return "抵达 \(end)"
        } else {
            return "驾驶记录"
        }
    }
    
    private var statusTagType: TagStyle.TagType {
        switch route.status {
        case .active:
            return .warning
        case .completed:
            return .success
        case .cancelled:
            return .error
        }
    }
    
    // MARK: - Helper Methods
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)小时\(minutes)分钟"
        } else {
            return "\(minutes)分钟"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f公里", distance / 1000)
        } else {
            return String(format: "%.0f米", distance)
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Route Map View
struct RouteMapView: View {
    let route: DriveRoute
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedItem: MapFeature?
    
    var body: some View {
        Map(position: $cameraPosition, selection: $selectedItem) {
            Group {
                // 添加起始位置标记
                if let startLocation = route.startLocation {
                    Marker("出发地", coordinate: CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude))
                        .tint(Color.brandPrimary500)
                }
                
                // 添加结束位置标记
                if let endLocation = route.endLocation {
                    Marker("到达地", coordinate: CLLocationCoordinate2D(latitude: endLocation.latitude, longitude: endLocation.longitude))
                        .tint(Color.brandDanger500)
                }
                
                // 添加路线
                if let waypoints = route.waypoints, !waypoints.isEmpty {
                    // 如果有路径点，绘制路线
                    let coordinates = createCoordinatesWithWaypoints(waypoints)
                    MapPolyline(coordinates: coordinates)
                        .stroke(Color.brandPrimary500, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                } else if let startLocation = route.startLocation, let endLocation = route.endLocation {
                    // 如果只有起终点，绘制直线
                    MapPolyline(coordinates: [
                        CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude),
                        CLLocationCoordinate2D(latitude: endLocation.latitude, longitude: endLocation.longitude)
                    ])
                    .stroke(Color.brandPrimary500, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .mapStyle(.standard)
        .onAppear {
            updateCameraPosition()
        }
    }
    
    // 创建包含路径点的坐标数组
    private func createCoordinatesWithWaypoints(_ waypoints: [RouteLocation]) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        
        // 添加起始位置（如果有）
        if let startLocation = route.startLocation {
            coordinates.append(CLLocationCoordinate2D(
                latitude: startLocation.latitude,
                longitude: startLocation.longitude
            ))
        }
        
        // 添加所有中间路径点
        for waypoint in waypoints {
            coordinates.append(CLLocationCoordinate2D(
                latitude: waypoint.latitude,
                longitude: waypoint.longitude
            ))
        }
        
        // 添加结束位置（如果有）
        if let endLocation = route.endLocation {
            coordinates.append(CLLocationCoordinate2D(
                latitude: endLocation.latitude,
                longitude: endLocation.longitude
            ))
        }
        
        return coordinates
    }
    
    private func updateCameraPosition() {
        var coordinates: [CLLocationCoordinate2D] = []
        
        // 收集所有坐标点
        if let startLocation = route.startLocation {
            coordinates.append(CLLocationCoordinate2D(latitude: startLocation.latitude, longitude: startLocation.longitude))
        }
        
        if let waypoints = route.waypoints, !waypoints.isEmpty {
            for waypoint in waypoints {
                coordinates.append(CLLocationCoordinate2D(latitude: waypoint.latitude, longitude: waypoint.longitude))
            }
        }
        
        if let endLocation = route.endLocation {
            coordinates.append(CLLocationCoordinate2D(latitude: endLocation.latitude, longitude: endLocation.longitude))
        }
        
        // 如果没有坐标点，则返回
        if coordinates.isEmpty {
            return
        }
        
        // 计算所有点的边界
        var minLat = coordinates[0].latitude
        var maxLat = coordinates[0].latitude
        var minLon = coordinates[0].longitude
        var maxLon = coordinates[0].longitude
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        // 计算中心点和距离
        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2
        
        let latDelta = max(maxLat - minLat, 0.01) // 最小值避免过度放大
        let lonDelta = max(maxLon - minLon, 0.01)
        
        // 添加一些边距以便更好地显示整个路线
        let span = MKCoordinateSpan(
            latitudeDelta: latDelta * 1.2,
            longitudeDelta: lonDelta * 1.2
        )
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon),
            span: span
        )
        
        cameraPosition = .region(region)
    }
}

#Preview {
    NavigationStack {
        DriveRouteDetailView(
            route: DriveRoute(
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date(),
                startLocation: RouteLocation(
                    latitude: 39.9042,
                    longitude: 116.4074,
                    address: "北京市朝阳区"
                ),
                endLocation: RouteLocation(
                    latitude: 39.9289,
                    longitude: 116.3883,
                    address: "北京市西城区"
                ),
                waypoints: [
                    RouteLocation(
                        latitude: 39.9100,
                        longitude: 116.4000,
                        address: "北京市东城区中间点"
                    ),
                    RouteLocation(
                        latitude: 39.9150,
                        longitude: 116.3950,
                        address: "北京市东城区中间点二"
                    ),
                    RouteLocation(
                        latitude: 39.9200,
                        longitude: 116.3900,
                        address: "北京市西城区中间点"
                    )
                ],
                distance: 15000,
                duration: 3600,
                status: .completed
            )
        )
        .environmentObject(AppDI.shared)
    }
}