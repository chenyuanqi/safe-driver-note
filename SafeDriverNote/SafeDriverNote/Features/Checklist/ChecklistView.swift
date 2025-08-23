import SwiftUI

struct ChecklistView: View {
    @StateObject private var vm = ChecklistViewModel(repository: AppDI.shared.checklistRepository)
    @State private var showingAdd = false
    @State private var newTitle: String = ""
    @State private var editingItem: ChecklistItem? = nil
    @State private var showingPunch = false
    @State private var tempSelectedIds = Set<UUID>()
    @State private var showingHistory = false
    @State private var showSavedAlert = false
    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Picker("Mode", selection: Binding(get: { vm.mode }, set: { vm.mode = $0 })) {
                    Text("行前").tag(ChecklistViewModel.Mode.pre)
                    Text("行后").tag(ChecklistViewModel.Mode.post)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                // 进度移除：按你的需求只保留自定义项维护与打卡

                List {
                    // 今日打卡记录
                    if !vm.punchesForCurrentMode.isEmpty {
                        Section(header: Text("今日打卡记录（\(vm.punchesForCurrentMode.count)次）")) {
                            ForEach(vm.punchesForCurrentMode, id: \.id) { p in
                                NavigationLink(value: p) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(p.createdAt, format: Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "zh_CN")))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        VStack(alignment: .leading, spacing: 6) {
                                            ForEach(vm.titles(for: p), id: \.self) { t in
                                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                                    Image(systemName: "checkmark.circle")
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    Text(t)
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                    }
                                }
                                .swipeActions {
                                    Button(role: .destructive) {
                                        deletePunch(p)
                                    } label: { Label("删除", systemImage: "trash") }
                                }
                            }
                        }
                    } else {
                        Section {
                            Text("今天还没有打卡，点右上角“打卡”即可勾选并保存一次记录。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // 移除模板项的勾选显示，只保留自定义项维护
                    Section(header:
                        HStack(alignment: .firstTextBaseline) {
                            Text("自定义项目")
                                .font(.headline)
                            Text("（可置顶与排序）")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    editMode = (editMode == .active ? .inactive : .active)
                                }
                            }) {
                                Image(systemName: (editMode == .active) ? "checkmark.seal.fill" : "gearshape")
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel(Text("编辑"))
                        }
                    ) {
                        if vm.mode == .pre {
                            ForEach(vm.itemsPre, id: \.id) { ci in
                                rowView(ci, isEditing: editMode == .active)
                            }
                            .onMove(perform: vm.moveItemsPre)
                        } else {
                            ForEach(vm.itemsPost, id: \.id) { ci in
                                rowView(ci, isEditing: editMode == .active)
                            }
                            .onMove(perform: vm.moveItemsPost)
                        }
                        Button(action: { showingAdd = true; newTitle = "" }) { Label("添加项目", systemImage: "plus") }
                    }
                }
                .environment(\.editMode, $editMode)
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            Button("历史") { showingHistory = true }
                            Button("打卡") { showingPunch = true }
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text("检查清单")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(Color.brandSecondary900)
                    }
                }
            }
            .navigationTitle("")
            .toolbarTitleDisplayMode(.inline)
            .navigationDestination(for: ChecklistPunch.self) { p in
                ChecklistPunchDetailView(punch: p).environmentObject(AppDI.shared)
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    Form { TextField("项目名称", text: $newTitle) }
                        .navigationTitle("添加项目")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("保存") { vm.addItem(title: newTitle, mode: vm.mode); showingAdd = false } } }
                }
            }
            .sheet(item: $editingItem) { item in
                NavigationStack {
                    Form {
                        Section {
                            TextEditor(text: $newTitle)
                                .frame(minHeight: 120)
                                .textInputAutocapitalization(.sentences)
                        }
                    }
                    .navigationTitle("")
                    .toolbarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("编辑项目").font(.system(size: 18, weight: .semibold))
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") { vm.editItem(item, newTitle: newTitle); editingItem = nil }
                        }
                    }
                }
            }
            .sheet(isPresented: $showingPunch) {
                NavigationStack {
                    Form {
                        Section(header: Text("请选择本次完成的项目")) {
                            let custom = vm.mode == .pre ? vm.itemsPre : vm.itemsPost
                            ForEach(custom, id: \.id) { it in
                                Toggle(it.title, isOn: Binding(
                                    get: { tempSelectedIds.contains(it.id) },
                                    set: { newVal in
                                        if newVal { tempSelectedIds.insert(it.id) } else { tempSelectedIds.remove(it.id) }
                                    }
                                ))
                            }
                        }
                        Section {
                            let allIds = (vm.mode == .pre ? vm.itemsPre : vm.itemsPost).map { $0.id }
                            Button(role: .none) {
                                tempSelectedIds = Set(allIds)
                                vm.punch(selectedItemIds: allIds)
                                tempSelectedIds.removeAll()
                                showingPunch = false
                                showSavedAlert = true
                            } label: { Label("一键完成并打卡", systemImage: "checkmark.circle.fill") }
                        }
                    }
                    .navigationTitle("本次打卡")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("取消") { showingPunch = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("保存") { vm.punch(selectedItemIds: Array(tempSelectedIds)); tempSelectedIds.removeAll(); showingPunch = false; showSavedAlert = true } }
                    }
                }
            }
            .sheet(isPresented: $showingHistory) {
                NavigationStack {
                    ChecklistHistoryView()
                        .environmentObject(AppDI.shared)
                        .navigationTitle("历史打卡")
                }
            }
            .onChange(of: vm.mode) { _, _ in vm.reloadPunchesToday() }
            .alert("已保存打卡", isPresented: $showSavedAlert) {
                Button("好的", role: .cancel) { }
            }
        }
    }

    private func itemsForMode() -> [ChecklistItemState] { vm.mode == .pre ? vm.record.pre : vm.record.post }

    // 无需额外导航函数
    private func deletePunch(_ p: ChecklistPunch) {
        try? AppDI.shared.checklistRepository.deletePunch(p)
        vm.reloadPunchesToday()
    }

    private func labelFor(key: String) -> String {
        switch key {
        case "tirePressure": return "胎压"
        case "lights": return "灯光"
        case "mirrors": return "后视镜"
        case "wipers": return "雨刷"
        case "fuel": return "油/电量"
        case "seatSteering": return "座椅方向盘"
        case "nav": return "导航"
        case "tools": return "随车工具"
        case "parkBrake": return "手刹/P档"
        case "windows": return "车窗"
        case "lightsOff": return "灯光关闭"
        case "valuables": return "贵重物品"
        case "lock": return "车门锁"
        default: return key
        }
    }
}

private extension ChecklistView {
    @ViewBuilder
    func rowView(_ ci: ChecklistItem, isEditing: Bool) -> some View {
        HStack(spacing: 12) {
            if (ci.isPinned ?? false) { Image(systemName: "pin.fill").foregroundStyle(.orange) }
            Text(ci.title)
                .font(.body)
            Spacer()
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture { if !isEditing { editingItem = ci; newTitle = ci.title } }
		.swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { vm.deleteItem(ci) } label: { Label("删除", systemImage: "trash") }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            let pinned = ci.isPinned ?? false
            Button { vm.togglePin(ci) } label: { Label(pinned ? "取消置顶" : "置顶", systemImage: pinned ? "pin.slash" : "pin") }
                .tint(pinned ? .gray : .orange)
        }
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.brandSecondary100)
    }
}

#Preview {
    ChecklistView()
}
