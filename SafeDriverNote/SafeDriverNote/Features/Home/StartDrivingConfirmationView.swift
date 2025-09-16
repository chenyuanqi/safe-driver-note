import SwiftUI

struct StartDrivingConfirmationView: View {
    let onCancel: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 标题
            Text("开始驾驶")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            // 内容 - 左对齐
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("将记录您的驾驶路线和时间，帮助您更好地管理驾驶行为。")
                    .font(.body)
                    .foregroundColor(.brandSecondary700)
                    .multilineTextAlignment(.leading)

                Text("道路千万条，安全第一条！")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.brandDanger500)
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // 按钮组
            HStack(spacing: Spacing.md) {
                Button(action: onCancel) {
                    Text("取消")
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.brandSecondary700)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandSecondary100)
                        .cornerRadius(12)
                }

                Button(action: onConfirm) {
                    Text("开始")
                        .font(.bodyLarge)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(Color.brandPrimary500)
                        .cornerRadius(12)
                }
            }
        }
        .padding(Spacing.pagePadding)
        .background(Color.white)
    }
}

#Preview {
    StartDrivingConfirmationView(
        onCancel: { print("Cancelled") },
        onConfirm: { print("Confirmed") }
    )
    .previewLayout(.sizeThatFits)
}