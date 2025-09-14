import SwiftUI

// MARK: - Base Card Component
struct Card<Content: View>: View {
    let content: Content
    let backgroundColor: Color
    let borderColor: Color?
    let padding: EdgeInsets
    let cornerRadius: CGFloat
    let shadow: Bool
    
    init(
        backgroundColor: Color = .cardBackground,
        borderColor: Color? = nil,
        padding: EdgeInsets = EdgeInsets(top: Spacing.cardPadding, leading: Spacing.cardPadding, bottom: Spacing.cardPadding, trailing: Spacing.cardPadding),
        cornerRadius: CGFloat = CornerRadius.lg,
        shadow: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadow = shadow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                    .overlay(
                        borderColor.map { color in
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .stroke(color, lineWidth: 1)
                        }
                    )
                    .shadow(
                        color: shadow ? Shadow.md.color : Color.clear,
                        radius: shadow ? Shadow.md.radius : 0,
                        x: shadow ? Shadow.md.x : 0,
                        y: shadow ? Shadow.md.y : 0
                    )
            )
    }
}

// MARK: - Status Card Component
struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    let icon: String?
    let onTap: (() -> Void)?  // 添加点击回调
    
    init(title: String, value: String, color: Color, icon: String? = nil, onTap: (() -> Void)? = nil) {
        self.title = title
        self.value = value
        self.color = color
        self.icon = icon
        self.onTap = onTap
    }
    
    var body: some View {
        Card(backgroundColor: color.opacity(0.08), shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundColor(color)
                    }
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)
            }
        }
        .onTapGesture {
            onTap?()
        }
    }
}

// MARK: - Action Card Component
struct ActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    init(title: String, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Card(backgroundColor: color.opacity(0.12), shadow: false) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.bodyLarge)
                        .foregroundColor(color)
                        .fontWeight(.medium)
                    
                    Spacer()
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - List Item Card Component
struct ListItemCard<Content: View>: View {
    let leadingIcon: String?
    let leadingColor: Color?
    let content: Content
    let trailingContent: (() -> AnyView)?
    let backgroundColor: Color
    
    init(
        leadingIcon: String? = nil,
        leadingColor: Color? = nil,
        backgroundColor: Color = .brandSecondary100,
        trailingContent: (() -> AnyView)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.leadingIcon = leadingIcon
        self.leadingColor = leadingColor
        self.backgroundColor = backgroundColor
        self.trailingContent = trailingContent
        self.content = content()
    }
    
    var body: some View {
        Card(backgroundColor: backgroundColor, shadow: false) {
            HStack(spacing: Spacing.lg) {
                if let leadingIcon = leadingIcon {
                    Image(systemName: leadingIcon)
                        .font(.title3)
                        .foregroundColor(leadingColor ?? .brandSecondary500)
                        .frame(width: 24, height: 24)
                }
                
                content
                
                Spacer()
                
                trailingContent?()
            }
        }
    }
}

// MARK: - Info Banner Component
struct InfoBanner: View {
    let message: String
    let type: BannerType
    let onDismiss: (() -> Void)?
    
    enum BannerType {
        case info, success, warning, error
        
        var color: Color {
            switch self {
            case .info: return .brandInfo500
            case .success: return .brandPrimary500
            case .warning: return .brandWarning500
            case .error: return .brandDanger500
            }
        }
        
        var backgroundColor: Color {
            switch self {
            case .info: return .brandInfo100
            case .success: return .brandPrimary100
            case .warning: return .brandWarning100
            case .error: return .brandDanger100
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
    }
    
    init(message: String, type: BannerType, onDismiss: (() -> Void)? = nil) {
        self.message = message
        self.type = type
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        Card(
            backgroundColor: type.backgroundColor,
            borderColor: type.color,
            shadow: false
        ) {
            HStack(spacing: Spacing.lg) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                    .font(.body)
                
                Text(message)
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary700)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.brandSecondary500)
                    }
                    .iconStyle(size: 24)
                }
            }
        }
    }
}

// MARK: - Empty State Component
struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Spacing.xl) {
            VStack(spacing: Spacing.lg) {
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                
                VStack(spacing: Spacing.sm) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .primaryStyle()
                    .frame(maxWidth: 200)
            }
        }
        .padding(.horizontal, Spacing.xxxxl)
        .padding(.vertical, Spacing.xxxl)
    }
}

// MARK: - Progress Card Component
struct ProgressCard: View {
    let title: String
    let progress: Double // 0.0 to 1.0
    let color: Color
    let showPercentage: Bool
    
    init(title: String, progress: Double, color: Color = .brandPrimary500, showPercentage: Bool = true) {
        self.title = title
        self.progress = max(0, min(1, progress))
        self.color = color
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        Card(shadow: false) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text(title)
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int(progress * 100))%")
                            .font(.bodySmall)
                            .fontWeight(.semibold)
                            .foregroundColor(color)
                    }
                }
                
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: color))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
            }
        }
    }
}

// MARK: - Expandable Card Component
struct ExpandableCard<Header: View, Content: View>: View {
    @State private var isExpanded = false
    
    let header: Header
    let content: Content
    let backgroundColor: Color
    
    init(
        backgroundColor: Color = .cardBackground,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.backgroundColor = backgroundColor
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        Card(backgroundColor: backgroundColor) {
            VStack(spacing: 0) {
                Button(action: { 
                    withAnimation(Animation.bouncy) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack {
                        header
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(Animation.standard, value: isExpanded)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                if isExpanded {
                    content
                        .padding(.top, Spacing.lg)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
            }
        }
    }
}