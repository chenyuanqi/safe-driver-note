import SwiftUI
import Foundation

struct TodayLearningModalView: View {
    @StateObject private var todayLearningService = TodayLearningService.shared
    @State private var currentCardIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    @State private var cardRotation: Double = 0
    @State private var showingFirework = false
    @State private var fireworkText = ""
    @State private var fireworkColor = Color.brandPrimary500
    @State private var cardOpacity: Double = 1.0
    @State private var isDismissing = false

    // 绑定到父视图的弹框状态
    @Binding var isPresented: Bool

    // 可选的初始卡片标题，用于定位到特定卡片
    let initialCardTitle: String?

    init(isPresented: Binding<Bool>, initialCardTitle: String? = nil) {
        self._isPresented = isPresented
        self.initialCardTitle = initialCardTitle
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 减少顶部空间，只留出导航栏的最小空间
                Spacer(minLength: 60)

                // 头部信息
                headerSection

                // 卡片内容区域
                if !todayLearningService.todayCards.isEmpty {
                    if currentCardIndex < todayLearningService.todayCards.count {
                        let card = todayLearningService.todayCards[currentCardIndex]

                        VStack(spacing: Spacing.md) {
                            // 卡片视图
                            ZStack {
                                cardFullView(card)
                                    .offset(x: dragOffset)
                                    .rotationEffect(.degrees(cardRotation))
                                    .opacity(cardOpacity)
                                    .scaleEffect(isDismissing ? 0.8 : 1.0)
                                    .gesture(
                                        DragGesture(minimumDistance: 20)
                                            .onChanged { value in
                                                withAnimation(.interactiveSpring()) {
                                                    dragOffset = value.translation.width
                                                    cardRotation = Double(dragOffset / 15)
                                                }
                                            }
                                            .onEnded { value in
                                                let dx = value.translation.width
                                                if dx > 120 { // 右滑：掌握
                                                    dismissCard(direction: .right, action: {
                                                        todayLearningService.markCardAsLearned(card)
                                                        moveToNextCard()
                                                    })
                                                } else if dx < -120 { // 左滑：稍后
                                                    dismissCard(direction: .left, action: {
                                                        todayLearningService.markCardAsLaterViewed(card)
                                                        moveToNextCard()
                                                    })
                                                } else {
                                                    // 回弹
                                                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                                        dragOffset = 0
                                                        cardRotation = 0
                                                    }
                                                }
                                            }
                                    )

                                // 烟花文字效果
                                if showingFirework {
                                    TodayFireworkTextView(text: fireworkText, color: fireworkColor)
                                }
                            }
                            .frame(maxHeight: .infinity)
                            .padding(.horizontal, Spacing.lg)

                            // 提示文字
                            Text("左滑稍后，右滑掌握")
                                .font(.bodySmall)
                                .foregroundColor(.brandSecondary500)
                                .padding(.top, Spacing.md)
                        }
                    } else {
                        // 全部完成状态
                        completedState
                    }
                } else {
                    // 空状态
                    emptyState
                }
            }
            .background(Color.brandSecondary50)
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                // 自定义导航栏
                HStack {
                    Button("完成") {
                        isPresented = false
                    }
                    .font(.body)
                    .foregroundColor(.brandPrimary500)

                    Spacer()

                    Text("今日学习")
                        .font(.bodyLarge)
                        .fontWeight(.semibold)
                        .foregroundColor(.brandSecondary900)

                    Spacer()

                    // 移除刷新按钮，今日学习内容固定
                    Spacer()
                        .frame(width: 24) // 保持布局平衡
                }
                .padding(.horizontal, Spacing.pagePadding)
                .padding(.vertical, Spacing.md)
                .background(Color.white.opacity(0.95))
            }
        }
        .onAppear {
            // 如果有指定的初始卡片标题，设置对应的索引
            if let title = initialCardTitle {
                if let index = todayLearningService.indexOfCard(withTitle: title) {
                    currentCardIndex = index
                }
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Image(systemName: "book.fill")
                .font(.title2)
                .foregroundColor(.brandPrimary500)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("今日学习任务")
                    .font(.bodyLarge)
                    .fontWeight(.semibold)
                    .foregroundColor(.brandSecondary900)

                Text("已掌握 \(todayLearningService.learnedCount)/3 个知识点")
                    .font(.bodySmall)
                    .foregroundColor(.brandSecondary600)
            }

            Spacer()
        }
        .padding(.horizontal, Spacing.pagePadding)
        .padding(.top, Spacing.sm)
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<todayLearningService.todayCards.count, id: \.self) { index in
                let card = todayLearningService.todayCards[index]
                Circle()
                    .fill(getCardStatusColor(card: card, index: index))
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: index == currentCardIndex ? 2 : 0)
                    )
            }
        }
        .padding(.vertical, Spacing.md)
    }

    private func getCardStatusColor(card: KnowledgeCard, index: Int) -> Color {
        if todayLearningService.todayTaskLearnedCardIds.contains(card.id) {
            return .brandSuccess500
        } else if todayLearningService.laterViewedCardIds.contains(card.id) {
            return .brandWarning500
        } else if index == currentCardIndex {
            return .brandPrimary500
        } else {
            return .brandSecondary300
        }
    }

    // MARK: - Card Views
    @ViewBuilder
    private func cardFullView(_ card: KnowledgeCard) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xxxxl) {
                // 卡片头部 - 标题区域
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(card.title)
                        .font(.title1)
                        .fontWeight(.bold)
                        .foregroundColor(.brandSecondary900)

                    // 装饰性分隔线
                    Rectangle()
                        .fill(Color.brandPrimary500)
                        .frame(height: 3)
                        .frame(maxWidth: 80)
                }

                // 主要内容
                VStack(alignment: .leading, spacing: Spacing.xxxxl) {
                    // What 部分
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("要点")
                            .font(.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(.brandPrimary600)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.brandPrimary100)
                            .cornerRadius(CornerRadius.sm)

                        Text(card.what)
                            .font(.bodyLarge)
                            .foregroundColor(.brandSecondary900)
                            .lineSpacing(6)
                    }

                    // Why 部分
                    DisclosureGroup {
                        Text(card.why)
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                            .lineSpacing(6)
                            .padding(.top, Spacing.md)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.brandWarning500)
                                .font(.body)
                            Text("Why")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                        }
                    }
                    .accentColor(.brandSecondary700)

                    // How 部分
                    DisclosureGroup {
                        Text(card.how)
                            .font(.body)
                            .foregroundColor(.brandSecondary700)
                            .lineSpacing(6)
                            .padding(.top, Spacing.md)
                    } label: {
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.brandSuccess500)
                                .font(.body)
                            Text("How")
                                .font(.bodyLarge)
                                .fontWeight(.semibold)
                                .foregroundColor(.brandSecondary900)
                        }
                    }
                    .accentColor(.brandSecondary700)

                    // 标签区域
                    HStack {
                        ForEach(card.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.brandSecondary100)
                                .foregroundColor(.brandSecondary700)
                                .cornerRadius(CornerRadius.lg)
                        }
                        Spacer()
                    }
                }
            }
            .padding(Spacing.xxxxl)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(Color.cardBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .stroke(Color.brandSecondary200, lineWidth: 1)
        )
    }

    // MARK: - State Views
    private var completedState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.brandSuccess500)

            VStack(spacing: Spacing.sm) {
                Text("今日学习完成！")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.brandSecondary900)

                Text("已掌握所有今日学习内容")
                    .font(.body)
                    .foregroundColor(.brandSecondary600)
            }

            Button("重新抽取") {
                todayLearningService.refreshTodayCards()
                currentCardIndex = 0
            }
            .font(.bodyMedium)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.md)
            .background(Color.brandPrimary500)
            .cornerRadius(CornerRadius.lg)

            Spacer()
        }
        .padding(Spacing.pagePadding)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.brandSecondary300)

            Text("暂无学习内容")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)

            Text("请稍后再试")
                .font(.body)
                .foregroundColor(.brandSecondary500)

            Spacer()
        }
        .padding(Spacing.pagePadding)
    }

    // MARK: - Animation Methods
    private func dismissCard(direction: SwipeDirection, action: @escaping () -> Void) {
        let targetX: CGFloat = direction == .right ? 500 : -500
        let targetRotation: Double = direction == .right ? 30 : -30

        // 设置烟花效果
        fireworkText = direction == .right ? "掌握" : "稍后"
        fireworkColor = direction == .right ? .brandSuccess500 : .brandWarning500

        withAnimation(.easeIn(duration: 0.3)) {
            isDismissing = true
            dragOffset = targetX
            cardRotation = targetRotation
            cardOpacity = 0
        }

        // 显示烟花效果
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                showingFirework = true
            }
        }

        // 执行动作和重置
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            action()
            resetCardState()
        }
    }

    private func resetCardState() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            dragOffset = 0
            cardRotation = 0
            cardOpacity = 1.0
            isDismissing = false
            showingFirework = false
        }
    }

    private func moveToNextCard() {
        if currentCardIndex < todayLearningService.todayCards.count - 1 {
            currentCardIndex += 1
        } else {
            // 到达最后一张卡片时，回到第一张重新开始
            currentCardIndex = 0
        }
    }
}

// 定义滑动方向枚举
enum SwipeDirection {
    case left, right
}

// MARK: - 烟花文字效果组件
struct TodayFireworkTextView: View {
    let text: String
    let color: Color
    @State private var particles: [TodayFireworkParticle] = []
    @State private var textOpacity: Double = 0
    @State private var textScale: Double = 0.5

    var body: some View {
        ZStack {
            // 主文字
            Text(text)
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(color)
                .opacity(textOpacity)
                .scaleEffect(textScale)
                .onAppear {
                    // 文字动画
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        textOpacity = 1.0
                        textScale = 1.0
                    }

                    // 添加粒子
                    generateParticles()

                    // 文字消散
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            textOpacity = 0
                            textScale = 1.2
                        }
                    }
                }

            // 粒子效果
            ForEach(particles.indices, id: \.self) { index in
                Circle()
                    .fill(particles[index].color)
                    .frame(width: particles[index].size, height: particles[index].size)
                    .offset(particles[index].offset)
                    .opacity(particles[index].opacity)
                    .onAppear {
                        animateParticle(at: index)
                    }
            }
        }
    }

    private func generateParticles() {
        particles = (0..<20).map { _ in
            TodayFireworkParticle(
                color: [color, color.opacity(0.8), Color.white].randomElement() ?? color,
                size: CGFloat.random(in: 4...8),
                offset: .zero,
                opacity: 1.0
            )
        }
    }

    private func animateParticle(at index: Int) {
        let angle = Double.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 50...120)
        let targetOffset = CGSize(
            width: Foundation.cos(angle) * distance,
            height: Foundation.sin(angle) * distance
        )

        withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5))) {
            particles[index].offset = targetOffset
            particles[index].opacity = 0
        }
    }
}

struct TodayFireworkParticle {
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double
}

#Preview {
    TodayLearningModalView(isPresented: .constant(true))
}