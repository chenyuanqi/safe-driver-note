import SwiftUI

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyLarge)
            .foregroundColor(.white)
            .frame(minHeight: Spacing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(isDisabled ? Color.brandSecondary300 : Color.brandPrimary500)
            )
            .shadow(
                color: Shadow.lg.color,
                radius: Shadow.lg.radius,
                x: Shadow.lg.x,
                y: Shadow.lg.y
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Opacity.pressed : 1.0)
            .animation(Animation.standard, value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(isDisabled ? .brandSecondary300 : .brandSecondary700)
            .frame(minHeight: Spacing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(Color.brandSecondary100)
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                            .stroke(Color.brandSecondary300, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Opacity.pressed : 1.0)
            .animation(Animation.standard, value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

struct DangerButtonStyle: ButtonStyle {
    let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodyLarge)
            .foregroundColor(.white)
            .frame(minHeight: Spacing.buttonHeight)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(isDisabled ? Color.brandSecondary300 : Color.brandDanger500)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? Opacity.pressed : 1.0)
            .animation(Animation.standard, value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

struct CompactButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = .brandPrimary500) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.bodySmall)
            .foregroundColor(color)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(color.opacity(0.12))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? Opacity.pressed : 1.0)
            .animation(Animation.standard, value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let backgroundColor: Color?
    
    init(size: CGFloat = 40, backgroundColor: Color? = nil) {
        self.size = size
        self.backgroundColor = backgroundColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(.brandSecondary700)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                    .fill(backgroundColor ?? Color.clear)
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .opacity(configuration.isPressed ? Opacity.pressed : 1.0)
            .animation(Animation.standard, value: configuration.isPressed)
    }
}

struct FloatingActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title3)
            .foregroundColor(.white)
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(Color.brandPrimary500)
                    .shadow(
                        color: Shadow.xl.color,
                        radius: Shadow.xl.radius,
                        x: Shadow.xl.x,
                        y: Shadow.xl.y
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(Animation.bouncy, value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions
extension Button {
    func primaryStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isDisabled: isDisabled))
    }
    
    func secondaryStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(SecondaryButtonStyle(isDisabled: isDisabled))
    }
    
    func dangerStyle(isDisabled: Bool = false) -> some View {
        self.buttonStyle(DangerButtonStyle(isDisabled: isDisabled))
    }
    
    func compactStyle(color: Color = .brandPrimary500) -> some View {
        self.buttonStyle(CompactButtonStyle(color: color))
    }
    
    func iconStyle(size: CGFloat = 40, backgroundColor: Color? = nil) -> some View {
        self.buttonStyle(IconButtonStyle(size: size, backgroundColor: backgroundColor))
    }
    
    func floatingActionStyle() -> some View {
        self.buttonStyle(FloatingActionButtonStyle())
    }
}

// MARK: - Tag Style
struct TagStyle: ViewModifier {
    let type: TagType
    
    enum TagType {
        case primary
        case success
        case warning
        case error
        case neutral
        
        var backgroundColor: Color {
            switch self {
            case .primary: return .brandInfo100
            case .success: return .brandPrimary100
            case .warning: return .brandWarning100
            case .error: return .brandDanger100
            case .neutral: return .brandSecondary100
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary: return .brandInfo600
            case .success: return .brandPrimary700
            case .warning: return .brandWarning600
            case .error: return .brandDanger600
            case .neutral: return .brandSecondary500
            }
        }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.caption)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.xs)
            .background(
                Capsule()
                    .fill(type.backgroundColor)
            )
            .foregroundColor(type.foregroundColor)
    }
}

extension View {
    func tagStyle(_ type: TagStyle.TagType) -> some View {
        self.modifier(TagStyle(type: type))
    }
}