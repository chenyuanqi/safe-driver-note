import SwiftUI
import Foundation

// MARK: - Theme Types
enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager
@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published private(set) var currentTheme: AppTheme = .system
    @Published private(set) var colorScheme: ColorScheme?

    private let userDefaults = UserDefaults.standard
    private let themeKey = "app_theme"

    private init() {
        loadSavedTheme()
        updateColorScheme()
    }

    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        userDefaults.set(theme.rawValue, forKey: themeKey)
        updateColorScheme()
    }

    private func loadSavedTheme() {
        if let savedThemeString = userDefaults.string(forKey: themeKey),
           let savedTheme = AppTheme(rawValue: savedThemeString) {
            currentTheme = savedTheme
        } else {
            currentTheme = .system
        }
    }

    private func updateColorScheme() {
        colorScheme = currentTheme.colorScheme
    }

    var isDarkMode: Bool {
        switch currentTheme {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            // 在实际应用中，这里应该检查系统的当前模式
            // 但由于SwiftUI的限制，我们返回nil让系统自动处理
            return false
        }
    }

    var isSystemTheme: Bool {
        return currentTheme == .system
    }
}

// MARK: - Theme Environment Values
private struct ThemeManagerKey: EnvironmentKey {
    static let defaultValue = ThemeManager.shared
}

extension EnvironmentValues {
    var themeManager: ThemeManager {
        get { self[ThemeManagerKey.self] }
        set { self[ThemeManagerKey.self] = newValue }
    }
}

// MARK: - View Extensions
extension View {
    func themeManaged() -> some View {
        self.environment(\.themeManager, ThemeManager.shared)
            .environmentObject(ThemeManager.shared)
    }
}