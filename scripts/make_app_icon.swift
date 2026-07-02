import AppKit
import Foundation

let output = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "Resources/AppIcon.icns")
let fileManager = FileManager.default

try fileManager.createDirectory(at: output.deletingLastPathComponent(), withIntermediateDirectories: true)

let specs: [(type: String, pixels: CGFloat)] = [
    ("icp4", 16),
    ("icp5", 32),
    ("icp6", 64),
    ("ic07", 128),
    ("ic08", 256),
    ("ic09", 512),
    ("ic10", 1024)
]

var elements = Data()

for spec in specs {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(spec.pixels),
        pixelsHigh: Int(spec.pixels),
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        fatalError("Failed to create bitmap for \(spec.type)")
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: spec.pixels, height: spec.pixels).fill()

    let font = NSFont.systemFont(ofSize: spec.pixels * 0.78)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .paragraphStyle: {
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            return style
        }()
    ]
    let text = "📅" as NSString
    let textSize = text.size(withAttributes: attributes)
    let rect = NSRect(
        x: 0,
        y: (spec.pixels - textSize.height) / 2,
        width: spec.pixels,
        height: textSize.height
    )
    text.draw(in: rect, withAttributes: attributes)
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render \(spec.type)")
    }

    elements.append(Data(spec.type.utf8))
    elements.appendUInt32(UInt32(png.count + 8))
    elements.append(png)
}

try? fileManager.removeItem(at: output)
var icns = Data("icns".utf8)
icns.appendUInt32(UInt32(elements.count + 8))
icns.append(elements)
try icns.write(to: output)

extension Data {
    mutating func appendUInt32(_ value: UInt32) {
        var bigEndianValue = value.bigEndian
        append(Data(bytes: &bigEndianValue, count: MemoryLayout<UInt32>.size))
    }
}
