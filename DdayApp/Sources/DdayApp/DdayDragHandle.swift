import AppKit
import SwiftUI

struct DdayDragHandle: NSViewRepresentable {
    static let pasteboardType = NSPasteboard.PasteboardType("com.user.ddaymenubar.item")

    let itemID: UUID
    let dragStarted: () -> Void
    let dragEnded: () -> Void

    func makeNSView(context: Context) -> HandleView {
        let view = HandleView(labelWithString: "☰")
        view.font = .systemFont(ofSize: 14, weight: .semibold)
        view.textColor = .secondaryLabelColor
        view.alignment = .center
        view.toolTip = "드래그해서 순서 변경"
        view.setAccessibilityLabel(view.toolTip)
        return view
    }

    func updateNSView(_ view: HandleView, context: Context) {
        view.itemID = itemID
        view.dragStarted = dragStarted
        view.dragEnded = dragEnded
    }

    final class HandleView: NSTextField, NSDraggingSource {
        var itemID: UUID?
        var dragStarted: (() -> Void)?
        var dragEnded: (() -> Void)?
        private var mouseDownPoint: NSPoint?

        override func mouseDown(with event: NSEvent) {
            mouseDownPoint = event.locationInWindow
        }

        override func mouseDragged(with event: NSEvent) {
            guard let origin = mouseDownPoint, let itemID,
                  hypot(event.locationInWindow.x - origin.x, event.locationInWindow.y - origin.y) >= 3
            else { return }
            mouseDownPoint = nil

            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(itemID.uuidString, forType: DdayDragHandle.pasteboardType)
            let item = NSDraggingItem(pasteboardWriter: pasteboardItem)
            let size = NSSize(width: 1, height: 1)
            item.setDraggingFrame(
                NSRect(origin: convert(event.locationInWindow, from: nil), size: size),
                contents: NSImage(size: size, flipped: false) { _ in true }
            )
            dragStarted?()
            let session = beginDraggingSession(with: [item], event: event, source: self)
            session.animatesToStartingPositionsOnCancelOrFail = false
        }

        func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
            context == .withinApplication ? .move : []
        }

        func ignoreModifierKeys(for session: NSDraggingSession) -> Bool { true }

        func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
            // AppKit calls this for successful drops, Escape, and drops outside the window.
            mouseDownPoint = nil
            dragEnded?()
        }
    }
}
