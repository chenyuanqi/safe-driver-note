import SwiftUI

struct TagSuggestionView: View {
    @ObservedObject private var service = AppDI.shared.tagSuggestionService
    @Binding var currentInput: String

    @State private var searchPrefix: String = ""

    private var existingTags: [String] {
        currentInput.split { ",#\n\t ".contains($0) }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    private var suggestions: [String] {
        service.suggestions(prefix: searchPrefix, excluding: existingTags)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(suggestions, id: \.self) { tag in
                            Button(action: { add(tag) }) {
                                Text("#" + tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.15))
                                    .clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 4)
                }
            } else {
                Text("暂无推荐标签")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: currentInput) { _, newValue in
            searchPrefix = extractCurrentPrefix(from: newValue)
        }
        .onAppear { searchPrefix = extractCurrentPrefix(from: currentInput) }
    }

    private func add(_ tag: String) {
        var comps = existingTags
        guard !comps.contains(tag) else { return }
        comps.append(tag)
        currentInput = comps.joined(separator: ", ") + ", "
    }

    private func extractCurrentPrefix(from value: String) -> String {
        // 拿最后一个分隔后的片段作为前缀
        let parts = value.split(separator: ",").map { String($0) }
        if let last = parts.last {
            return last.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        return ""
    }
}

#Preview {
    @State var input = ""
    return VStack { TagSuggestionView(currentInput: $input); TextField("tags", text: $input) }.padding()
}
