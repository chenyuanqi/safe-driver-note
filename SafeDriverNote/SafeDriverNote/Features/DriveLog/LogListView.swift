import SwiftUI

struct LogListView: View {
    @StateObject private var vm = DriveLogViewModel(repository: AppDI.shared.logRepository)
    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.logs.isEmpty { emptyState } else { list }
            }
            .navigationTitle("驾驶日志")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全部") { vm.filter = nil }
                        Button("失误") { vm.filter = .mistake }
                        Button("成功") { vm.filter = .success }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) { LogEditorView(entry: nil) { type, detail, location, scene, cause, improvement, tags, photos, audioFileName, transcript in
                vm.create(type: type,
                          detail: detail,
                          locationNote: location,
                          scene: scene,
                          cause: cause,
                          improvement: improvement,
                          rawTags: tags,
                          photoIds: photos,
                          audioFileName: audioFileName,
                          transcript: transcript)
            } }
            .sheet(item: $vm.editing) { entry in
                LogEditorView(entry: entry) { type, detail, location, scene, cause, improvement, tags, photos, audioFileName, transcript in
                    vm.update(entry: entry,
                              type: type,
                              detail: detail,
                              locationNote: location,
                              scene: scene,
                              cause: cause,
                              improvement: improvement,
                              rawTags: tags,
                              photoIds: photos,
                              audioFileName: audioFileName,
                              transcript: transcript)
                }
            }
        }
    }

    private var list: some View {
        List {
            ForEach(vm.logs, id: \.id) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text(Self.zhCNFormatter.string(from: log.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(title(for: log))
                    if !log.locationNote.isEmpty || !log.scene.isEmpty {
                        Text("📍 \(log.locationNote)  ·  \(log.scene)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if let attach = vm.attachmentSummary(for: log) {
                        Text(attach)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if !log.tags.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(log.tags.prefix(6), id: \.self) { tag in
                                Text("#" + tag)
                                    .font(.caption2)
                                    .padding(.horizontal,6)
                                    .padding(.vertical,2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture { vm.beginEdit(log) }
            }.onDelete(perform: vm.delete)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "car")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("还没有驾驶记录")
                .font(.headline)
            Button("开始记录") { showingAdd = true }
                .buttonStyle(.borderedProminent)
            Spacer()
        }.padding()
    }

    private func prefixIcon(for type: LogType) -> String { type == .mistake ? "⚠️ " : "✅ " }

    private func title(for log: LogEntry) -> String {
        let icon = prefixIcon(for: log.type)
        if !log.scene.isEmpty { return icon + log.scene }
        if !log.locationNote.isEmpty { return icon + log.locationNote }
        if !log.detail.isEmpty { return icon + String(log.detail.prefix(18)) }
        return icon + "记录"
    }

    // MARK: - Date Formatter (Chinese)
    private static let zhCNFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy年M月d日 HH:mm" // 示例：2025年8月18日 16:37
        return f
    }()
}

#Preview { LogListView() }
