import SwiftUI
import CoreLocation
import Foundation

struct LocationPermissionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI

    @State private var showingLocationAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isLoading = false

    private var locationService: LocationService {
        di.locationService
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 位置权限状态
                    locationStatusSection

                    // 权限说明
                    permissionExplanationSection

                    // 功能说明
                    featureExplanationSection

                    // 操作按钮
                    actionButtonsSection
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("位置权限")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // LocationService已经在监听状态变化
            }
            .alert(alertTitle, isPresented: $showingLocationAlert) {
                Button("确定") { }
                if alertTitle.contains("升级") {
                    Button("前往设置") {
                        openAppSettings()
                    }
                } else if alertTitle.contains("前往设置") {
                    Button("前往设置") {
                        openAppSettings()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }

    // MARK: - 位置权限状态
    private var locationStatusSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("当前状态")

            Card(shadow: true) {
                HStack(spacing: Spacing.lg) {
                    // 状态图标
                    Circle()
                        .fill(statusColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: statusIcon)
                                .font(.title2)
                                .foregroundColor(statusColor)
                        )

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(statusTitle)
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text(statusDescription)
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer()
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 权限说明
    private var permissionExplanationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("权限说明")

            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    explanationItem(
                        icon: "location.fill",
                        title: "精确位置",
                        description: "获取您的精确位置信息，用于记录驾驶起点和终点"
                    )

                    Divider()

                    explanationItem(
                        icon: "map.fill",
                        title: "路线记录",
                        description: "记录您的驾驶路径，用于里程统计和路线分析"
                    )

                    Divider()

                    explanationItem(
                        icon: "location.circle.fill",
                        title: "检查点定位",
                        description: "在行前和行后检查时记录位置信息"
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 功能说明
    private var featureExplanationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("功能介绍")

            Card(shadow: true) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("启用位置服务后，您可以享受以下功能：")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        featureItem("自动记录驾驶路线和里程")
                        featureItem("智能识别出发地和目的地")
                        featureItem("提供更准确的安全评分")
                        featureItem("生成详细的驾驶报告")
                    }

                    Text("我们承诺：")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                        .padding(.top, Spacing.md)

                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text("• 位置数据仅用于记录驾驶信息")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary600)

                        Text("• 所有数据存储在您的设备本地")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary600)

                        Text("• 不会上传或共享您的位置信息")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary600)
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 操作按钮
    private var actionButtonsSection: some View {
        VStack(spacing: Spacing.lg) {
            if locationService.authorizationStatus == .notDetermined {
                Button("请求位置权限") {
                    requestLocationPermission()
                }
                .primaryStyle()
                .disabled(isLoading)
            } else if locationService.authorizationStatus == .denied {
                Button("前往设置开启权限") {
                    openAppSettings()
                }
                .primaryStyle()
            } else if locationService.authorizationStatus == .authorizedWhenInUse {
                Button("升级为始终允许") {
                    showAlwaysAuthorizationAlert()
                }
                .secondaryStyle()
            }

            if isLoading {
                HStack(spacing: Spacing.sm) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("检查权限状态...")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }
            }
        }
    }

    // MARK: - Helper Views

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.brandSecondary900)
            .padding(.leading, Spacing.sm)
    }

    private func explanationItem(icon: String, title: String, description: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandInfo500)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.brandSecondary900)

                Text(description)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary600)
            }
        }
    }

    private func featureItem(_ text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("•")
                .font(.bodySmall)
                .foregroundColor(.brandPrimary500)
                .padding(.top, 2)

            Text(text)
                .font(.bodySmall)
                .foregroundColor(.brandSecondary600)
        }
    }

    // MARK: - Status Computed Properties

    private var statusColor: Color {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return .brandPrimary500
        case .authorizedWhenInUse:
            return .brandWarning500
        case .denied, .restricted:
            return .brandDanger500
        case .notDetermined:
            return .brandSecondary400
        @unknown default:
            return .brandSecondary400
        }
    }

    private var statusIcon: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "location.fill"
        case .authorizedWhenInUse:
            return "location"
        case .denied, .restricted:
            return "location.slash.fill"
        case .notDetermined:
            return "location.circle"
        @unknown default:
            return "location.circle"
        }
    }

    private var statusTitle: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "位置权限已开启"
        case .authorizedWhenInUse:
            return "仅应用使用时允许"
        case .denied:
            return "位置权限被拒绝"
        case .restricted:
            return "位置权限受限制"
        case .notDetermined:
            return "未设置位置权限"
        @unknown default:
            return "位置权限状态未知"
        }
    }

    private var statusDescription: String {
        switch locationService.authorizationStatus {
        case .authorizedAlways:
            return "应用可以在任何时候访问您的位置信息，功能完全可用"
        case .authorizedWhenInUse:
            return "应用仅在使用时可以访问位置信息，部分后台功能可能受限"
        case .denied:
            return "您已拒绝位置访问，无法使用路线记录等功能"
        case .restricted:
            return "位置访问受到限制，可能由家长控制或企业政策导致"
        case .notDetermined:
            return "尚未请求位置权限，点击下方按钮开启位置服务"
        @unknown default:
            return "无法确定当前的位置权限状态"
        }
    }

    // MARK: - Actions

    private func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            alertTitle = "位置服务未开启"
            alertMessage = "请在设备设置中开启位置服务，然后重新打开应用。"
            showingLocationAlert = true
            return
        }

        isLoading = true

        // 使用现有的LocationService来请求权限
        locationService.requestLocationPermission()

        // 延迟检查状态变化
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }

    private func showAlwaysAuthorizationAlert() {
        alertTitle = "升级位置权限"
        alertMessage = "要获得最佳体验，建议在设置中将位置权限改为「始终」，这样可以在后台自动记录驾驶路线。"
        showingLocationAlert = true

        // 使用LocationService申请始终允许权限
        locationService.requestAlwaysAuthorizationIfEligible()
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

#Preview {
    LocationPermissionView()
        .environmentObject(AppDI.shared)
}