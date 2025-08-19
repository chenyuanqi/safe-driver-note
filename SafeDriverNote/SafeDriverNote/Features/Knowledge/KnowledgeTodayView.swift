import SwiftUI

struct KnowledgeTodayView: View {
    @StateObject private var vm = KnowledgeViewModel(repository: AppDI.shared.knowledgeRepository)

    var body: some View {
        NavigationStack {
            Group {
                if vm.today.isEmpty {
                    emptyState
                } else {
                    List(vm.today, id: \.id) { card in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack { Text(card.title).font(.headline); Spacer() }
                            Text(card.what).font(.subheadline)
                            DisclosureGroup("Why") { Text(card.why) }
                            DisclosureGroup("How") { Text(card.how) }
                            HStack {
                                ForEach(card.tags, id: \.self) { t in
                                    Text(t).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2).background(Color.blue.opacity(0.1)).clipShape(Capsule())
                                }
                                Spacer()
                                Button("掌握") { vm.mark(card: card) }
                                    .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("今日知识")
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("刷新") { vm.loadToday() } } }
        }
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
