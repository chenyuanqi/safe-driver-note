import SwiftUI
import Foundation
import MessageUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingMailComposer = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingOpenSourceLicenses = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 应用图标和信息
                    appInfoSection

                    // 版本信息
                    versionSection

                    // 功能介绍
                    featuresSection

                    // 开发团队
                    teamSection

                    // 法律信息
                    legalSection
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingOpenSourceLicenses) {
            OpenSourceLicensesView()
        }
    }

    // MARK: - 应用信息
    private var appInfoSection: some View {
        VStack(spacing: Spacing.lg) {
            // 应用图标
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.brandPrimary500)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "car.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            VStack(spacing: Spacing.xs) {
                Text("安全驾驶助手")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandSecondary900)

                Text("Safe Driver Note")
                    .font(.bodyMedium)
                    .foregroundColor(.brandSecondary600)

                Text("让每一次出行都更安全")
                    .font(.body)
                    .foregroundColor(.brandSecondary500)
                    .multilineTextAlignment(.center)
                    .padding(.top, Spacing.xs)
            }
        }
    }

    // MARK: - 版本信息
    private var versionSection: some View {
        Card(shadow: true) {
            VStack(spacing: Spacing.md) {
                infoRow(
                    title: "版本号",
                    value: "1.0.0"
                )

                Divider()

                infoRow(
                    title: "构建号",
                    value: "2025.001"
                )

                Divider()

                infoRow(
                    title: "发布日期",
                    value: "2025年1月"
                )

                Divider()

                HStack {
                    Text("检查更新")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    Spacer()

                    Button("检查") {
                        // TODO: 检查更新逻辑
                    }
                    .font(.bodySmall)
                    .foregroundColor(.brandPrimary500)
                }
            }
            .padding(Spacing.lg)
        }
    }

    // MARK: - 功能介绍
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("核心功能")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    featureItem(
                        icon: "car",
                        title: "智能驾驶记录",
                        description: "自动记录驾驶路线和时间，生成详细的出行报告"
                    )

                    Divider()

                    featureItem(
                        icon: "list.bullet",
                        title: "驾驶日志管理",
                        description: "记录驾驶心得和经验，分类管理成功与失误"
                    )

                    Divider()

                    featureItem(
                        icon: "checklist",
                        title: "安全检查清单",
                        description: "行前行后检查提醒，培养良好的安全习惯"
                    )

                    Divider()

                    featureItem(
                        icon: "book",
                        title: "安全知识学习",
                        description: "每日推送安全驾驶知识，提升驾驶技能"
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 开发团队
    private var teamSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("开发团队")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: Spacing.md) {
                    Text("感谢每一位为道路安全贡献力量的开发者")
                        .font(.body)
                        .foregroundColor(.brandSecondary700)
                        .multilineTextAlignment(.center)

                    VStack(spacing: Spacing.xs) {
                        Text("产品设计 & 开发")
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text("Safe Driver Team")
                            .font(.body)
                            .foregroundColor(.brandSecondary600)
                    }

                    Button(action: {
                        sendEmail()
                    }) {
                        Text("联系我们")
                            .font(.bodyMedium)
                            .foregroundColor(.brandPrimary500)
                    }
                    .padding(.top, Spacing.sm)
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 法律信息
    private var legalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("法律信息")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
                .padding(.leading, Spacing.sm)

            Card(shadow: true) {
                VStack(spacing: Spacing.md) {
                    legalItem(
                        title: "隐私政策",
                        description: "了解我们如何保护您的个人信息"
                    )

                    Divider()

                    legalItem(
                        title: "服务条款",
                        description: "使用本应用的相关条款和条件"
                    )

                    Divider()

                    legalItem(
                        title: "开源许可",
                        description: "查看使用的第三方开源组件"
                    )
                }
                .padding(Spacing.lg)
            }

            // 版权信息
            Text("© 2025 Safe Driver Team. All rights reserved.")
                .font(.caption)
                .foregroundColor(.brandSecondary400)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, Spacing.lg)
        }
    }

    // MARK: - 辅助方法
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary900)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(.brandSecondary600)
        }
    }

    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.brandPrimary500)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Text(description)
                    .font(.body)
                    .foregroundColor(.brandSecondary700)
                    .lineLimit(nil)
            }

            Spacer()
        }
    }

    private func legalItem(title: String, description: String) -> some View {
        Button(action: {
            switch title {
            case "隐私政策":
                showingPrivacyPolicy = true
            case "服务条款":
                showingTermsOfService = true
            case "开源许可":
                showingOpenSourceLicenses = true
            default:
                break
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(title)
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary900)

                    Text(description)
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary300)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Actions

    private func sendEmail() {
        let email = "chenyuanqi@outlook.com"
        let subject = "安全驾驶助手 - 用户反馈"
        let body = """
        您好，

        我在使用安全驾驶助手过程中有以下反馈：

        [请在此处描述您的问题或建议]

        设备信息：
        - 应用版本：1.0.0 (2025.001)
        - 系统版本：iOS \(UIDevice.current.systemVersion)
        - 设备型号：\(UIDevice.current.model)

        谢谢！
        """

        if let emailURL = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            if UIApplication.shared.canOpenURL(emailURL) {
                UIApplication.shared.open(emailURL)
            } else {
                // 如果无法打开邮件应用，可以显示一个提示
                if let _ = UIPasteboard.general.url {
                    UIPasteboard.general.string = email
                }
            }
        }
    }
}

#Preview {
    AboutView()
}