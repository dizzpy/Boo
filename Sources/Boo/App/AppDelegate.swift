import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var status: StatusItemController!
    private let sorter = Sorter()
    private var watcher: DownloadsWatcher?

    func applicationDidFinishLaunching(_ notification: Notification) {
        status = StatusItemController(sorter: sorter)

        // Ghost + toast reactions, always delivered on the main thread.
        sorter.onSorted = { [weak self] folder in
            DispatchQueue.main.async {
                self?.status.playEating()
                if Store.shared.notificationsEnabled {
                    ToastManager.shared.show("Nom! Saved to \(folder)")
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
