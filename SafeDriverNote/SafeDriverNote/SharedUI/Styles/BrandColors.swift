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

	// Primary
	static let brandPrimary50  = Color(hex: "#E8F5E8")
	static let brandPrimary100 = Color(hex: "#C3E6C3")
	static let brandPrimary500 = Color(hex: "#22C55E")
	static let brandPrimary600 = Color(hex: "#16A34A")
	static let brandPrimary700 = Color(hex: "#15803D")

	// Secondary
	static let brandSecondary25  = Color(hex: "#FCFCFD")
	static let brandSecondary50  = Color(hex: "#F8FAFC")
	static let brandSecondary100 = Color(hex: "#F1F5F9")
	static let brandSecondary200 = Color(hex: "#E2E8F0")
	static let brandSecondary300 = Color(hex: "#CBD5E1")
	static let brandSecondary400 = Color(hex: "#94A3B8")
	static let brandSecondary500 = Color(hex: "#64748B")
	static let brandSecondary600 = Color(hex: "#475569")
	static let brandSecondary700 = Color(hex: "#334155")
	static let brandSecondary900 = Color(hex: "#0F172A")

	// Functional
	static let brandWarning100 = Color(hex: "#FEF3C7")
	static let brandWarning500 = Color(hex: "#F59E0B")
	static let brandWarning600 = Color(hex: "#D97706")

	static let brandDanger100 = Color(hex: "#FEE2E2")
	static let brandDanger500 = Color(hex: "#EF4444")
	static let brandDanger600 = Color(hex: "#DC2626")

	static let brandInfo100 = Color(hex: "#DBEAFE")
	static let brandInfo500 = Color(hex: "#3B82F6")
	static let brandInfo600 = Color(hex: "#2563EB")

	static let brandSuccess100 = Color(hex: "#DCFCE7")
	static let brandSuccess500 = Color(hex: "#22C55E")
	static let brandSuccess700 = Color(hex: "#15803D")
}