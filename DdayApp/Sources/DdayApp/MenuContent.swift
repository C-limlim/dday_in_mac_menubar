import SwiftUI
import ServiceManagement

struct MenuContent: View {
    @EnvironmentObject var model: DdayModel
    @Environment(\.openWindow) private var openWindow
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

    var body: some View {
        if let date = model.targetDate {
            Text("목표: \(formatted(date))")
                .foregroundStyle(.secondary)
            Divider()
        }

        Button("설정...") {
            NSApp.activate(ignoringOtherApps: true)
            openWindow(id: "settings")
        }
        .keyboardShortcut("s")

        if model.targetDate != nil {
            Button("초기화") {
                model.clearTarget()
            }
        }

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

    private func formatted(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone.current
        return f.string(from: date)
    }
}

struct SettingsView: View {
    @EnvironmentObject var model: DdayModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate: Date = Date()
    @State private var name: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("D-Day 설정")
                .font(.headline)

            Form {
                TextField("이벤트 이름", text: $name)
                    .textFieldStyle(.roundedBorder)
                DatePicker("목표 날짜", selection: $selectedDate, displayedComponents: .date)
            }

            HStack {
                Button("취소") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("저장") {
                    model.setTarget(date: selectedDate, name: name)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear {
            selectedDate = model.targetDate ?? Date()
            name = model.eventName
        }
    }
}
