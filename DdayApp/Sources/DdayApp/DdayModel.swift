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

class DdayModel: ObservableObject {
    @Published var menuBarLabel: String = ""
    @Published var items: [DdayItem] = []

    private static let itemsKey = "ddayItems"
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
        menuBarLabel = Self.menuBarLabel(for: items)
    }

    var sortedItems: [DdayItem] {
        items.sorted(by: Self.sortItems)
    }

    var visibleItems: [DdayItem] {
        sortedItems.filter(\.isShownInMenuBar)
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

    static func menuBarLabel(for items: [DdayItem], today: Date = Date(), calendar: Calendar = .current) -> String {
        items
            .filter(\.isShownInMenuBar)
            .sorted(by: sortItems)
            .map { itemLabel(for: $0, today: today, calendar: calendar) }
            .joined(separator: "     ")
    }

    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Self.itemsKey)
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
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
}
