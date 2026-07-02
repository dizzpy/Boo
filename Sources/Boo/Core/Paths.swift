import Foundation

enum Paths {
    /// The real ~/Downloads. Symlinks are resolved because the sandbox hands
    /// us a container symlink, and sandboxed directory enumeration refuses to
    /// traverse symlinks (fails with ENOTDIR).
    static let downloads: URL = {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads", isDirectory: true)
        return url.resolvingSymlinksInPath()
    }()
}
