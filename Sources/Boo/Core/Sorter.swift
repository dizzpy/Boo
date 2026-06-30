import AppKit

/// Watches a queue, scans Downloads, and sorts files.
/// Known types move silently. Unknown types prompt the user.
final class Sorter {
    /// Called (off main) when a file was auto-sorted into `folder`.
    var onSorted: ((String) -> Void)?
    /// Called when an unknown file triggered a prompt.
    var onConfused: (() -> Void)?

    private let fm = FileManager.default
    private let store = Store.shared
    private let queue = DispatchQueue(label: "co.dizzpy.boo.sort")
    /// Files the user chose to leave in Downloads (basenames).
    private var leftAlone = Set<String>()

    private let partialSuffixes = [".crdownload", ".download", ".part", ".partial", ".tmp"]

    func scan() {
        queue.async { [weak self] in self?.performScan() }
    }

    // MARK: - Scan

    private func performScan() {
        guard !store.paused else { return }
        let dl = Paths.downloads
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey]
        guard let items = try? fm.contentsOfDirectory(
            at: dl, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
        ) else { return }

        // Prune leftAlone entries whose files are gone.
        leftAlone = leftAlone.filter { fm.fileExists(atPath: dl.appendingPathComponent($0).path) }

        for url in items {
            let name = url.lastPathComponent

            let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDir { continue }

            let lower = name.lowercased()
            if partialSuffixes.contains(where: { lower.hasSuffix($0) }) { continue }
            if leftAlone.contains(name) { continue }
            if !sizeStable(url) { continue }
            if !fm.fileExists(atPath: url.path) { continue } // vanished mid-loop

            let ext = url.pathExtension.lowercased()

            if let folder = Categories.builtin[ext] {
                moveAndReport(url, to: folder)
                continue
            }
            if !ext.isEmpty, let folder = store.learned[ext] {
                moveAndReport(url, to: folder)
                continue
            }
            promptUnknown(url: url, ext: ext)
        }
    }

    /// Returns true if the file size is unchanged across a short window,
    /// i.e. the download has finished writing.
    private func sizeStable(_ url: URL) -> Bool {
        let s1 = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
        Thread.sleep(forTimeInterval: 0.4)
        let s2 = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -2
        return s1 == s2
    }

    // MARK: - Move

    private func moveAndReport(_ url: URL, to folder: String) {
        if move(url, toFolder: folder) {
            onSorted?(folder)
        }
    }

    @discardableResult
    private func move(_ url: URL, toFolder folder: String) -> Bool {
        let destDir = Paths.downloads.appendingPathComponent(folder, isDirectory: true)
        do {
            try fm.createDirectory(at: destDir, withIntermediateDirectories: true)
        } catch {
            return false
        }
        let dest = uniqueDestination(for: url.lastPathComponent, in: destDir)
        do {
            try fm.moveItem(at: url, to: dest)
            return true
        } catch {
            return false
        }
    }

    /// Appends " (1)", " (2)"... before the extension if the name is taken.
    private func uniqueDestination(for name: String, in dir: URL) -> URL {
        var candidate = dir.appendingPathComponent(name)
        guard fm.fileExists(atPath: candidate.path) else { return candidate }

        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        var n = 1
        repeat {
            let newName = ext.isEmpty ? "\(base) (\(n))" : "\(base) (\(n)).\(ext)"
            candidate = dir.appendingPathComponent(newName)
            n += 1
        } while fm.fileExists(atPath: candidate.path)
        return candidate
    }

    // MARK: - Unknown type prompt

    private func promptUnknown(url: URL, ext: String) {
        onConfused?()
        let name = url.lastPathComponent
        let folders = existingFolders()

        // UI must run on the main thread. We are on `queue`, so sync is safe.
        DispatchQueue.main.sync {
            let decision = UnknownFilePrompt.run(fileName: name, ext: ext, folders: folders)
            switch decision.kind {
            case .leave:
                leftAlone.insert(name)
            case .move:
                if move(url, toFolder: decision.folder) {
                    if decision.remember, !ext.isEmpty {
                        store.learned[ext] = decision.folder
                    }
                    onSorted?(decision.folder)
                } else {
                    // Move failed; don't re-prompt on every rescan.
                    leftAlone.insert(name)
                }
            }
        }
    }

    private func existingFolders() -> [String] {
        guard let items = try? fm.contentsOfDirectory(
            at: Paths.downloads, includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return items
            .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
            .map { $0.lastPathComponent }
            .sorted()
    }
}
