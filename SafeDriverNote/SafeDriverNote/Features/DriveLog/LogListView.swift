import SwiftUI

struct LogListView: View {
    @StateObject private var vm = DriveLogViewModel(repository: AppDI.shared.logRepository)
    @State private var showingAdd = false
    @State private var searchText: String = ""
    @State private var selectedSegment: Segment = .all

    private enum Segment: Hashable, CaseIterable { case all, mistake, success }

    var body: some View {
        NavigationStack {
            Group {
                if filteredLogs.isEmpty { emptyState } else { list }
            }
            .navigationTitle("驾驶日志")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("全部") { vm.filter = nil; selectedSegment = .all }
                        Button("失误") { vm.filter = .mistake; selectedSegment = .mistake }
                        Button("成功") { vm.filter = .success; selectedSegment = .success }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .safeAreaInset(edge: .top) { header }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索场景/地点/标签")
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

    private var filteredLogs: [LogEntry] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return vm.logs }
        return vm.logs.filter { e in
            let hay = [e.detail, e.locationNote, e.scene, e.tags.joined(separator: " ")]
                .joined(separator: " ")
                .lowercased()
            return hay.contains(q)
        }
    }

    private var groupedByDay: [(key: String, items: [LogEntry])] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "zh_CN")
        df.calendar = Calendar(identifier: .gregorian)
        df.dateFormat = "yyyy年M月d日 EEEE"
        let groups = Dictionary(grouping: filteredLogs) { e in df.string(from: e.createdAt) }
        return groups
            .map { ($0.key, $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { lhs, rhs in lhs.items.first?.createdAt ?? .distantPast > rhs.items.first?.createdAt ?? .distantPast }
    }

    private var list: some View {
        List {
            ForEach(groupedByDay, id: \.key) { section in
                Section(section.key) {
                    ForEach(section.items, id: \.id) { log in
                        logCard(for: log)
                            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    if let idx = vm.logs.firstIndex(where: { $0.id == log.id }) {
                                        vm.delete(at: IndexSet(integer: idx))
                                    }
                                } label: { Label("删除", systemImage: "trash") }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { vm.beginEdit(log) }
                    }
                }
            }
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
            Text("开始记录你的安全驾驶之旅")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showingAdd = true
            } label: {
                Label("开始记录", systemImage: "plus.circle.fill")
            }
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Picker("类型", selection: Binding(get: {
                selectedSegment
            }, set: { seg in
                selectedSegment = seg
                switch seg {
                case .all: vm.filter = nil
                case .mistake: vm.filter = .mistake
                case .success: vm.filter = .success
                }
            })) {
                Text("全部").tag(Segment.all)
                Text("失误").tag(Segment.mistake)
                Text("成功").tag(Segment.success)
            }
            .pickerStyle(.segmented)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(vm.tagOptions, id: \.self) { tag in
                        Button {
                            vm.toggleMultiTag(tag)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: vm.selectedTags.contains(tag) ? "checkmark.circle.fill" : "circle")
                                Text(tag)
                            }
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                        }
                    }
                    Button(action: { vm.toggleShowAllTags() }) {
                        Label(vm.showAllTags ? "收起" : "更多(\(vm.fullTagCount))", systemImage: vm.showAllTags ? "chevron.up" : "ellipsis.circle")
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func logCard(for log: LogEntry) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(Self.zhCNFormatter.string(from: log.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(log.type == .mistake ? "失误" : "成功")
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background((log.type == .mistake ? Color.red.opacity(0.1) : Color.green.opacity(0.1)))
                    .foregroundColor(log.type == .mistake ? .red : .green)
                    .clipShape(Capsule())
            }
            Text(title(for: log))
                .font(.body)
            if !log.locationNote.isEmpty || !log.scene.isEmpty {
                Text("📍 \(log.locationNote)  ·  \(log.scene)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                if let attach = vm.attachmentSummary(for: log) {
                    Text(attach)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            if !log.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(log.tags.prefix(6), id: \.self) { tag in
                        Text("#" + tag)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
