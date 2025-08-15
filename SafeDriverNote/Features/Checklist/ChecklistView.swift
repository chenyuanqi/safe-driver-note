import SwiftUI

struct ChecklistView: View {
    @StateObject private var vm = ChecklistViewModel(repository: AppDI.shared.checklistRepository)

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Picker("Mode", selection: Binding(get: { vm.mode }, set: { vm.mode = $0 })) {
                    Text("行前").tag(ChecklistViewModel.Mode.pre)
                    Text("行后").tag(ChecklistViewModel.Mode.post)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                Text("进度: \(vm.score)%").font(.headline).padding(.horizontal)

                List {
                    Section(header: Text(vm.mode == .pre ? "行前检查" : "行后检查")) {
                        ForEach(itemsForMode(), id: \.key) { item in
                            Button(action: { vm.toggle(item: item.key) }) {
                                HStack {
                                    Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.checked ? .green : .secondary)
                                    Text(labelFor(key: item.key))
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("安全检查")
        }
    }

    private func itemsForMode() -> [ChecklistItemState] {
        vm.mode == .pre ? vm.record.pre : vm.record.post
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
