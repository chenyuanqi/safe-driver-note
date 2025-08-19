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
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(p.createdAt, format: Date.FormatStyle(date: .omitted, time: .shortened).locale(Locale(identifier: "zh_CN")))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(vm.titles(for: p).joined(separator: "、"))
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
                    Section(header: Text("自定义项目")) {
                        let customItems = vm.mode == .pre ? vm.itemsPre : vm.itemsPost
                        ForEach(customItems, id: \.id) { ci in
                            HStack {
                                Text(ci.title)
                                Spacer()
                                Button("编辑") { editingItem = ci; newTitle = ci.title }
                                    .buttonStyle(.bordered)
                            }
                            .swipeActions {
                                Button(role: .destructive) { vm.deleteItem(ci) } label: { Label("删除", systemImage: "trash") }
                            }
                        }
                        Button(action: { showingAdd = true; newTitle = "" }) { Label("添加项目", systemImage: "plus") }
                    }
                }
                .listStyle(.insetGrouped)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        HStack {
                            Button("历史") { showingHistory = true }
                            Button("打卡") { showingPunch = true }
                        }
                    }
                }
            }
            .navigationTitle("检查")
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
                    Form { TextField("项目名称", text: $newTitle) }
                        .navigationTitle("编辑项目")
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("保存") { vm.editItem(item, newTitle: newTitle); editingItem = nil } } }
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

#Preview {
    ChecklistView()
}
