import Foundation
import Combine

struct DdayItem: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var date: Date
    var isShownInMenuBar: Bool
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        date: Date,
        isShownInMenuBar: Bool = true,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.date = date
        self.isShownInMenuBar = isShownInMenuBar
        self.sortOrder = sortOrder
    }
}

enum MenuBarDisplayMode: String {
    case all
    case rotating
}

class DdayModel: ObservableObject {
    @Published var menuBarLabel: String = ""
    @Published private(set) var menuBarDisplayMode: MenuBarDisplayMode = .all
    @Published private(set) var menuBarRotationSeconds = 10.0
    @Published var items: [DdayItem] = []

    private static let itemsKey = "ddayItems"
    private static let displayModeKey = "menuBarDisplayMode"
    private static let rotationSecondsKey = "menuBarRotationSeconds"
    private var rotationIndex = 0
    private var timer: AnyCancellable?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        loadSettings()
        refresh()
        startTimer()
    }

    func refresh() {
        menuBarLabel = Self.menuBarLabel(
            for: items,
            displayMode: menuBarDisplayMode,
            rotationIndex: rotationIndex
        )
    }

    var sortedItems: [DdayItem] {
        items.sorted(by: Self.sortItems)
    }

    var visibleItems: [DdayItem] {
        sortedItems.filter(\.isShownInMenuBar)
    }

    func updateMenuBarDisplayMode(_ mode: MenuBarDisplayMode) {
        guard menuBarDisplayMode != mode else { return }
        menuBarDisplayMode = mode
        rotationIndex = 0
        defaults.set(mode.rawValue, forKey: Self.displayModeKey)
        refresh()
        startTimer()
    }

    func updateMenuBarRotationSeconds(_ seconds: Double) {
        let seconds = Self.validRotationSeconds(seconds)
        guard menuBarRotationSeconds != seconds else { return }
        menuBarRotationSeconds = seconds
        defaults.set(seconds, forKey: Self.rotationSecondsKey)
        startTimer()
    }

    func addItem() {
        let nextOrder = (items.map(\.sortOrder).max() ?? -1) + 1
        items.append(DdayItem(name: "이벤트", date: Date(), sortOrder: nextOrder))
        saveSettings()
        refresh()
    }

    func update(_ item: DdayItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        saveSettings()
        refresh()
    }

    func delete(_ item: DdayItem) {
        items.removeAll { $0.id == item.id }
        items = Self.normalized(items)
        saveSettings()
        refresh()
    }

    func move(fromOffsets source: IndexSet, toOffset destination: Int) {
        let currentItems = sortedItems
        guard !source.isEmpty, source.allSatisfy(currentItems.indices.contains) else { return }

        let movingItems = source.sorted().map { currentItems[$0] }
        var remainingItems = currentItems.enumerated()
            .filter { !source.contains($0.offset) }
            .map(\.element)
        let removedBeforeDestination = source.filter { $0 < destination }.count
        let insertionIndex = min(max(destination - removedBeforeDestination, 0), remainingItems.count)
        remainingItems.insert(contentsOf: movingItems, at: insertionIndex)
        items = Self.renumbered(remainingItems)
        saveSettings()
        refresh()
    }

    func move(_ item: DdayItem, to target: DdayItem) {
        let currentItems = sortedItems
        guard
            let source = currentItems.firstIndex(where: { $0.id == item.id }),
            let destination = currentItems.firstIndex(where: { $0.id == target.id }),
            source != destination
        else { return }

        move(fromOffsets: IndexSet(integer: source), toOffset: destination > source ? destination + 1 : destination)
    }

    static func ddayText(for date: Date, today: Date = Date(), calendar: Calendar = .current) -> String {
        let todayStart = calendar.startOfDay(for: today)
        let targetStart = calendar.startOfDay(for: date)
        let delta = calendar.dateComponents([.day], from: todayStart, to: targetStart).day ?? 0

        if delta > 0 { return "D-\(delta)" }
        if delta == 0 { return "D-Day" }
        return "D+\(abs(delta))"
    }

    static func itemLabel(for item: DdayItem, today: Date = Date(), calendar: Calendar = .current) -> String {
        let name = shortName(item.name.trimmingCharacters(in: .whitespacesAndNewlines))
        let dday = ddayText(for: item.date, today: today, calendar: calendar)
        return name.isEmpty ? dday : "\(name) \(dday)"
    }

    static func menuBarLabel(
        for items: [DdayItem],
        today: Date = Date(),
        calendar: Calendar = .current,
        displayMode: MenuBarDisplayMode = .all,
        rotationIndex: Int = 0
    ) -> String {
        let labels = items
            .filter(\.isShownInMenuBar)
            .sorted(by: sortItems)
            .map { itemLabel(for: $0, today: today, calendar: calendar) }

        switch displayMode {
        case .all:
            return labels.joined(separator: "     ")
        case .rotating:
            guard !labels.isEmpty else { return "" }
            return labels[rotationIndex % labels.count]
        }
    }

    private func tick() {
        if menuBarDisplayMode == .rotating {
            let count = visibleItems.count
            rotationIndex = count > 1 ? (rotationIndex + 1) % count : 0
        }
        refresh()
    }

    private func startTimer() {
        let interval = menuBarDisplayMode == .rotating ? menuBarRotationSeconds : 60
        timer = Timer.publish(every: TimeInterval(interval), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Self.itemsKey)
    }

    private func loadSettings() {
        if
            let rawMode = defaults.string(forKey: Self.displayModeKey),
            let mode = MenuBarDisplayMode(rawValue: rawMode)
        {
            menuBarDisplayMode = mode
        }
        let rotationSeconds = defaults.double(forKey: Self.rotationSecondsKey)
        if rotationSeconds > 0 {
            menuBarRotationSeconds = Self.validRotationSeconds(rotationSeconds)
        }

        if
            let data = defaults.data(forKey: Self.itemsKey),
            let decoded = try? JSONDecoder().decode([DdayItem].self, from: data)
        {
            items = Self.normalized(decoded)
            return
        }

        guard let oldDate = defaults.object(forKey: "ddayTargetDate") as? Date else { return }
        let oldName = defaults.string(forKey: "ddayEventName") ?? ""
        items = [DdayItem(name: oldName, date: oldDate, sortOrder: 0)]
        saveSettings()
    }

    private static func normalized(_ items: [DdayItem]) -> [DdayItem] {
        renumbered(items.sorted(by: sortItems))
    }

    private static func renumbered(_ items: [DdayItem]) -> [DdayItem] {
        items.enumerated().map { index, item in
            var item = item
            item.sortOrder = index
            return item
        }
    }

    private static func sortItems(_ lhs: DdayItem, _ rhs: DdayItem) -> Bool {
        if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        if lhs.name != rhs.name { return lhs.name < rhs.name }
        return lhs.id.uuidString < rhs.id.uuidString
    }

    private static func shortName(_ name: String) -> String {
        name.count > 12 ? "\(name.prefix(12))..." : name
    }

    static func validRotationSeconds(_ seconds: Double) -> Double {
        guard seconds.isFinite else { return 10 }
        return min(max(seconds, 0.5), 60)
    }
}
