import Foundation

var calendar = Calendar(identifier: .gregorian)
calendar.timeZone = TimeZone(secondsFromGMT: 0)!
let today = calendar.date(from: DateComponents(year: 2026, month: 7, day: 2))!
let first = calendar.date(from: DateComponents(year: 2026, month: 7, day: 5))!
let second = calendar.date(from: DateComponents(year: 2026, month: 7, day: 12))!

let items = [
    DdayItem(name: "생일", date: second, isShownInMenuBar: true, sortOrder: 2),
    DdayItem(name: "시험", date: first, isShownInMenuBar: true, sortOrder: 1),
    DdayItem(name: "숨김", date: first, isShownInMenuBar: false, sortOrder: 0)
]

assert(
    DdayModel.menuBarLabel(for: items, today: today, calendar: calendar) == "시험 D-3  |  생일 D-10"
)

let model = DdayModel()
model.items = [
    DdayItem(name: "시험", date: first, isShownInMenuBar: true, sortOrder: 0),
    DdayItem(name: "생일", date: second, isShownInMenuBar: true, sortOrder: 1)
]
model.move(fromOffsets: IndexSet(integer: 1), toOffset: 0)

assert(
    DdayModel.menuBarLabel(for: model.items, today: today, calendar: calendar) == "생일 D-10  |  시험 D-3"
)
