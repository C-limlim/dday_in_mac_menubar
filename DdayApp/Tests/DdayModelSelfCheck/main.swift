import Foundation
import AppKit

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 2))!
let first = calendar.date(from: DateComponents(year: 2026, month: 7, day: 5))!
let second = calendar.date(from: DateComponents(year: 2026, month: 7, day: 12))!
let items = [
    DdayItem(name: "생일", date: second, sortOrder: 2),
    DdayItem(name: "시험", date: first, sortOrder: 1),
    DdayItem(name: "숨김", date: first, isShownInMenuBar: false, sortOrder: 0)
]

assert(DdayModel.ddayText(for: today, today: today, calendar: calendar) == "D-Day")
assert(DdayModel.ddayText(for: today, today: first, calendar: calendar) == "D+3")
assert(DdayModel.menuBarLabel(for: items, today: today, calendar: calendar) == "시험 D-3     생일 D-10")
for (index, expected) in ["시험 D-3", "생일 D-10", "시험 D-3"].enumerated() {
    assert(DdayModel.menuBarLabel(
        for: items, today: today, calendar: calendar, displayMode: .rotating, rotationIndex: index
    ) == expected)
}
assert(DdayModel.menuBarLabel(for: [], displayMode: .rotating) == "")
assert(DdayModel.menuBarLabel(for: [items[2]], displayMode: .rotating) == "")

assert(DdayModel.validRotationSeconds(0.1) == 0.5)
assert(DdayModel.validRotationSeconds(1.5) == 1.5)
assert(DdayModel.validRotationSeconds(90) == 60)
for value in [Double.nan, .infinity, -.infinity] {
    assert(DdayModel.validRotationSeconds(value) == 10, "Non-finite intervals must use the default")
}

let suiteName = "DdayModelSelfCheck.\(UUID().uuidString)"
let defaults = UserDefaults(suiteName: suiteName)!
defer { defaults.removePersistentDomain(forName: suiteName) }
let model = DdayModel(defaults: defaults)
model.items = [
    DdayItem(name: "A", date: first, sortOrder: 0),
    DdayItem(name: "B", date: first, sortOrder: 1),
    DdayItem(name: "C", date: first, sortOrder: 2)
]
model.move(model.items[0], to: model.items[2])
assert(model.sortedItems.map(\.name) == ["B", "C", "A"])
model.move(model.items[2], to: model.items[0])
assert(model.sortedItems.map(\.name) == ["A", "B", "C"])
assert(DdayModel(defaults: defaults).sortedItems == model.sortedItems)

model.updateMenuBarDisplayMode(.rotating)
model.updateMenuBarRotationSeconds(1.5)
assert(DdayModel(defaults: defaults).menuBarRotationSeconds == 1.5)
for value in [Double.nan, .infinity, -.infinity] {
    model.updateMenuBarRotationSeconds(value)
    assert(model.menuBarRotationSeconds == 10)
}
model.updateMenuBarDisplayMode(.all)
assert(model.menuBarLabel == DdayModel.menuBarLabel(for: model.items))
assert(DdayModel(defaults: defaults).menuBarDisplayMode == .all)

for item in model.items { model.delete(item) }
assert(model.menuBarLabel.isEmpty)
assert(DdayModel(defaults: defaults).items.isEmpty)

defaults.removeObject(forKey: "ddayItems")
defaults.set(first, forKey: "ddayTargetDate")
defaults.set("Legacy", forKey: "ddayEventName")
let migrated = DdayModel(defaults: defaults)
assert(migrated.items.count == 1 && migrated.items[0].name == "Legacy")
assert(DdayModel(defaults: defaults).items == migrated.items)
let handle = DdayDragHandle.HandleView(labelWithString: "")
let session = NSDraggingSession()
assert(handle.draggingSession(session, sourceOperationMaskFor: .withinApplication) == .move)
assert(handle.draggingSession(session, sourceOperationMaskFor: .outsideApplication).isEmpty)
assert(handle.ignoreModifierKeys(for: session))
for operation: NSDragOperation in [[], .move] {
    var dragging = true
    handle.dragEnded = { dragging = false }
    handle.draggingSession(session, endedAt: .zero, operation: operation)
    assert(!dragging, "Success and cancellation must both clear the drag state")
}
print("Dday model and drag checks passed")
