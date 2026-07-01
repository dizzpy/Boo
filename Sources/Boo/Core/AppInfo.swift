import Foundation

enum AppInfo {
    /// Marketing version from Info.plist; nil under `swift run`.
    static let version: String? =
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

    /// "v1.2.0" when packaged, "dev" from the toolchain.
    static let displayVersion: String = version.map { "v\($0)" } ?? "dev"
}
