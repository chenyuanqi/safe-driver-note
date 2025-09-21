import SwiftUI
import CoreLocation

struct LocationPermissionGuideView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.openURL) private var openURL
	@ObservedObject private var locationService = LocationService.shared

	var body: some View {
		NavigationStack {
			VStack(alignment: .leading, spacing: 16) {
				HStack(spacing: 12) {
					Image(systemName: "location.circle.fill")
						.font(.largeTitle)
						.foregroundColor(.brandPrimary500)
					VStack(alignment: .leading, spacing: 4) {
						Text("需要开启“始终允许”位置权限")
							.font(.title3)
							.fontWeight(.semibold)
						Text("用于后台记录行驶路线，即使切换到其他App或熄屏也能持续记录。")
							.font(.body)
							.foregroundColor(.brandSecondary700)
					}
				}

				statusSection
				stepsSection

				Spacer()

				primaryButtons
			}
			.padding(20)
			.navigationTitle("位置权限设置")
			.navigationBarTitleDisplayMode(.inline)
		}
		.onChange(of: locationService.authorizationStatus) { _, newStatus in
			if newStatus == .authorizedAlways { dismiss() }
		}
	}

	private var statusSection: some View {
		HStack {
			Text("当前状态：")
				.font(.body)
				.foregroundColor(.brandSecondary700)
			Text(statusText)
				.font(.body)
				.fontWeight(.medium)
				.foregroundColor(statusColor)
				.padding(.horizontal, 8)
				.padding(.vertical, 4)
				.background(statusColor.opacity(0.12))
				.clipShape(Capsule())
			Spacer()
		}
	}

	private var stepsSection: some View {
		VStack(alignment: .leading, spacing: 12) {
			Text("设置步骤：")
				.font(.headline)
				.foregroundColor(.brandSecondary900)
			VStack(alignment: .leading, spacing: 8) {
				Label("打开“设置 > 隐私与安全 > 定位服务”", systemImage: "1.circle")
				Label("找到“安全驾驶日志”，将权限改为“始终”", systemImage: "2.circle")
				Label("建议开启“精确位置”，提高记录准确度", systemImage: "3.circle")
			}
			.font(.body)
			.foregroundColor(.brandSecondary700)
		}
	}

	private var primaryButtons: some View {
		VStack(spacing: 12) {
			Button("前往设置") {
				if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
			}
			.primaryStyle()

			if locationService.authorizationStatus == .authorizedWhenInUse {
				Button("申请“始终允许”") {
					locationService.requestAlwaysAuthorizationIfEligible()
				}
				.secondaryStyle()
			}

			Button("暂不设置") { dismiss() }
			.foregroundColor(.brandSecondary500)
		}
	}

	private var statusText: String {
		switch locationService.authorizationStatus {
		case .authorizedAlways: return "已始终允许"
		case .authorizedWhenInUse: return "仅使用期间允许"
		case .denied: return "已拒绝"
		case .restricted: return "受限制"
		case .notDetermined: return "未选择"
		@unknown default: return "未知"
		}
	}

	private var statusColor: Color {
		switch locationService.authorizationStatus {
		case .authorizedAlways: return .brandPrimary500
		case .authorizedWhenInUse: return .brandWarning500
		case .denied, .restricted: return .brandDanger500
		case .notDetermined: return .brandSecondary500
		@unknown default: return .brandSecondary500
		}
	}
}

#Preview {
	LocationPermissionGuideView()
}

