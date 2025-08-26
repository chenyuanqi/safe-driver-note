import SwiftUI

struct KnowledgeTodayView: View {
    @StateObject private var vm = KnowledgeViewModel(repository: AppDI.shared.knowledgeRepository)
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            Group {
                if let card = vm.today.first {
                    GeometryReader { geo in
                        let cardHeight = geo.size.height * 0.66
                        VStack(spacing: 12) {
                            Spacer(minLength: 0)
                            cardFullView(card)
                                .frame(height: cardHeight)
                                .offset(x: dragOffset)
                                .rotationEffect(.degrees(Double(dragOffset / 20)))
                                .opacity(1.0 - Double(min(abs(dragOffset) / 600, 0.4)))
                                .overlay(alignment: .topLeading) {
                                    if dragOffset < 0 {
                                        feedbackLabel(text: "稍后", color: .blue, opacity: min(Double(abs(dragOffset) / 120), 1.0))
                                            .padding(12)
                                    }
                                }
                                .overlay(alignment: .topTrailing) {
                                    if dragOffset > 0 {
                                        feedbackLabel(text: "掌握", color: .green, opacity: min(Double(abs(dragOffset) / 120), 1.0))
                                            .padding(12)
                                    }
                                }
                                .gesture(
                                    DragGesture(minimumDistance: 20)
                                        .onChanged { value in
                                            dragOffset = value.translation.width
                                        }
                                        .onEnded { value in
                                            let dx = value.translation.width
                                            if dx > 100 { // 右滑：掌握
                                                withAnimation(.spring) { vm.mark(card: card); dragOffset = 0 }
                                            } else if dx < -100 { // 左滑：稍后
                                                withAnimation(.spring) { vm.snooze(card: card); dragOffset = 0 }
                                            } else {
                                                withAnimation(.spring) { dragOffset = 0 }
                                            }
                                        }
                                )
                            Text("提示：右滑=掌握，左滑=稍后再看")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal)
                    }
                } else {
                    emptyState
                }
            }
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("今日知识")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(Color.brandSecondary900)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("同步网络知识") { Task { await vm.syncRemote() } }
                        Button("重新抽取") { vm.loadToday() }
                    } label: { Image(systemName: "arrow.triangle.2.circlepath") }
                }
            }
        }
    }

    @ViewBuilder
    private func feedbackLabel(text: String, color: Color, opacity: Double) -> some View {
        Text(text)
            .font(.headline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
            .opacity(opacity)
    }

    @ViewBuilder
    private func cardFullView(_ card: KnowledgeCard) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 卡片头部 - 标题区域
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.title)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    // 装饰性分隔线
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.6), .white.opacity(0.2)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 主要内容
                VStack(alignment: .leading, spacing: 16) {
                    // What 部分
                    VStack(alignment: .leading, spacing: 8) {
                        Text("要点")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                        
                        Text(card.what)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .lineSpacing(4)
                    }
                    
                    // Why 部分
                    DisclosureGroup {
                        Text(card.why)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                            .padding(.top, 8)
                    } label: {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 16))
                            Text("Why")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accentColor(.white)
                    
                    // How 部分
                    DisclosureGroup {
                        Text(card.how)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                            .padding(.top, 8)
                    } label: {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.green)
                                .font(.system(size: 16))
                            Text("How")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .accentColor(.white)
                    
                    // 标签区域
                    HStack {
                        ForEach(card.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.2))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.4), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(
            // 卡牌渐变背景
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.2, green: 0.4, blue: 0.8),
                            Color(red: 0.1, green: 0.3, blue: 0.7),
                            Color(red: 0.05, green: 0.2, blue: 0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // 内部光晕效果
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(
                    // 顶部高光
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.1), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        // 卡牌阴影效果
        .shadow(
            color: Color.black.opacity(0.3),
            radius: 15,
            x: 0,
            y: 8
        )
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        // 边框效果
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "book")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("今日已全部掌握 🎉")
                .font(.headline)
            Button("重新抽取") { vm.loadToday() }
            Spacer()
        }.padding()
    }
}

#Preview { KnowledgeTodayView() }
