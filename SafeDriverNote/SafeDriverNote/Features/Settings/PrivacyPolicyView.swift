import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("安全驾驶助手隐私政策")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.brandSecondary900)
                        .padding(.bottom, Spacing.md)

                    Text("生效日期：2025年1月1日")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                        .padding(.bottom, Spacing.lg)

                    // 引言
                    sectionView(
                        title: "1. 引言",
                        content: """
                        感谢您使用安全驾驶助手（以下简称"本应用"）。我们非常重视您的隐私权益，本隐私政策将向您说明我们如何收集、使用、存储和保护您的个人信息。

                        使用本应用即表示您同意本隐私政策的条款。如果您不同意本政策，请停止使用本应用。
                        """
                    )

                    // 信息收集
                    sectionView(
                        title: "2. 信息收集",
                        content: """
                        为了为您提供更好的服务，我们可能收集以下类型的信息：

                        2.1 位置信息
                        • 在您明确授权后，我们会收集您的位置信息用于记录驾驶路线
                        • 位置数据仅在本地设备存储，不会上传到服务器
                        • 您可以随时在设置中关闭位置权限

                        2.2 驾驶数据
                        • 您手动输入的驾驶日志和经验记录
                        • 检查清单的完成记录和评分
                        • 知识学习的进度和偏好设置

                        2.3 设备信息
                        • 设备型号、操作系统版本等技术信息
                        • 应用使用统计数据（匿名）
                        """
                    )

                    // 信息使用
                    sectionView(
                        title: "3. 信息使用",
                        content: """
                        我们收集的信息仅用于以下目的：

                        3.1 核心功能
                        • 提供驾驶记录和路线追踪功能
                        • 生成个人驾驶统计和分析报告
                        • 提供安全检查清单和知识推荐

                        3.2 改进服务
                        • 优化应用性能和用户体验
                        • 开发新功能和改进现有功能
                        • 分析使用模式以提供更好的建议

                        我们承诺不会将您的个人信息用于商业营销或出售给第三方。
                        """
                    )

                    // 数据存储
                    sectionView(
                        title: "4. 数据存储与安全",
                        content: """
                        4.1 本地存储
                        • 所有个人数据均存储在您的设备本地
                        • 我们不会将您的驾驶数据上传到远程服务器
                        • 数据的安全性依赖于您设备的安全措施

                        4.2 安全措施
                        • 使用业界标准的加密技术保护数据
                        • 定期更新安全协议和保护措施
                        • 限制对个人数据的访问权限

                        4.3 数据备份
                        • 您可以选择使用iCloud同步功能备份数据
                        • 备份数据受到Apple隐私政策保护
                        """
                    )

                    // 权限管理
                    sectionView(
                        title: "5. 权限管理",
                        content: """
                        本应用可能请求以下权限：

                        5.1 位置权限
                        • 用途：记录驾驶路线和位置信息
                        • 可选性：您可以选择拒绝或随时撤回

                        5.2 通知权限
                        • 用途：发送安全提醒和学习推送
                        • 可选性：您可以在设置中关闭通知

                        5.3 照片权限
                        • 用途：保存和查看驾驶相关照片
                        • 可选性：仅在您使用相关功能时请求
                        """
                    )

                    // 第三方服务
                    sectionView(
                        title: "6. 第三方服务",
                        content: """
                        本应用可能集成以下第三方服务：

                        • 地图服务：用于显示位置和路线信息
                        • 分析服务：用于改进应用性能（数据已匿名化）

                        这些服务有自己的隐私政策，我们建议您仔细阅读。
                        """
                    )

                    // 儿童隐私
                    sectionView(
                        title: "7. 儿童隐私保护",
                        content: """
                        本应用主要面向成年驾驶员，不会故意收集13岁以下儿童的个人信息。

                        如果我们发现无意中收集了儿童的个人信息，我们将尽快删除这些信息。
                        """
                    )

                    // 政策更新
                    sectionView(
                        title: "8. 隐私政策更新",
                        content: """
                        我们可能会不时更新本隐私政策。重大变更将通过应用内通知或其他适当方式告知您。

                        建议您定期查看本政策以了解最新信息。
                        """
                    )

                    // 联系我们
                    sectionView(
                        title: "9. 联系我们",
                        content: """
                        如果您对本隐私政策有任何疑问或建议，请通过以下方式联系我们：

                        邮箱：chenyuanqi@outlook.com
                        主题：安全驾驶助手 - 隐私政策咨询

                        我们将在收到您的信息后尽快回复。
                        """
                    )

                    // 版权信息
                    Text("© 2025 Safe Driver Team. All rights reserved.")
                        .font(.caption)
                        .foregroundColor(.brandSecondary400)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, Spacing.xl)
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("隐私政策")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sectionView(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.bodyLarge)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Text(content)
                .font(.body)
                .foregroundColor(.brandSecondary700)
                .lineSpacing(4)
        }
        .padding(.bottom, Spacing.md)
    }
}

#Preview {
    PrivacyPolicyView()
}