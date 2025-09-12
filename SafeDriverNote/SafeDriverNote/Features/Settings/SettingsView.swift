import SwiftUI
import Foundation

struct SettingsView: View {
    var body: some View {
        VStack(spacing: Spacing.xl) {
            // 标题（移除）
            
            // 通知设置
            NavigationLink(destination: NotificationSettingsView()) {
                HStack {
                    Image(systemName: "bell")
                        .font(.bodyLarge)
                        .foregroundColor(.brandPrimary500)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("通知设置")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)
                        
                        Text("管理每日安全驾驶提醒")
                            .font(.bodySmall)
                            .foregroundColor(.brandSecondary500)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary300)
                }
                .padding(Spacing.md)
                .background(Color.white)
                .cornerRadius(CornerRadius.md)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 其他设置项可以在这里添加
            
            Spacer()
        }
        .padding(Spacing.pagePadding)
        .background(Color.brandSecondary50)
        .navigationTitle("") // 移除导航标题
        .navigationBarTitleDisplayMode(.inline) // 隐藏标题显示
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}