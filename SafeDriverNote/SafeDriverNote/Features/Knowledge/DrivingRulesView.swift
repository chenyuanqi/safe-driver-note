import SwiftUI

struct DrivingRulesView: View {
    let onDismiss: () -> Void
    
    private let rules = [
        "慢出稳，练出精，思出透！敬畏生命，小心驾驶！",
        "保持车距，专注前方，快速扫描周围环境",
        "三逢（盲区+道路+自身）四要（减速+备刹+眼神+精神），逢变化必注意减速",
        "不加速，脚一定放在刹车上",
        "眼不到手不动！",
        "让速不让道！",
        "变道（打灯3s以上+看后视镜&内后视镜&b柱盲区确认安全+快速完成）",
        "会车防车尾（其他交通参与者），超车防车头（预判前车的移动方向）",
        "错过的路口就让它错过，不要紧急打方向盘变道",
        "急刹，前方有状况，开启双闪提醒后方",
        "远离大车（尤其是左右两侧和前方盲区）",
        "假设别人会犯错，提前给自己预留处理空间",
        "下车，帮忙提醒查看前后是否有交通参与者",
        "打转向灯、鸣笛，是为了告知其他交通参与者",
        "特殊环境提前做好准备，比如雨天提前清理油膜",
        "打哈欠、眼皮沉重、走神，必须靠边休息恢复"
    ]
    
    var body: some View {
        ZStack {
            // 背景
            Color.brandSecondary50
                .ignoresSafeArea()
            
            VStack(spacing: Spacing.xl) {
                // 增加顶部间距，避免被导航栏遮挡
                Spacer(minLength: Spacing.navBarHeight + Spacing.lg)
                
                // 主卡片
                ScrollView {
                    VStack(alignment: .leading, spacing: Spacing.xxl) {
                        // 标题
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text("开车守则")
                                .font(.title1)
                                .fontWeight(.bold)
                                .foregroundColor(.brandSecondary900)
                            
                            // 装饰性分隔线
                            Rectangle()
                                .fill(Color.brandPrimary500)
                                .frame(height: 3)
                                .frame(maxWidth: 80)
                        }
                        
                        // 守则内容
                        VStack(alignment: .leading, spacing: Spacing.lg) {
                            ForEach(rules.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: Spacing.md) {
                                    Text("\(index + 1).")
                                        .font(.bodyLarge)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.brandPrimary600)
                                        .frame(minWidth: 20, alignment: .leading)
                                    
                                    Text(rules[index])
                                        .font(.bodyLarge)
                                        .foregroundColor(.brandSecondary900)
                                        .lineSpacing(6)
                                    Spacer()
                                }
                            }
                        }
                        .padding(Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                                .stroke(Color.brandSecondary200, lineWidth: 1)
                        )
                    }
                    .padding(Spacing.xxxl)
                }
                .frame(maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                        .stroke(Color.brandSecondary200, lineWidth: 1)
                )
                
                // 按钮
                Button(action: onDismiss) {
                    Text("开始学习")
                        .font(.bodyMedium)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.lg)
                        .background(Color.brandPrimary500)
                        .cornerRadius(CornerRadius.lg)
                }
                .padding(.bottom, Spacing.xl)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Spacing.pagePadding)
        }
    }
}

#Preview {
    DrivingRulesView(onDismiss: {})
}
