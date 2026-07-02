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
        sorter.onAccess = { [weak self] ok in
            DispatchQueue.main.async { self?.status.setDownloadsAccess(ok: ok) }
        }

        // Sort whatever is already sitting there. Runs on a background queue,
        sorter.scan()

        // Watch ~/Downloads for changes. The open() inside can block while
        // macOS asks for Downloads permission — keep it off the main thread.
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let watcher = DownloadsWatcher(url: Paths.downloads) { self?.sorter.scan() }
            DispatchQueue.main.async {
                self?.watcher = watcher
                if watcher == nil {
                    ToastManager.shared.show("Couldn't watch Downloads")
                }
            }
        }
    }
}
