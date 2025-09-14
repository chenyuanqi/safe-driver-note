import SwiftUI

// Design tokens: colors from design/design-system/colors.md
extension Color {
	/// Initialize Color from hex string like "#RRGGBB" or "RRGGBB".
	init(hex: String, alpha: Double = 1.0) {
		let hexString = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
		var int: UInt64 = 0
		Scanner(string: hexString).scanHexInt64(&int)
		let r, g, b: UInt64
		switch hexString.count {
		case 6:
			r = (int >> 16) & 0xFF
			g = (int >> 8) & 0xFF
			b = int & 0xFF
		default:
			r = 1; g = 1; b = 1
		}
		self.init(.sRGB, red: Double(r) / 255.0, green: Double(g) / 255.0, blue: Double(b) / 255.0, opacity: alpha)
	}

	/// Create adaptive color that changes based on color scheme
	static func adaptive(light: Color, dark: Color) -> Color {
		return Color(UIColor { traits in
			traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
		})
	}

	// MARK: - Primary Colors (Brand Green - consistent across themes)
	static let brandPrimary50  = adaptive(
		light: Color(hex: "#E8F5E8"),
		dark: Color(hex: "#0F2A0F")
	)
	static let brandPrimary100 = adaptive(
		light: Color(hex: "#C3E6C3"),
		dark: Color(hex: "#1A3D1A")
	)
	static let brandPrimary500 = adaptive(
		light: Color(hex: "#22C55E"),
		dark: Color(hex: "#22C55E")  // Keep brand color consistent
	)
	static let brandPrimary600 = adaptive(
		light: Color(hex: "#16A34A"),
		dark: Color(hex: "#16A34A")
	)
	static let brandPrimary700 = adaptive(
		light: Color(hex: "#15803D"),
		dark: Color(hex: "#15803D")
	)

	// MARK: - Secondary Colors (Grays - adaptive for readability)
	static let brandSecondary25  = adaptive(
		light: Color(hex: "#FCFCFD"),
		dark: Color(hex: "#0A0A0B")
	)
	static let brandSecondary50  = adaptive(
		light: Color(hex: "#F8FAFC"),
		dark: Color(hex: "#111213")
	)
	static let brandSecondary100 = adaptive(
		light: Color(hex: "#F1F5F9"),
		dark: Color(hex: "#1A1D1E")
	)
	static let brandSecondary200 = adaptive(
		light: Color(hex: "#E2E8F0"),
		dark: Color(hex: "#2D3238")
	)
	static let brandSecondary300 = adaptive(
		light: Color(hex: "#CBD5E1"),
		dark: Color(hex: "#4A525A")
	)
	static let brandSecondary400 = adaptive(
		light: Color(hex: "#94A3B8"),
		dark: Color(hex: "#64748B")
	)
	static let brandSecondary500 = adaptive(
		light: Color(hex: "#64748B"),
		dark: Color(hex: "#94A3B8")
	)
	static let brandSecondary600 = adaptive(
		light: Color(hex: "#475569"),
		dark: Color(hex: "#CBD5E1")
	)
	static let brandSecondary700 = adaptive(
		light: Color(hex: "#334155"),
		dark: Color(hex: "#E2E8F0")
	)
	static let brandSecondary900 = adaptive(
		light: Color(hex: "#0F172A"),
		dark: Color(hex: "#F8FAFC")
	)

	// MARK: - Functional Colors (Status colors - adaptive)
	static let brandWarning100 = adaptive(
		light: Color(hex: "#FEF3C7"),
		dark: Color(hex: "#2D2008")
	)
	static let brandWarning500 = adaptive(
		light: Color(hex: "#F59E0B"),
		dark: Color(hex: "#F59E0B")  // Keep warning color visible
	)
	static let brandWarning600 = adaptive(
		light: Color(hex: "#D97706"),
		dark: Color(hex: "#E4920F")
	)

	static let brandDanger100 = adaptive(
		light: Color(hex: "#FEE2E2"),
		dark: Color(hex: "#2D0A0A")
	)
	static let brandDanger500 = adaptive(
		light: Color(hex: "#EF4444"),
		dark: Color(hex: "#EF4444")  // Keep danger color visible
	)
	static let brandDanger600 = adaptive(
		light: Color(hex: "#DC2626"),
		dark: Color(hex: "#F56565")
	)

	static let brandInfo100 = adaptive(
		light: Color(hex: "#DBEAFE"),
		dark: Color(hex: "#0F1D2E")
	)
	static let brandInfo500 = adaptive(
		light: Color(hex: "#3B82F6"),
		dark: Color(hex: "#3B82F6")  // Keep info color visible
	)
	static let brandInfo600 = adaptive(
		light: Color(hex: "#2563EB"),
		dark: Color(hex: "#60A5FA")
	)

	static let brandSuccess100 = adaptive(
		light: Color(hex: "#DCFCE7"),
		dark: Color(hex: "#0F2A0F")
	)
	static let brandSuccess500 = adaptive(
		light: Color(hex: "#22C55E"),
		dark: Color(hex: "#22C55E")  // Keep success color visible
	)
	static let brandSuccess700 = adaptive(
		light: Color(hex: "#15803D"),
		dark: Color(hex: "#4ADE80")
	)

	// MARK: - Semantic Colors (UI Components)
	/// 卡片背景色 - 在浅色模式下为白色，深色模式下为深灰
	static let cardBackground = adaptive(
		light: Color.white,
		dark: Color(hex: "#1F2937")
	)

	/// 页面背景色 - 在浅色模式下为浅灰，深色模式下为黑色
	static let pageBackground = adaptive(
		light: Color(hex: "#F8FAFC"),
		dark: Color(hex: "#111213")
	)

	/// 分隔线颜色
	static let separatorColor = adaptive(
		light: Color(hex: "#E2E8F0"),
		dark: Color(hex: "#374151")
	)

	/// 输入框背景色
	static let inputBackground = adaptive(
		light: Color.white,
		dark: Color(hex: "#374151")
	)
}