import SwiftUI

struct LogEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var type: LogType = .mistake
    @State private var detail: String = ""
    @State private var locationNote: String = ""
    @State private var scene: String = ""
    @State private var cause: String = ""
    @State private var improvement: String = ""
    @State private var tags: String = "" // 逗号或空白分隔
    // 附件占位（未来接入图片选择与语音录制）
    @State private var photos: [String] = [] // 临时用本地标识符 / 文件名字符串
    @State private var audioFileName: String? = nil
    @State private var transcript: String? = nil

    // 快速输入
    @State private var showingQuickInput: Bool = false
    @State private var quickInputText: String = ""

    let entry: LogEntry?
    let onSave: (LogType, String, String, String, String?, String?, String, [String], String?, String?) -> Void

    var body: some View {
    NavigationStack {
            Form {
                typePickerSection
                locationSection
                detailSection
                if type == .mistake { analysisSection }
                tagsSection
                attachmentSection
            }
            .navigationTitle(entry == nil ? "新建日志" : "编辑日志")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { save() }.disabled(!formValid) }
                ToolbarItem(placement: .primaryAction) { Button("快速输入") { showingQuickInput = true } }
            }
            .onAppear(perform: prefillIfNeeded)
            .sheet(isPresented: $showingQuickInput) { quickInputSheet }
        }
    }

    private var formValid: Bool {
        !detail.trimmed.isEmpty && !locationNote.trimmed.isEmpty && !scene.trimmed.isEmpty && (type == .success || !cause.trimmed.isEmpty)
    }

    private func save() {
    onSave(type,
           detail.trimmed,
           locationNote.trimmed,
           scene.trimmed,
           cause.trimmed.emptyToNil,
           improvement.trimmed.emptyToNil,
           tags,
           photos,
           audioFileName,
           transcript)
        dismiss()
    }

    private func prefillIfNeeded() {
        guard let e = entry else { return }
        type = e.type
        detail = e.detail
        locationNote = e.locationNote
        scene = e.scene
        cause = e.cause ?? ""
        improvement = e.improvement ?? ""
        tags = e.tags.joined(separator: ", ")
        photos = e.photoLocalIds
        audioFileName = e.audioFileName
        transcript = e.transcript
    }

    @ViewBuilder
    private func placeholder(_ placeholderText: String, text: Binding<String>) -> some View {
        if text.wrappedValue.isEmpty {
            Text(placeholderText).foregroundStyle(.secondary).padding(.top, 8).padding(.leading, 5)
        }
    }

    // MARK: - Subviews

    @ViewBuilder private var typePickerSection: some View {
        Picker("类型", selection: $type) {
            Text("失误").tag(LogType.mistake)
            Text("成功").tag(LogType.success)
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder private var locationSection: some View {
        Section("地点 / 场景") {
            TextField("地点备注，如：商场地下车库", text: $locationNote)
            TextField("场景描述，如：直角弯、倒车入位", text: $scene)
        }
    }

    @ViewBuilder private var detailSection: some View {
        Section("详情") {
            TextEditor(text: $detail)
                .frame(minHeight: 120)
                .overlay(alignment: .topLeading) { placeholder("请输入事件详细经过", text: $detail) }
        }
    }

    @ViewBuilder private var analysisSection: some View {
        Section("失误分析") {
            TextField("原因分析", text: $cause, axis: .vertical)
                .lineLimit(1...4)
            TextField("改进方案", text: $improvement, axis: .vertical)
                .lineLimit(1...4)
        }
    }

    @ViewBuilder private var tagsSection: some View {
        Section {
            TextField("输入标签，逗号或空格分隔，例如：倒车 立柱 后视镜", text: $tags)
            TagSuggestionView(currentInput: $tags)
        } header: {
            Text("标签")
        } footer: {
            Text("最多 8 个；自动去重、转为小写。")
        }
    }

    @ViewBuilder private var attachmentSection: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("图片：\(photos.count) 张")
                    Text("语音：\(audioFileName == nil ? "无" : "已录制")")
                        .foregroundStyle(audioFileName == nil ? .secondary : .primary)
                    if let t = transcript, !t.isEmpty {
                        Text("转写预览：" + t.prefix(20) + (t.count > 20 ? "…" : ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                VStack(spacing: 8) {
                    Button("添加图片占位") { /* TODO: 打开图片选择器 */ }
                        .buttonStyle(.bordered)
                    Button("录音占位") { /* TODO: 打开录音 */ }
                        .buttonStyle(.bordered)
                }
            }
            .font(.subheadline)
        } header: {
            Text("附件 (占位)")
        } footer: {
            Text("当前为占位 UI；后续将接入 PHPicker 与语音转写。")
        }
    }
}

// MARK: - 快速输入解析
extension LogEditorView {
    @ViewBuilder private var quickInputSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("把今天的行车记录随便写在这里，我们会自动提取要点。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                TextEditor(text: $quickInputText)
                    .frame(minHeight: 220)
                    .overlay(alignment: .topLeading) { if quickInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { Text("例如：今天周末早上没什么车，很顺利就到公司；在快速路看到集群慢车，不要轻易脱离车流速度……").foregroundStyle(.secondary).padding(.top, 8).padding(.leading, 5) } }
                    .padding(.horizontal, 2)

                // 实时预览解析结果
                quickParsePreview
                Spacer()
            }
            .padding()
            .navigationTitle("快速输入")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("关闭") { showingQuickInput = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("解析并填充") {
                        applyQuickParse(text: quickInputText)
                        showingQuickInput = false
                    }.disabled(quickInputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    @ViewBuilder private var quickParsePreview: some View {
        let parsed = QuickParser.parse(text: quickInputText)
        VStack(alignment: .leading, spacing: 8) {
            Text("解析结果预览").font(.headline)
            HStack(spacing: 12) {
                Label(parsed.type == .mistake ? "失误" : "成功", systemImage: parsed.type == .mistake ? "exclamationmark.triangle" : "checkmark.seal")
                if let s = parsed.scene { Label(s, systemImage: "road.lanes") }
                if let loc = parsed.location { Label(loc, systemImage: "mappin.and.ellipse") }
                Label("标签 \(parsed.tags.count)", systemImage: "tag")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private func applyQuickParse(text: String) {
        let parsed = QuickParser.parse(text: text)
        type = parsed.type
        detail = parsed.detail
        scene = parsed.scene ?? scene
        locationNote = parsed.location ?? locationNote
        if !parsed.tags.isEmpty {
            let merged = (tags.splitOnDelimiters() + parsed.tags).map { $0.lowercased() }
            let dedup = Array(Set(merged)).sorted()
            tags = dedup.joined(separator: ", ")
        }
        if type == .mistake {
            // 简单启发式：包含“原因/改进”句子时填入
            if let causeLine = QuickParser.firstLine(matching: ["原因", "因为"]) (text) { cause = causeLine }
            if let improveLine = QuickParser.firstLine(matching: ["改进", "下次", "以后"]) (text) { improvement = improveLine }
        }
    }
}

private enum QuickParser {
    static func parse(text: String) -> ParsedLog {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        // 类型：包含顺利/顺溜/很顺/顺畅/开心 视为 success，否则默认 mistake；包含“失误/不好/不安/问题/险/差点/不对”强制 mistake
        let lower = normalized.lowercased()
        let positiveHints = ["顺利","顺溜","顺畅","很顺","开心","成功"]
        let negativeHints = ["失误","不好","不安","问题","险","差点","不对","糟糕"]
        let isNegative = negativeHints.contains(where: { normalized.contains($0) })
        let isPositive = positiveHints.contains(where: { normalized.contains($0) })
        let type: LogType = isNegative ? .mistake : (isPositive ? .success : .mistake)

        // 场景与地点：从关键词字典中提取首个命中；并尝试用“在…”句式抓取更自然的场景短语
        let sceneKeywords = ["高速","快速路","高架","城市快速路","国道","省道","环路","隧道","地库","停车场","倒车","倒车入位","侧方停车","直角弯","S弯","变道","并线","汇入","匝道","环岛","路口","人行横道"]
        let locationKeywords = ["公司","学校","商场","地下车库","地库","小区","家","服务区","收费站","停车场"]
        var scene = sceneKeywords.first(where: { normalized.contains($0.lowercased()) })
        let location = locationKeywords.first(where: { normalized.contains($0.lowercased()) })

        // 尝试从首个以“在”开头的短语抽取场景（例如“在快速路”、“在地库”）
        if scene == nil {
            let sentences = normalized.components(separatedBy: CharacterSet(charactersIn: "。！!？?\n")).map { $0.trimmingCharacters(in: .whitespaces) }
            if let s = sentences.first(where: { $0.hasPrefix("在") }) {
                // 取“在 … （逗号/句号前）”中的短语
                if let commaIdx = s.firstIndex(where: { ",，。.".contains($0) }) {
                    let phrase = String(s[s.startIndex..<commaIdx])
                    if phrase.count >= 2 { scene = phrase.replacingOccurrences(of: "在", with: "") }
                } else {
                    let phrase = s.replacingOccurrences(of: "在", with: "")
                    if phrase.count >= 1 { scene = phrase }
                }
            }
        }

        // 标签：从较大的关键词表中提取多个
        let tagDict = [
            "倒车","变道","并线","汇入","跟车","礼让","让行","观察","盲区","后视镜","A柱","B柱","转向灯","灯光","车距","并排","拥堵","急刹","打灯","停车","起步","车位","入位","侧方","直角","S弯","坡起","快车道","慢车","集群慢车","超车","保持车速","车流","车道线","限速","导航","口述","复盘","行人","周末","早上","晚上","安全距离"
        ]
        var tags: [String] = []
        for key in tagDict { if normalized.contains(key.lowercased()) { tags.append(key) } }
        // 常见扩展：把场景关键词也纳入标签
        if let s = scene { tags.append(s) }

        // 详情：原文全部作为详情（去除首尾空白）
        let detail = normalized

        return ParsedLog(type: type, detail: detail, scene: scene, location: location, tags: tags)
    }

    static func firstLine(matching hints: [String]) -> (String) -> String? {
        return { text in
            let lines = text.components(separatedBy: .newlines)
            for l in lines {
                for h in hints { if l.contains(h) { return l.trimmingCharacters(in: .whitespaces) } }
            }
            return nil
        }
    }
}

private struct ParsedLog { let type: LogType; let detail: String; let scene: String?; let location: String?; let tags: [String] }

private extension String {
    func splitOnDelimiters() -> [String] {
        let seps = CharacterSet(charactersIn: ",;\n \t")
        return self.components(separatedBy: seps).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var emptyToNil: String? { trimmed.isEmpty ? nil : trimmed }
}

#Preview {
    LogEditorView(entry: nil) { _,_,_,_,_,_,_,_,_,_  in }
}
