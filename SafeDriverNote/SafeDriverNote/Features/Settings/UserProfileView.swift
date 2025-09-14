import SwiftUI
import Foundation

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var userName = "安全驾驶人"
    @State private var userAge = ""
    @State private var drivingYears = "3"
    @State private var vehicleType = "小型汽车"
    @State private var showingImagePicker = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // 头像区域
                    profileImageSection

                    // 基本信息
                    basicInfoSection

                    // 驾驶信息
                    drivingInfoSection

                    // 成就统计
                    achievementSection
                }
                .padding(Spacing.pagePadding)
            }
            .background(Color.brandSecondary50)
            .navigationTitle("个人资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        // TODO: 保存用户信息
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - 头像区域
    private var profileImageSection: some View {
        VStack(spacing: Spacing.md) {
            Button(action: {
                showingImagePicker = true
            }) {
                Circle()
                    .fill(Color.brandPrimary100)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.brandPrimary500)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.cardBackground, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            Text("点击更换头像")
                .font(.bodySmall)
                .foregroundColor(.brandSecondary500)
        }
    }

    // MARK: - 基本信息
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("基本信息")

            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    inputField(
                        title: "姓名",
                        value: $userName,
                        placeholder: "请输入您的姓名"
                    )

                    Divider()

                    inputField(
                        title: "年龄",
                        value: $userAge,
                        placeholder: "请输入您的年龄",
                        keyboardType: .numberPad
                    )
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 驾驶信息
    private var drivingInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("驾驶信息")

            Card(shadow: true) {
                VStack(spacing: Spacing.lg) {
                    inputField(
                        title: "驾龄",
                        value: $drivingYears,
                        placeholder: "请输入您的驾龄（年）",
                        keyboardType: .numberPad
                    )

                    Divider()

                    HStack {
                        Text("车辆类型")
                            .font(.bodyMedium)
                            .fontWeight(.medium)
                            .foregroundColor(.brandSecondary900)

                        Spacer()

                        Picker("车辆类型", selection: $vehicleType) {
                            Text("小型汽车").tag("小型汽车")
                            Text("SUV").tag("SUV")
                            Text("货车").tag("货车")
                            Text("摩托车").tag("摩托车")
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 成就统计
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionTitle("成就统计")

            Card(shadow: true) {
                VStack(spacing: Spacing.md) {
                    HStack {
                        achievementItem(
                            title: "安全评分",
                            value: "92",
                            unit: "分",
                            color: .brandPrimary500
                        )

                        achievementItem(
                            title: "连续天数",
                            value: "15",
                            unit: "天",
                            color: .brandInfo500
                        )

                        achievementItem(
                            title: "总里程",
                            value: "1,240",
                            unit: "km",
                            color: .brandWarning500
                        )
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("最近成就")
                                .font(.bodyMedium)
                                .fontWeight(.medium)
                                .foregroundColor(.brandSecondary900)

                            Text("🎉 连续打卡15天")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary600)
                        }

                        Spacer()

                        Text("3天前")
                            .font(.caption)
                            .foregroundColor(.brandSecondary400)
                    }
                }
                .padding(Spacing.lg)
            }
        }
    }

    // MARK: - 辅助方法
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.semibold)
            .foregroundColor(.brandSecondary900)
            .padding(.leading, Spacing.sm)
    }

    private func inputField(
        title: String,
        value: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        HStack {
            Text(title)
                .font(.bodyMedium)
                .fontWeight(.medium)
                .foregroundColor(.brandSecondary900)
                .frame(width: 60, alignment: .leading)

            TextField(placeholder, text: value)
                .keyboardType(keyboardType)
                .textFieldStyle(PlainTextFieldStyle())
        }
    }

    private func achievementItem(
        title: String,
        value: String,
        unit: String,
        color: Color
    ) -> some View {
        VStack(spacing: Spacing.xs) {
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(unit)
                    .font(.caption)
                    .foregroundColor(.brandSecondary500)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.brandSecondary500)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    UserProfileView()
}