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
            }
            .onAppear(perform: prefillIfNeeded)
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

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var emptyToNil: String? { trimmed.isEmpty ? nil : trimmed }
}

#Preview {
    LogEditorView(entry: nil) { _,_,_,_,_,_,_,_,_,_  in }
}
