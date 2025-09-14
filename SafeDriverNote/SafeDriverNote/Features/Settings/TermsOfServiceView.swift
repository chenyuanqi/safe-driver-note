import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("安全驾驶助手服务条款")
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
                        title: "1. 服务条款接受",
                        content: """
                        欢迎使用安全驾驶助手（以下简称"本应用"）。本服务条款构成您与我们之间具有法律约束力的协议。

                        通过下载、安装或使用本应用，您表示已阅读、理解并同意受本服务条款的约束。如果您不同意本条款，请不要使用本应用。

                        我们保留随时修改本服务条款的权利，修改后的条款将在应用内公布。继续使用本应用即表示您接受修改后的条款。
                        """
                    )

                    // 服务说明
                    sectionView(
                        title: "2. 服务说明",
                        content: """
                        2.1 应用功能
                        本应用为用户提供以下功能：
                        • 驾驶记录和路线跟踪
                        • 驾驶日志管理和经验分享
                        • 安全检查清单和评分系统
                        • 安全驾驶知识学习

                        2.2 服务性质
                        • 本应用是一款个人驾驶辅助工具
                        • 所提供的建议仅供参考，不能替代专业驾驶培训
                        • 用户需要根据实际情况和当地法律法规进行驾驶

                        2.3 免费服务
                        • 本应用目前为免费提供
                        • 我们保留在未来引入付费功能的权利
                        • 任何付费功能将会明确标识并征得用户同意
                        """
                    )

                    // 用户责任
                    sectionView(
                        title: "3. 用户责任与义务",
                        content: """
                        3.1 合法使用
                        • 您必须遵守当地的交通法律法规
                        • 不得将应用用于任何非法目的
                        • 驾驶时应专注于道路安全，避免分心操作

                        3.2 账户安全
                        • 您有责任保护设备和数据的安全
                        • 不得与他人共享个人驾驶数据
                        • 发现安全问题应及时联系我们

                        3.3 内容责任
                        • 您对输入应用的所有内容负责
                        • 不得输入虚假、误导或有害信息
                        • 尊重他人隐私，不分享他人信息

                        3.4 禁止行为
                        您不得进行以下行为：
                        • 逆向工程、反编译或破解应用
                        • 干扰应用的正常运行
                        • 恶意传播病毒或有害代码
                        • 侵犯他人的知识产权
                        """
                    )

                    // 知识产权
                    sectionView(
                        title: "4. 知识产权",
                        content: """
                        4.1 应用权利
                        • 本应用及其所有内容的知识产权归我们所有
                        • 包括但不限于软件代码、界面设计、文本内容、图标等
                        • 未经许可，您不得复制、修改、分发或商业使用

                        4.2 用户内容
                        • 您对自己创建的内容保留所有权
                        • 但授予我们为提供服务所需的使用权
                        • 我们不会将您的个人内容用于商业目的

                        4.3 第三方内容
                        • 应用可能包含第三方的内容或链接
                        • 这些内容归各自所有者所有
                        • 我们不对第三方内容承担责任
                        """
                    )

                    // 隐私保护
                    sectionView(
                        title: "5. 隐私保护",
                        content: """
                        我们非常重视您的隐私权益：

                        • 所有个人数据均存储在本地设备
                        • 不会未经授权收集或分享您的信息
                        • 详细信息请参阅《隐私政策》

                        您有权：
                        • 查看和修改您的数据
                        • 导出您的数据
                        • 删除您的数据
                        """
                    )

                    // 免责声明
                    sectionView(
                        title: "6. 免责声明",
                        content: """
                        6.1 服务提供
                        • 我们努力确保服务的准确性和可靠性
                        • 但不保证服务永不中断或完全无错误
                        • 服务按"现状"提供，不提供明示或暗示的担保

                        6.2 使用风险
                        • 用户使用本应用的风险由其自行承担
                        • 我们不对因使用应用导致的任何损失承担责任
                        • 包括但不限于数据丢失、设备损坏、事故等

                        6.3 内容准确性
                        • 应用中的安全知识仅供参考
                        • 不能替代正规的驾驶培训或专业建议
                        • 用户应结合实际情况和当地法规进行判断

                        6.4 第三方服务
                        • 我们不对集成的第三方服务承担责任
                        • 第三方服务的使用受其自身条款约束
                        """
                    )

                    // 服务变更
                    sectionView(
                        title: "7. 服务变更与终止",
                        content: """
                        7.1 服务更新
                        • 我们可能随时更新、修改或改进服务
                        • 重大变更将通过适当方式通知用户
                        • 继续使用服务表示接受变更

                        7.2 服务终止
                        我们保留在以下情况下终止服务的权利：
                        • 用户违反本服务条款
                        • 出现技术或法律问题
                        • 商业决策需要

                        7.3 数据处理
                        • 服务终止前我们会尽力通知用户
                        • 用户应及时备份重要数据
                        • 终止后我们可能删除相关数据
                        """
                    )

                    // 争议解决
                    sectionView(
                        title: "8. 争议解决",
                        content: """
                        8.1 友好协商
                        • 任何争议优先通过友好协商解决
                        • 您可以通过邮件联系我们：chenyuanqi@outlook.com

                        8.2 适用法律
                        • 本协议受中华人民共和国法律管辖
                        • 不含法律冲突原则

                        8.3 管辖法院
                        • 如协商无果，争议应提交至我们所在地法院管辖
                        """
                    )

                    // 其他条款
                    sectionView(
                        title: "9. 其他条款",
                        content: """
                        9.1 完整协议
                        • 本服务条款构成您与我们之间的完整协议
                        • 取代之前的所有协议和约定

                        9.2 条款分割
                        • 如果本协议的任何条款被认定为无效
                        • 其余条款仍然有效

                        9.3 语言版本
                        • 本协议以中文为准
                        • 如有其他语言版本，以中文版本为准
                        """
                    )

                    // 联系信息
                    sectionView(
                        title: "10. 联系我们",
                        content: """
                        如果您对本服务条款有任何疑问，请联系我们：

                        邮箱：chenyuanqi@outlook.com
                        主题：安全驾驶助手 - 服务条款咨询

                        我们将尽快为您解答。
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
            .navigationTitle("服务条款")
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
    TermsOfServiceView()
}