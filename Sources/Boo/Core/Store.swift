import Foundation
import Combine

/// Lightweight persistence via UserDefaults. Shared across the app.
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

    private enum Keys {
        static let notif = "boo.notifications"
        static let paused = "boo.paused"
        static let learned = "boo.learned"
    }

    private init() {
        notificationsEnabled = (d.object(forKey: Keys.notif) as? Bool) ?? true
        paused = d.bool(forKey: Keys.paused)
        learned = (d.dictionary(forKey: Keys.learned) as? [String: String]) ?? [:]
    }
}
