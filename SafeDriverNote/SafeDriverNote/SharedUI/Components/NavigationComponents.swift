import SwiftUI

// MARK: - Custom Navigation Bar
struct BrandNavigationBar<Leading: View, Center: View, Trailing: View>: View {
    let leading: Leading
    let center: Center
    let trailing: Trailing
    let backgroundColor: Color
    
    init(
        backgroundColor: Color = .white,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder center: () -> Center,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.backgroundColor = backgroundColor
        self.leading = leading()
        self.center = center()
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack {
            HStack {
                leading
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            center
                .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                trailing
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: Spacing.navBarHeight)
        .padding(.horizontal, Spacing.cardPadding)
        .padding(.top, 0)
        .background(
            Rectangle()
                .fill(backgroundColor)
        )
        .overlay(
            Rectangle()
                .fill(Color.brandSecondary300)
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
}

// MARK: - Standard Navigation Bar
struct StandardNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let backAction: (() -> Void)?
    let trailingButtons: [NavBarButton]
    
    struct NavBarButton {
        let icon: String
        let action: () -> Void
        
        init(icon: String, action: @escaping () -> Void) {
            self.icon = icon
            self.action = action
        }
    }
    
    init(
        title: String,
        showBackButton: Bool = true,
        backAction: (() -> Void)? = nil,
        trailingButtons: [NavBarButton] = []
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.backAction = backAction
        self.trailingButtons = trailingButtons
    }
    
    var body: some View {
        BrandNavigationBar(
            leading: {
                if showBackButton {
                    Button(action: backAction ?? {}) {
                        Image(systemName: "chevron.left")
                            .font(.bodyLarge)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary700)
                    }
                    .iconStyle(size: 40, backgroundColor: .brandSecondary100)
                } else {
                    Spacer()
                }
            },
            center: {
                Text(title)
                    .font(.navTitle)
                    .foregroundColor(.brandSecondary900)
            },
            trailing: {
                HStack(spacing: Spacing.md) {
                    ForEach(0..<trailingButtons.count, id: \.self) { index in
                        let button = trailingButtons[index]
                        Button(action: button.action) {
                            Image(systemName: button.icon)
                                .font(.bodyLarge)
                                .foregroundColor(.brandSecondary700)
                        }
                        .iconStyle(size: 40, backgroundColor: .brandSecondary100)
                    }
                }
            }
        )
    }
}

// MARK: - Bottom Navigation Bar
struct BottomNavigationBar: View {
    @Binding var selectedTab: Tab
    
    enum Tab: String, CaseIterable {
        case home = "首页"
        case driveLog = "日志"
        case checklist = "检查"
        case knowledge = "学习"
        case profile = "我的"
        
        var icon: String {
            switch self {
            case .home: return "house"
            case .driveLog: return "doc.text"
            case .checklist: return "checklist"
            case .knowledge: return "book"
            case .profile: return "person"
            }
        }
        
        var selectedIcon: String {
            switch self {
            case .home: return "house.fill"
            case .driveLog: return "doc.text.fill"
            case .checklist: return "checklist"
            case .knowledge: return "book.fill"
            case .profile: return "person.fill"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(Animation.standard) {
                        selectedTab = tab
                    }
                }) {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: selectedTab == tab ? tab.selectedIcon : tab.icon)
                            .font(.title3)
                            .foregroundColor(selectedTab == tab ? .brandPrimary500 : .brandSecondary500)
                            .animation(Animation.quickFade, value: selectedTab)
                        
                        Text(tab.rawValue)
                            .font(.navLabel)
                            .foregroundColor(selectedTab == tab ? .brandPrimary500 : .brandSecondary500)
                            .animation(Animation.quickFade, value: selectedTab)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .frame(height: Spacing.bottomNavHeight)
        .background(
            Rectangle()
                .fill(Color.white)
                .shadow(
                    color: Shadow.md.color,
                    radius: Shadow.md.radius,
                    x: Shadow.md.x,
                    y: -Shadow.md.y
                )
        )
        .overlay(
            Rectangle()
                .fill(Color.brandSecondary300)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

// MARK: - Tab Bar Item Component
struct TabBarItem: View {
    let icon: String
    let selectedIcon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    init(
        icon: String,
        selectedIcon: String? = nil,
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: isSelected ? selectedIcon : icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .brandPrimary500 : .brandSecondary500)
                
                Text(title)
                    .font(.navLabel)
                    .foregroundColor(isSelected ? .brandPrimary500 : .brandSecondary500)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Segmented Control Component
struct BrandSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let options: [T]
    let displayText: (T) -> String
    
    init(
        selection: Binding<T>,
        options: [T],
        displayText: @escaping (T) -> String
    ) {
        self._selection = selection
        self.options = options
        self.displayText = displayText
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.element) { index, option in
                Button(action: {
                    withAnimation(Animation.standard) {
                        selection = option
                    }
                }) {
                    Text(displayText(option))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(selection == option ? .white : .brandSecondary700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(
                            RoundedRectangle(
                                cornerRadius: CornerRadius.md,
                                style: .continuous
                            )
                            .fill(selection == option ? Color.brandPrimary500 : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(Color.brandSecondary100)
        )
    }
}

// MARK: - Breadcrumb Component
struct Breadcrumb: View {
    let items: [BreadcrumbItem]
    
    struct BreadcrumbItem {
        let title: String
        let action: (() -> Void)?
        
        init(title: String, action: (() -> Void)? = nil) {
            self.title = title
            self.action = action
        }
    }
    
    init(items: [BreadcrumbItem]) {
        self.items = items
    }
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.brandSecondary500)
                }
                
                if let action = item.action {
                    Button(action: action) {
                        Text(item.title)
                            .font(.bodySmall)
                            .foregroundColor(.brandPrimary500)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Text(item.title)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary700)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, Spacing.cardPadding)
        .padding(.vertical, Spacing.md)
        .background(Color.brandSecondary50)
    }
}