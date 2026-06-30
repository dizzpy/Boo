import AppKit
import SwiftUI

enum GhostState {
    case idle, eating, confused, sleeping
}

/// Loads the ghost avatar art (bundled SVGs) and scales it for a given spot.
/// Images stay vector-backed so they render crisply at any size / Retina scale.
enum GhostRenderer {

    /// Avatar art bundled under Resources/Avatars. Raw values are the file names.
    enum Avatar: String {
        case `default`, eating, confused, sleep
        case happy, smile, sad, moreSad = "more-sad", surprise
    }

    private static var cache: [String: NSImage] = [:]

    /// The menu-bar avatar for a given runtime state.
    static func image(for state: GhostState, height: CGFloat) -> NSImage {
        switch state {
        case .idle:     return image(.default, height: height)
        case .eating:   return image(.eating, height: height)
        case .confused: return image(.confused, height: height)
        case .sleeping: return image(.sleep, height: height)
        }
    }

    /// A specific avatar scaled to `height` (width follows the art's aspect ratio).
    static func image(_ avatar: Avatar, height: CGFloat) -> NSImage {
        let key = "\(avatar.rawValue)@\(height)"
        if let cached = cache[key] { return cached }
        let img = load(avatar, height: height)
        cache[key] = img
        return img
    }

    private static func load(_ avatar: Avatar, height: CGFloat) -> NSImage {
        guard let url = Bundle.module.url(
                forResource: avatar.rawValue, withExtension: "svg", subdirectory: "Avatars"),
              let svg = NSImage(contentsOf: url), svg.size.height > 0
        else {
            // Fallback: empty image so the app never crashes on a missing asset.
            return NSImage(size: NSSize(width: height, height: height))
        }
        let scale = height / svg.size.height
        svg.size = NSSize(width: (svg.size.width * scale).rounded(), height: height)
        svg.isTemplate = false   // colored art, not a tinted template
        return svg
    }
}

/// A ghost avatar for use in SwiftUI views (settings, toast, prompts).
struct GhostAvatar: View {
    let avatar: GhostRenderer.Avatar
    var height: CGFloat = 34

    var body: some View {
        Image(nsImage: GhostRenderer.image(avatar, height: height))
    }
}
