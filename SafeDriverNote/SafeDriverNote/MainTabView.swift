import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: BottomNavigationBar.Tab = .home
    
    var body: some View {
        ZStack {
            // Content Views
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .driveLog:
                    LogListView()
                case .checklist:
                    ChecklistView()
                case .knowledge:
                    KnowledgeView()
                case .profile:
                    ProfileView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom Navigation
            VStack {
                Spacer()
                BottomNavigationBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Knowledge View (Placeholder)
struct KnowledgeView: View {
    var body: some View {
        VStack(spacing: 0) {
            StandardNavigationBar(
                title: "知识学习",
                showBackButton: false
            )
            
            ScrollView {
                VStack(spacing: Spacing.xxxl) {
                    EmptyStateCard(
                        icon: "book",
                        title: "知识卡片功能",
                        subtitle: "即将推出更多学习内容",
                        actionTitle: "敬请期待"
                    ) {
                        // Future implementation
                    }
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
        }
    }
}

// MARK: - Profile View (Placeholder)  
struct ProfileView: View {
    var body: some View {
        VStack(spacing: 0) {
            StandardNavigationBar(
                title: "我的",
                showBackButton: false
            )
            
            ScrollView {
                VStack(spacing: Spacing.xxxl) {
                    // User Profile Section
                    Card {
                        HStack(spacing: Spacing.lg) {
                            Circle()
                                .fill(Color.brandPrimary100)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.title2)
                                        .foregroundColor(.brandPrimary500)
                                )
                            
                            VStack(alignment: .leading, spacing: Spacing.sm) {
                                Text("安全驾驶员")
                                    .font(.bodyLarge)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.brandSecondary900)
                                
                                Text("已使用 30 天")
                                    .font(.bodySmall)
                                    .foregroundColor(.brandSecondary500)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    // Settings Section
                    VStack(spacing: Spacing.lg) {
                        Text("设置")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(spacing: Spacing.md) {
                            settingItem(icon: "bell", title: "通知设置", hasArrow: true)
                            settingItem(icon: "gear", title: "应用设置", hasArrow: true)
                            settingItem(icon: "questionmark.circle", title: "帮助反馈", hasArrow: true)
                            settingItem(icon: "info.circle", title: "关于我们", hasArrow: true)
                        }
                    }
                    
                    // Statistics Section
                    VStack(spacing: Spacing.lg) {
                        Text("我的统计")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing: Spacing.lg) {
                            StatusCard(
                                title: "总驾驶日志",
                                value: "156",
                                color: .brandInfo500,
                                icon: "car"
                            )
                            
                            StatusCard(
                                title: "安全天数",
                                value: "28",
                                color: .brandPrimary500,
                                icon: "shield.checkered"
                            )
                        }
                    }
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
        }
    }
    
    private func settingItem(icon: String, title: String, hasArrow: Bool = false) -> some View {
        Card(shadow: false) {
            HStack(spacing: Spacing.lg) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.brandSecondary700)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.brandSecondary900)
                
                Spacer()
                
                if hasArrow {
                    Image(systemName: "chevron.right")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary300)
                }
            }
        }
    }
}

#Preview {
    MainTabView()
}