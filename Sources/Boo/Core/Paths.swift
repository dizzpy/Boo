import Foundation

enum Paths {
    /// ~/Downloads (via the sandbox container symlink when sandboxed).
    static let downloads: URL = {
        FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads", isDirectory: true)
    }()
}
