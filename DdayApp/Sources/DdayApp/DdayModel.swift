import Foundation
import Combine

class DdayModel: ObservableObject {
    @Published var menuBarLabel: String = "날짜 설정"
    @Published var targetDate: Date? = nil
    @Published var eventName: String = "이벤트"

    private var timer: AnyCancellable?

    init() {
        loadSettings()
        refresh()
        // 매 분 갱신
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        guard let targetDate else {
            menuBarLabel = ""
            return
        }
        var cal = Calendar.current
        cal.timeZone = TimeZone.current
        let today = cal.startOfDay(for: Date())
        let target = cal.startOfDay(for: targetDate)
        let delta = cal.dateComponents([.day], from: today, to: target).day ?? 0
        let dday: String
        if delta > 0 { dday = "D-\(delta)" }
        else if delta == 0 { dday = "D-Day" }
        else { dday = "D+\(abs(delta))" }
        menuBarLabel = eventName.isEmpty ? dday : "\(eventName)  \(dday)"
    }

    func setTarget(date: Date, name: String) {
        targetDate = date
        eventName = name
        saveSettings()
        refresh()
    }

    func clearTarget() {
        targetDate = nil
        eventName = ""
        UserDefaults.standard.removeObject(forKey: "ddayTargetDate")
        UserDefaults.standard.removeObject(forKey: "ddayEventName")
        refresh()
    }

    private func saveSettings() {
        UserDefaults.standard.set(targetDate, forKey: "ddayTargetDate")
        UserDefaults.standard.set(eventName, forKey: "ddayEventName")
    }

    private func loadSettings() {
        targetDate = UserDefaults.standard.object(forKey: "ddayTargetDate") as? Date
        eventName = UserDefaults.standard.string(forKey: "ddayEventName") ?? ""
    }
}
