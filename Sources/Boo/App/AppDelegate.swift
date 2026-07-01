import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var status: StatusItemController!
    private let sorter = Sorter()
    private var watcher: DownloadsWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = StatusItemController(sorter: sorter)

        // Ghost + toast reactions, one toast per scan, on the main thread.
        sorter.onSortedBatch = { [weak self] counts in
            DispatchQueue.main.async {
                self?.status.playEating()
                guard Store.shared.notificationsEnabled else { return }
                let total = counts.values.reduce(0, +)
                if total == 1, let folder = counts.keys.first {
                    ToastManager.shared.show("Nom! Saved to \(folder)")
                } else {
                    ToastManager.shared.show("Nom! Sorted \(total) files")
                }
            }
        }
        sorter.onConfused = { [weak self] in
            DispatchQueue.main.async { self?.status.playConfused() }
        }

        // Watch ~/Downloads for changes.
        watcher = DownloadsWatcher(url: Paths.downloads) { [weak self] in
            self?.sorter.scan()
        }
        if watcher == nil {
            ToastManager.shared.show("Couldn't watch Downloads")
        }

        // Sort whatever is already sitting there.
        sorter.scan()
    }
}
