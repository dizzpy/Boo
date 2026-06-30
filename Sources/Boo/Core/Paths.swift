import Foundation

enum Paths {
    static var home: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }
    static var downloads: URL {
        home.appendingPathComponent("Downloads", isDirectory: true)
    }
}
