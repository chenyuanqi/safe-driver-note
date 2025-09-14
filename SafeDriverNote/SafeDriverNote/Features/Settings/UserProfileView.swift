import SwiftUI
import Foundation

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var di: AppDI

    @State private var userName = "安全驾驶人"
    @State private var userAge = ""
    @State private var drivingYears = "3"
    @State private var vehicleType = "小型汽车"
    @State private var showingImagePicker = false
    @State private var userStats: UserStats?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    if isLoading {
                        // 加载状态
                        VStack(spacing: Spacing.lg) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("加载中...")
                                .font(.bodyMedium)
                                .foregroundColor(.brandSecondary500)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.xxxl)
                    } else {
                        // 头像区域
                        profileImageSection

                        // 基本信息
                        basicInfoSection

                        // 驾驶信息
                        drivingInfoSection

                        // 成就统计
                        achievementSection
                    }
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
                    .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveUserProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(isSaving)
                }
            }
            .onAppear {
                loadUserProfile()
            }
            .alert("保存失败", isPresented: $showingError) {
                Button("确定") { }
            } message: {
                Text(errorMessage)
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
                    if let stats = userStats {
                        HStack {
                            achievementItem(
                                title: "安全评分",
                                value: "\(stats.safetyScore)",
                                unit: "分",
                                color: .brandPrimary500
                            )

                            achievementItem(
                                title: "连续天数",
                                value: "\(stats.currentStreakDays)",
                                unit: "天",
                                color: .brandInfo500
                            )

                            achievementItem(
                                title: "总里程",
                                value: formatDistance(stats.totalRouteDistance),
                                unit: stats.totalRouteDistance >= 1000 ? "km" : "m",
                                color: .brandWarning500
                            )
                        }

                        Divider()

                        if let achievement = stats.recentAchievement {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("最近成就")
                                        .font(.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(.brandSecondary900)

                                    Text(achievement.description)
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary600)
                                }

                                Spacer()

                                Text(formatRelativeDate(achievement.achievedDate))
                                    .font(.caption)
                                    .foregroundColor(.brandSecondary400)
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading, spacing: Spacing.xs) {
                                    Text("最近成就")
                                        .font(.bodyMedium)
                                        .fontWeight(.medium)
                                        .foregroundColor(.brandSecondary900)

                                    Text("继续努力，即将获得新成就！")
                                        .font(.bodySmall)
                                        .foregroundColor(.brandSecondary500)
                                }

                                Spacer()
                            }
                        }
                    } else {
                        // 加载状态
                        VStack(spacing: Spacing.md) {
                            ProgressView()
                            Text("加载统计数据...")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
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

    // MARK: - Data Loading & Saving

    private func loadUserProfile() {
        Task {
            do {
                let profile = try di.userProfileRepository.fetchUserProfile()
                let stats = try di.userProfileRepository.calculateUserStats()

                await MainActor.run {
                    self.userName = profile.userName
                    self.userAge = profile.userAge != nil ? "\(profile.userAge!)" : ""
                    self.drivingYears = "\(profile.drivingYears)"
                    self.vehicleType = profile.vehicleType
                    self.userStats = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载用户资料失败：\(error.localizedDescription)"
                    self.showingError = true
                    self.isLoading = false
                }
            }
        }
    }

    private func saveUserProfile() {
        guard !isSaving else { return }

        isSaving = true

        Task {
            do {
                let ageValue = userAge.isEmpty ? nil : Int(userAge)
                let drivingYearsValue = Int(drivingYears) ?? 0

                let updatedProfile = try di.userProfileRepository.updateUserProfile(
                    userName: userName,
                    userAge: ageValue,
                    drivingYears: drivingYearsValue,
                    vehicleType: vehicleType,
                    avatarImagePath: nil
                )

                await MainActor.run {
                    self.isSaving = false
                    self.dismiss()
                }
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.errorMessage = "保存用户资料失败：\(error.localizedDescription)"
                    self.showingError = true
                }
            }
        }
    }

    // MARK: - Formatting Helpers

    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f", distance / 1000)
        } else {
            return String(format: "%.0f", distance)
        }
    }

    private func formatRelativeDate(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.day], from: date, to: now)

        if let days = components.day {
            if days == 0 {
                return "今天"
            } else if days == 1 {
                return "昨天"
            } else if days < 7 {
                return "\(days)天前"
            } else {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "zh_CN")
                formatter.dateFormat = "M月d日"
                return formatter.string(from: date)
            }
        }
        return ""
    }
}

#Preview {
    UserProfileView()
        .environmentObject(AppDI.shared)
}