import SwiftUI
import AppKit
import ServiceManagement

@main
struct DdayApp: App {
    @StateObject private var model = DdayModel()

    init() {
        // 첫 설치 시 자동으로 로그인 항목 등록
        // ~/Applications 또는 /Applications에 있을 때만 성공함
        if !UserDefaults.standard.bool(forKey: "didRegisterLoginItem") {
            try? SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: "didRegisterLoginItem")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuContent()
                .environmentObject(model)
        } label: {
            HStack(spacing: 8) {
                if model.targetDate == nil {
                    Image(nsImage: Self.menuBarIcon)
                }
                if !model.menuBarLabel.isEmpty {
                    Text(model.menuBarLabel)
                }
            }
            .padding(.trailing, -16)
        }
        .menuBarExtraStyle(.menu)

        Window("D-Day 설정", id: "settings") {
            SettingsView()
                .environmentObject(model)
        }
        .windowResizability(.contentSize)
    }

    // NSImage + .large 스케일: 메뉴바용으로 최적화된 AppKit 렌더링
    static let menuBarIcon: NSImage = {
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium, scale: .large)
        let img = (NSImage(systemSymbolName: "calendar", accessibilityDescription: nil) ?? NSImage())
            .withSymbolConfiguration(config) ?? NSImage()
        img.isTemplate = true
        return img
    }()
}
