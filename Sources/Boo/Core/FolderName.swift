import Foundation

/// Validates folder names so every move stays inside Downloads.
enum FolderName {
    static let maxLength = 255

    static func isValid(_ name: String) -> Bool {
        if name.isEmpty || name.count > maxLength { return false }
        if name != name.trimmingCharacters(in: .whitespacesAndNewlines) { return false }
        if name == "." || name == ".." { return false }
        if name.hasPrefix(".") { return false }
        if name.contains("/") || name.contains(":") { return false }
        if name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) { return false }
        return true
    }
}
