import SwiftUI
import ServiceManagement

struct MenuContent: View {
    @EnvironmentObject var model: DdayModel
    @Environment(\.openWindow) private var openWindow
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        if model.visibleItems.isEmpty {
            Text("표시 중인 D-Day 없음")
                .foregroundStyle(.secondary)
        } else {
            ForEach(model.visibleItems) { item in
                Text(DdayModel.itemLabel(for: item))
                    .foregroundStyle(.secondary)
            }
        }

        Divider()

        Button("D-Day 관리...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }
        .keyboardShortcut("s")

        Button(launchAtLogin ? "✓ 로그인 시 자동 실행" : "로그인 시 자동 실행") {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.unregister()
                } else {
                    try SMAppService.mainApp.register()
                }
            } catch {
                print("Login item error: \(error)")
            }
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
        .onAppear {
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }

        Divider()

        Button("종료") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}

struct SettingsView: View {
    @EnvironmentObject var model: DdayModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("D-Day 관리")
                    .font(.headline)
                Spacer()
                Button {
                    model.addItem()
                } label: {
                    Label("추가", systemImage: "plus")
                }
                .keyboardShortcut("n")
            }

            if model.sortedItems.isEmpty {
                Text("추가 버튼으로 D-Day를 등록하세요.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                List {
                    ForEach(model.sortedItems) { item in
                        DdayItemRow(
                            item: binding(for: item),
                            delete: { model.delete(item) }
                        )
                    }
                    .onMove { source, destination in
                        model.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .listStyle(.plain)
                .frame(maxHeight: 320)
            }

            HStack {
                Spacer()
                Button("닫기") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 620)
    }

    private func binding(for item: DdayItem) -> Binding<DdayItem> {
        Binding(
            get: { model.items.first(where: { $0.id == item.id }) ?? item },
            set: { model.update($0) }
        )
    }
}

struct DdayItemRow: View {
    @Binding var item: DdayItem
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("☰")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)
                .help("드래그해서 순서 변경")
                .accessibilityLabel("드래그해서 순서 변경")

            Toggle("", isOn: $item.isShownInMenuBar)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .help("메뉴바 표시")

            TextField("이벤트 이름", text: $item.name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)

            DatePicker("", selection: $item.date, displayedComponents: .date)
                .labelsHidden()
                .frame(width: 150)

            Text(DdayModel.ddayText(for: item.date))
                .monospacedDigit()
                .frame(width: 64, alignment: .trailing)

            Button(role: .destructive) {
                delete()
            } label: {
                Image(systemName: "trash")
            }
            .help("삭제")
        }
    }
}
