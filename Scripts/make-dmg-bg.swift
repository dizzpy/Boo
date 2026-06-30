import AppKit

// Draws the DMG window background: cream (#F6EDDF) with a centered arrow
// pointing from the Boo icon toward the Applications folder.
//
// usage: swift make-dmg-bg.swift <output.png>
//
// Window is 660x420; the icon row sits 195pt from the top, Boo at x=175 and
// Applications at x=485, so the arrow is centered at x=330. Keep these in sync
// with the AppleScript layout in make-app.sh.

let W: CGFloat = 660, H: CGFloat = 420

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write(Data("usage: make-dmg-bg.swift <out.png>\n".utf8))
    exit(2)
}
let out = CommandLine.arguments[1]

guard let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: Int(W), pixelsHigh: Int(H),
    bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
) else { exit(1) }

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

// Background fill.
NSColor(srgbRed: 0xF6 / 255.0, green: 0xED / 255.0, blue: 0xDF / 255.0, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: W, height: H)).fill()

// Arrow (NSGraphics origin is bottom-left; icon row is 195pt from the top).
let cy = H - 195
let tail: CGFloat = 290, tip: CGFloat = 370, head: CGFloat = 18
NSColor(srgbRed: 0x2A / 255.0, green: 0x25 / 255.0, blue: 0x20 / 255.0, alpha: 1).setStroke()
let arrow = NSBezierPath()
arrow.lineWidth = 8
arrow.lineCapStyle = .round
arrow.lineJoinStyle = .round
arrow.move(to: NSPoint(x: tail, y: cy))
arrow.line(to: NSPoint(x: tip, y: cy))
arrow.move(to: NSPoint(x: tip - head, y: cy + head))
arrow.line(to: NSPoint(x: tip, y: cy))
arrow.line(to: NSPoint(x: tip - head, y: cy - head))
arrow.stroke()

NSGraphicsContext.restoreGraphicsState()

guard let data = rep.representation(using: .png, properties: [:]) else { exit(1) }
do { try data.write(to: URL(fileURLWithPath: out)) } catch { exit(1) }
