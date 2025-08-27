import SwiftUI
import Foundation

enum SwipeDirection {
    case left, right
}

struct KnowledgeTodayView: View {
    @StateObject private var vm = KnowledgeViewModel(repository: AppDI.shared.knowledgeRepository)
    @State private var dragOffset: CGFloat = 0
    @State private var cardRotation: Double = 0
    @State private var showingFirework = false
    @State private var fireworkText = ""
    @State private var fireworkColor = Color.brandPrimary500
    @State private var cardOpacity: Double = 1.0
    @State private var isDismissing = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                Color.brandSecondary50
                    .ignoresSafeArea()
                
                Group {
                    if let card = vm.today.first {
                        GeometryReader { geo in
                            let cardHeight = geo.size.height * 0.7
                            VStack(spacing: Spacing.xl) {
                                Spacer(minLength: 0)
                                
                                ZStack {
                                    // 主卡片
                                    cardFullView(card)
                                        .frame(height: cardHeight)
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
                                                            vm.mark(card: card)
                                                        })
                                                    } else if dx < -120 { // 左滑：稍后
                                                        dismissCard(direction: .left, action: {
                                                            vm.snooze(card: card)
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
                                        FireworkTextView(text: fireworkText, color: fireworkColor)
                                    }
                                }
                                
                                // 提示文字
                                Text("左滑稍后，右滑掌握")
                                    .font(.bodySmall)
                                    .foregroundColor(.brandSecondary500)
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, Spacing.pagePadding)
                        }
                    } else {
                        emptyState
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay(alignment: .top) {
                // 自定义导航栏
                StandardNavigationBar(
                    title: "今日知识",
                    showBackButton: false,
                    trailingButtons: [
                        StandardNavigationBar.NavBarButton(icon: "arrow.triangle.2.circlepath") {
                            vm.loadToday()
                        }
                    ]
                )
            }
        }
    }
    
    // MARK: - 动画方法
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

    @ViewBuilder
    private func cardFullView(_ card: KnowledgeCard) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                // 卡片头部 - 标题区域
                VStack(alignment: .leading, spacing: Spacing.md) {
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
                VStack(alignment: .leading, spacing: Spacing.xxl) {
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
            .padding(Spacing.xxxl)
        }
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xl, style: .continuous)
                .stroke(Color.brandSecondary200, lineWidth: 1)
        )
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.brandSecondary300)
            
            Text("今日已全部掌握 🎉")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.brandSecondary900)
            
            Text("明日再来学习新知识！")
                .font(.body)
                .foregroundColor(.brandSecondary500)
            
            Button("重新抽取") {
                vm.loadToday()
            }
            .font(.bodyMedium)
            .fontWeight(.medium)
            .foregroundColor(.brandPrimary500)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.lg)
            .background(Color.brandPrimary100)
            .cornerRadius(CornerRadius.lg)
            
            Spacer()
        }
        .padding(Spacing.pagePadding)
    }
}

// MARK: - 烟花文字效果组件
struct FireworkTextView: View {
    let text: String
    let color: Color
    @State private var particles: [FireworkParticle] = []
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
            FireworkParticle(
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

struct FireworkParticle {
    let color: Color
    let size: CGFloat
    var offset: CGSize
    var opacity: Double
}

#Preview { KnowledgeTodayView() }
