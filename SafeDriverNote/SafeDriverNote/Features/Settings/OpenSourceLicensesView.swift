import SwiftUI

struct OpenSourceLicensesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    Text("开源许可证")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.brandSecondary900)
                        .padding(.bottom, Spacing.md)

                    Text("感谢以下开源项目为本应用提供支持")
                        .font(.body)
                        .foregroundColor(.brandSecondary600)
                        .padding(.bottom, Spacing.lg)

                    // SwiftUI
                    licenseView(
                        name: "SwiftUI",
                        description: "Apple's declarative UI framework",
                        license: "Apple Software License",
                        copyright: "© 2019-2025 Apple Inc.",
                        licenseText: """
                        SwiftUI is provided by Apple Inc. under the terms of the Xcode and Apple SDKs Agreement.

                        This software is provided 'as is' without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, and non-infringement.
                        """
                    )

                    Divider()

                    // Swift
                    licenseView(
                        name: "Swift Programming Language",
                        description: "Apple's powerful and intuitive programming language",
                        license: "Apache License 2.0",
                        copyright: "© 2014-2025 Apple Inc.",
                        licenseText: """
                        Licensed under the Apache License, Version 2.0 (the "License");
                        you may not use this file except in compliance with the License.
                        You may obtain a copy of the License at

                        http://www.apache.org/licenses/LICENSE-2.0

                        Unless required by applicable law or agreed to in writing, software
                        distributed under the License is distributed on an "AS IS" BASIS,
                        WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
                        See the License for the specific language governing permissions and
                        limitations under the License.
                        """
                    )

                    Divider()

                    // Foundation
                    licenseView(
                        name: "Foundation Framework",
                        description: "Base layer of functionality for apps and frameworks",
                        license: "Apple Software License",
                        copyright: "© 1994-2025 Apple Inc.",
                        licenseText: """
                        Foundation framework is provided by Apple Inc. under the terms of the Xcode and Apple SDKs Agreement.

                        This framework provides fundamental software services including basic data types, collections, and operating system services.
                        """
                    )

                    Divider()

                    // CoreLocation
                    licenseView(
                        name: "Core Location",
                        description: "Framework for location and heading information",
                        license: "Apple Software License",
                        copyright: "© 2008-2025 Apple Inc.",
                        licenseText: """
                        Core Location framework is provided by Apple Inc. under the terms of the Xcode and Apple SDKs Agreement.

                        This framework provides location services for determining a device's geographic location, altitude, and orientation.
                        """
                    )

                    Divider()

                    // SwiftData
                    licenseView(
                        name: "SwiftData",
                        description: "Framework for data modeling and persistence",
                        license: "Apple Software License",
                        copyright: "© 2023-2025 Apple Inc.",
                        licenseText: """
                        SwiftData framework is provided by Apple Inc. under the terms of the Xcode and Apple SDKs Agreement.

                        SwiftData makes it easy to persist data using declarative code. You can query and filter data using regular Swift code.
                        """
                    )

                    Divider()

                    // Combine
                    licenseView(
                        name: "Combine Framework",
                        description: "Reactive programming framework",
                        license: "Apple Software License",
                        copyright: "© 2019-2025 Apple Inc.",
                        licenseText: """
                        Combine framework is provided by Apple Inc. under the terms of the Xcode and Apple SDKs Agreement.

                        The Combine framework provides a declarative Swift API for processing values over time.
                        """
                    )

                    // 自定义组件说明
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("自定义组件")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text("本应用的用户界面组件、业务逻辑和设计系统均为原创开发，不依赖第三方UI库。")
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                            .lineSpacing(4)

                        Text("主要特点：")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)
                            .padding(.top, Spacing.sm)

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("• 自定义设计系统和组件库")
                            Text("• 原生SwiftUI实现，无第三方依赖")
                            Text("• 针对驾驶场景优化的用户体验")
                            Text("• 完全离线工作，保护用户隐私")
                        }
                        .font(.body)
                        .foregroundColor(.brandSecondary600)
                    }
                    .padding(Spacing.lg)
                    .background(Color.brandSecondary100)
                    .cornerRadius(CornerRadius.md)

                    // 致谢
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("特别致谢")
                            .font(.bodyLarge)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandSecondary900)

                        Text("""
                        感谢苹果公司提供优秀的开发工具和框架，让我们能够专注于为用户创造价值。

                        感谢开源社区的贡献者们，是您们的无私奉献推动了技术的进步。

                        如果您发现我们遗漏了任何应该包含的许可证信息，请联系我们：chenyuanqi@outlook.com
                        """)
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                            .lineSpacing(4)
                    }
                    .padding(Spacing.lg)
                    .background(Color.brandPrimary50)
                    .cornerRadius(CornerRadius.md)

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
            .navigationTitle("开源许可")
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

    private func licenseView(name: String, description: String, license: String, copyright: String, licenseText: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // 头部信息
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(name)
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Text(description)
                    .font(.bodyMedium)
                    .foregroundColor(.brandSecondary600)

                HStack {
                    Text("许可证：")
                        .font(.bodySmall)
                        .foregroundColor(.brandSecondary500)

                    Text(license)
                        .font(.bodySmall)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPrimary500)
                }

                Text(copyright)
                    .font(.caption)
                    .foregroundColor(.brandSecondary400)
            }

            // 许可证文本
            Text(licenseText)
                .font(.caption)
                .foregroundColor(.brandSecondary600)
                .lineSpacing(2)
                .padding(Spacing.md)
                .background(Color.brandSecondary100)
                .cornerRadius(CornerRadius.sm)
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.md)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    OpenSourceLicensesView()
}