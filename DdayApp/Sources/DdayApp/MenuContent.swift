import SwiftUI
import ServiceManagement

// Select the property wrapper on SDKs that also export a State macro.
private typealias ViewState<Value> = SwiftUI.State<Value>

struct MenuContent: View {
    @EnvironmentObject var model: DdayModel
    @Environment(\.openWindow) private var openWindow
    @ViewState private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

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
    @ViewState private var draggingItem: DdayItem?

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

            HStack {
                Text("메뉴바 표시")
                Spacer()
                Picker("", selection: displayModeBinding) {
                    Text("전체 표시").tag(MenuBarDisplayMode.all)
                    Text("하나씩 표시").tag(MenuBarDisplayMode.rotating)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 220)
            }

            if model.menuBarDisplayMode == .rotating {
                HStack {
                    Text("전환 간격")
                    Spacer()
                    TextField("", value: rotationSecondsBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 72)
                    Text("초")
                        .foregroundStyle(.secondary)
                }
            }

            if model.sortedItems.isEmpty {
                Text("추가 버튼으로 D-Day를 등록하세요.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(model.sortedItems) { item in
                            DdayItemRow(
                                item: binding(for: item),
                                dragStarted: {
                                    draggingItem = item
                                },
                                dragEnded: { draggingItem = nil },
                                delete: { model.delete(item) }
                            )
                            .opacity(draggingItem?.id == item.id ? 0.55 : 1)
                            .background {
                                if draggingItem?.id == item.id {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.accentColor.opacity(0.08))
                                }
                            }
                            .overlay {
                                if draggingItem?.id == item.id {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentColor, lineWidth: 2)
                                }
                            }
                            .onDrop(
                                of: [DdayDragHandle.pasteboardType.rawValue],
                                delegate: DdayDropDelegate(
                                    target: item,
                                    draggingItem: $draggingItem,
                                    model: model
                                )
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 320)
                .onDrop(
                    of: [DdayDragHandle.pasteboardType.rawValue],
                    delegate: DdayDropEndDelegate(draggingItem: $draggingItem)
                )
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

    private var displayModeBinding: Binding<MenuBarDisplayMode> {
        Binding(
            get: { model.menuBarDisplayMode },
            set: { model.updateMenuBarDisplayMode($0) }
        )
    }

    private var rotationSecondsBinding: Binding<Double> {
        Binding(
            get: { model.menuBarRotationSeconds },
            set: { model.updateMenuBarRotationSeconds($0) }
        )
    }
}

struct DdayItemRow: View {
    @Binding var item: DdayItem
    let dragStarted: () -> Void
    let dragEnded: () -> Void
    let delete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            DdayDragHandle(itemID: item.id, dragStarted: dragStarted, dragEnded: dragEnded)
                .frame(width: 18, height: 22)

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

            Spacer()

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

private struct DdayDropDelegate: DropDelegate {
    let target: DdayItem
    @Binding var draggingItem: DdayItem?
    let model: DdayModel

    func validateDrop(info: DropInfo) -> Bool {
        draggingItem != nil && info.hasItemsConforming(to: [DdayDragHandle.pasteboardType.rawValue])
    }

    func dropEntered(info: DropInfo) {
        guard let draggingItem else { return }
        withAnimation(.easeInOut(duration: 0.18)) {
            model.move(draggingItem, to: target)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: draggingItem == nil ? .forbidden : .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard draggingItem != nil else { return false }
        draggingItem = nil
        return true
    }
}

private struct DdayDropEndDelegate: DropDelegate {
    @Binding var draggingItem: DdayItem?

    func validateDrop(info: DropInfo) -> Bool {
        draggingItem != nil && info.hasItemsConforming(to: [DdayDragHandle.pasteboardType.rawValue])
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: draggingItem == nil ? .forbidden : .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        guard draggingItem != nil else { return false }
        draggingItem = nil
        return true
    }
}
