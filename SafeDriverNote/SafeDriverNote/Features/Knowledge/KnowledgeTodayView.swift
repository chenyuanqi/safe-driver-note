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
            VStack(alignment: .leading, spacing: 12) {
                Text(card.title)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                Text(card.what)
                    .font(.body)
                DisclosureGroup("Why") { Text(card.why).font(.body) }
                DisclosureGroup("How") { Text(card.how).font(.body) }
                HStack {
                    ForEach(card.tags, id: \.self) { t in
                        Text(t)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Spacer()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.brandSecondary100)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
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
