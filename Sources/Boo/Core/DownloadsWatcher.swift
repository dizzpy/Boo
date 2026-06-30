import Foundation

/// Watches a directory and calls `onChange` (debounced) when its contents change.
final class DownloadsWatcher {
    private let fd: Int32
    private let source: DispatchSourceFileSystemObject
    private let onChange: () -> Void
    private var debounce: DispatchWorkItem?

    init?(url: URL, onChange: @escaping () -> Void) {
        self.onChange = onChange
        fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return nil }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .attrib, .rename, .delete],
            queue: DispatchQueue.global(qos: .utility)
        )
        source.setEventHandler { [weak self] in self?.fire() }
        let capturedFD = fd
        source.setCancelHandler { close(capturedFD) }
        source.resume()
    }

    private func fire() {
        debounce?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.onChange() }
        debounce = work
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 0.8, execute: work)
    }

    deinit {
        source.cancel()
    }
}
