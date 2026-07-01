import Foundation
import Combine

/// App settings and learned rules, persisted in UserDefaults. Main-thread only;
/// background workers snapshot values via `DispatchQueue.main.sync`.
final class Store: ObservableObject {
    static let shared = Store()
    private let d = UserDefaults.standard

    @Published var notificationsEnabled: Bool {
        didSet { d.set(notificationsEnabled, forKey: Keys.notif) }
    }
    @Published var paused: Bool {
        didSet { d.set(paused, forKey: Keys.paused) }
    }
    /// Learned mappings: extension -> folder name.
    @Published var learned: [String: String] {
        didSet { d.set(learned, forKey: Keys.learned) }
    }
    /// Extensions the user chose to always leave in Downloads.
    @Published var ignoredExtensions: Set<String> {
        didSet { d.set(Array(ignoredExtensions).sorted(), forKey: Keys.ignored) }
    }

    private enum Keys {
        static let notif = "boo.notifications"
        static let paused = "boo.paused"
        static let learned = "boo.learned"
        static let ignored = "boo.ignored"
    }

    private init() {
        notificationsEnabled = (d.object(forKey: Keys.notif) as? Bool) ?? true
        paused = d.bool(forKey: Keys.paused)
        // Drop invalid folder names so a stored rule can't point outside Downloads.
        let storedLearned = (d.dictionary(forKey: Keys.learned) as? [String: String]) ?? [:]
        learned = storedLearned.filter { !$0.key.isEmpty && FolderName.isValid($0.value) }
        ignoredExtensions = Set((d.stringArray(forKey: Keys.ignored) ?? []).filter { !$0.isEmpty })
    }
}
