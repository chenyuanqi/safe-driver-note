import SwiftUI

struct SafetyReminderView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // 标题
            Text("安全驾驶提醒")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            // 内容 - 左对齐
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("您好像有一段时间没有查看安全驾驶知识了。")
                    .font(.body)
                    .foregroundColor(.brandSecondary700)
                    .multilineTextAlignment(.leading)

                Text("道路千万条，安全第一条！")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.brandDanger500)
                    .multilineTextAlignment(.leading)

                Text("记得每天学习新的驾驶技巧哦~")
                    .font(.body)
                    .foregroundColor(.brandSecondary700)
                    .multilineTextAlignment(.leading)
            }
            .fixedSize(horizontal: false, vertical: true)

            Spacer()

            // 按钮
            Button(action: onDismiss) {
                Text("知道了")
                    .font(.bodyLarge)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(Color.brandPrimary500)
                    .cornerRadius(12)
            }
        }
        .padding(Spacing.pagePadding)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(Color.cardBackground)
        )
        .shadow(
            color: Shadow.xl.color,
            radius: Shadow.xl.radius,
            x: Shadow.xl.x,
            y: Shadow.xl.y
        )
    }
}

#Preview {
    SafetyReminderView {
        print("Dismissed")
    }
    .previewLayout(.sizeThatFits)
}
