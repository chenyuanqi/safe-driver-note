import SwiftUI

struct EnhancedTagInputView: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    // 用于临时输入的文本
    @State private var inputText: String = ""
    
    // 已解析的标签
    private var tags: [String] {
        parseTags(from: text)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 已添加的标签展示区域
            if !tags.isEmpty {
                FlowLayoutView(tags: tags) { tag in
                    TagView(tag: tag) {
                        removeTag(tag)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 输入区域
            HStack {
                TextField("输入标签，回车或逗号分隔", text: $inputText)
                    .focused($isFocused)
                    .onSubmit {
                        addTagFromInput()
                    }
                    .onChange(of: inputText) { _, newValue in
                        checkAndAddTagIfNeeded(newValue)
                    }
                
                Button(action: addTagFromInput) {
                    Image(systemName: "plus")
                }
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
            
            // 推荐标签
            RecommendedTagsView(currentTags: tags) { tag in
                addTag(tag)
            }
        }
        .onAppear {
            // 初始化时清空输入框
            inputText = ""
        }
    }
    
    // 解析标签文本
    private func parseTags(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: ",，、;；\n\t ")
        return text.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { $0.lowercased() }
            .removingDuplicates()
    }
    
    // 检查是否需要添加标签
    private func checkAndAddTagIfNeeded(_ newValue: String) {
        // 如果输入中包含分隔符，则自动添加标签
        let separators = [",", "，", ";", "；", "\n"]
        for separator in separators {
            if newValue.contains(separator) {
                let parts = newValue.components(separatedBy: separator)
                for part in parts.dropLast() { // 除了最后一部分，其他都添加为标签
                    let trimmedPart = part.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedPart.isEmpty {
                        addTag(trimmedPart)
                    }
                }
                // 保留最后一部分在输入框中
                inputText = parts.last?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                break
            }
        }
    }
    
    // 从输入框添加标签
    private func addTagFromInput() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedText.isEmpty {
            addTag(trimmedText)
            inputText = ""
        }
    }
    
    // 添加标签
    private func addTag(_ tag: String) {
        let trimmedTag = tag.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedTag.isEmpty else { return }
        
        var currentTags = tags
        if !currentTags.contains(trimmedTag) {
            currentTags.append(trimmedTag)
            text = currentTags.joined(separator: ", ")
        }
    }
    
    // 删除标签
    private func removeTag(_ tag: String) {
        var currentTags = tags
        currentTags.removeAll { $0 == tag.lowercased() }
        text = currentTags.joined(separator: ", ")
    }
}

// 标签视图组件
struct TagView: View {
    let tag: String
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text("#\(tag)")
                .font(.caption)
                .foregroundColor(.white)
            
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue)
        .cornerRadius(8)
    }
}

// 推荐标签视图组件
struct RecommendedTagsView: View {
    let currentTags: [String]
    let onTagSelected: (String) -> Void
    
    @ObservedObject private var service = AppDI.shared.tagSuggestionService
    
    private var suggestions: [String] {
        service.suggestions(excluding: currentTags)
    }
    
    var body: some View {
        if !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("推荐标签")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(suggestions.prefix(10), id: \.self) { tag in
                            Button(action: {
                                onTagSelected(tag)
                            }) {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemFill))
                                    .foregroundColor(.primary)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// 流式布局容器
struct FlowLayoutView<TagView: View>: View {
    let tags: [String]
    let tagView: (String) -> TagView
    
    var body: some View {
        let rows = computeRows()
        
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<rows.count, id: \.self) { index in
                HStack(spacing: 4) {
                    ForEach(0..<rows[index].count, id: \.self) { tagIndex in
                        tagView(rows[index][tagIndex])
                    }
                }
            }
        }
    }
    
    private func computeRows() -> [[String]] {
        var rows: [[String]] = [[]]
        var currentRow = 0
        var currentRowWidth: CGFloat = 0
        
        let spacing: CGFloat = 4
        let screenWidth = UIScreen.main.bounds.width - 32 // 减去左右padding
        
        for tag in tags {
            // 估算标签宽度（这里简化处理，实际应该更精确）
            let tagWidth = CGFloat(tag.count * 10 + 30)
            
            if currentRowWidth + tagWidth > screenWidth {
                // 需要换行
                rows.append([])
                currentRow += 1
                currentRowWidth = tagWidth + spacing
                rows[currentRow].append(tag)
            } else {
                // 继续在当前行
                currentRowWidth += tagWidth + spacing
                rows[currentRow].append(tag)
            }
        }
        
        return rows
    }
}

// 数组去重扩展
extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

#Preview {
    @State var text = "倒车, 立柱, 后视镜"
    return VStack {
        EnhancedTagInputView(text: $text)
        Spacer()
    }
    .padding()
}