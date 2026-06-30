import AppKit

// Builds a macOS .iconset folder from a single square PNG, applying rounded
// (squircle-ish) corners so the app icon looks native in Finder / the installer.
//
// usage: swift make-icon.swift <input.png> <output.iconset-dir>

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <in.png> <out.iconset>\n".utf8))
    exit(2)
}
let inputPath = args[1]
let outDir = args[2]

guard let src = NSImage(contentsOfFile: inputPath) else {
    FileHandle.standardError.write(Data("make-icon: cannot load \(inputPath)\n".utf8))
    exit(1)
}

try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// Apple's icon grid corner radius is ~22.37% of the tile size.
let cornerFraction: CGFloat = 0.2237

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),   ("icon_16x16@2x", 32),
    ("icon_32x32", 32),   ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, px) in sizes {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { continue }
    rep.size = NSSize(width: px, height: px)

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let rect = NSRect(x: 0, y: 0, width: px, height: px)
    let radius = CGFloat(px) * cornerFraction
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).addClip()
    src.draw(in: rect, from: .zero, operation: .copy, fraction: 1.0)
    NSGraphicsContext.restoreGraphicsState()

    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png"))
    }
}
