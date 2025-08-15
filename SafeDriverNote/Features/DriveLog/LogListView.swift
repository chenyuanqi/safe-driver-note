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
            if !vm.tagOptions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: { vm.toggleTagFilter(nil) }) {
                            Text("全部")
                                .font(.caption)
                                .padding(.horizontal,10).padding(.vertical,6)
                                .background(vm.tagFilter == nil ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }.buttonStyle(.plain)
                        ForEach(vm.tagOptions, id: \.self) { tag in
                            Button(action: { vm.toggleTagFilter(tag) }) {
                                HStack(spacing: 4) {
                                    Text("#" + tag)
                                }
                                .font(.caption)
                                .padding(.horizontal,10).padding(.vertical,6)
                                .background(vm.tagFilter == tag ? Color.accentColor.opacity(0.25) : Color.accentColor.opacity(0.08))
                                .overlay(
                                    Capsule().stroke(vm.tagFilter == tag ? Color.accentColor : Color.clear, lineWidth: 1)
                                )
                                .clipShape(Capsule())
                            }.buttonStyle(.plain)
                        }
                    }.padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            }
            ForEach(vm.logs, id: \.id) { log in
                VStack(alignment: .leading, spacing: 4) {
                    Text(log.createdAt, style: .date) + Text(" ") + Text(log.createdAt, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(prefixIcon(for: log.type) + log.detail)
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
                                Text("#" + tag).font(.caption2).padding(.horizontal,6).padding(.vertical,2).background(Color.accentColor.opacity(0.1)).clipShape(Capsule())
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
}

#Preview { LogListView() }
