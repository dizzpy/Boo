import AppKit

/// Scans Downloads and sorts files: known types move silently, unknown types prompt.
/// All work runs on `queue`; never block the main thread on it.
final class Sorter {
    /// Called off-main once per scan: folder -> number of files moved into it.
    var onSortedBatch: (([String: Int]) -> Void)?
    /// Called when an unknown file triggered a prompt.
    var onConfused: (() -> Void)?
    /// Called off-main after each scan with whether Downloads could be read.
    var onAccess: ((Bool) -> Void)?

    private let fm = FileManager.default
    private let queue = DispatchQueue(label: "co.dizzpy.boo.sort")
    /// Files the user chose to leave in Downloads, keyed by name + creation date.
    private var leftAlone = Set<String>()
    /// True while a delayed rescan is queued.
    private var rescanPending = false

    private let partialSuffixes = [
        ".crdownload", ".download", ".part", ".partial", ".tmp",
        ".opdownload", ".!ut", ".aria2", ".filepart",
    ]
    /// Files must sit untouched this long before moving; catches downloads
    /// that preallocate their full size and would pass a size check.
    private let settleInterval: TimeInterval = 5

    func scan() {
        queue.async { [weak self] in self?.performScan() }
    }

    // MARK: - Scan

    private func performScan() {
        // Store is main-thread only; snapshot what this scan needs.
        let (paused, learned, ignored) = DispatchQueue.main.sync {
            (Store.shared.paused, Store.shared.learned, Store.shared.ignoredExtensions)
        }
        guard !paused else { return }

        let dl = Paths.downloads
        let keys: [URLResourceKey] = [
            .isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey,
            .contentModificationDateKey, .creationDateKey,
        ]
        // This read may block while macOS shows the Downloads permission
        // prompt on first run — we're on the background queue, so that's fine.
        guard let items = try? fm.contentsOfDirectory(
            at: dl, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]
        ) else {
            onAccess?(false)
            return
        }
        onAccess?(true)

        leftAlone.formIntersection(items.map { fileKey($0) })

        var movedCounts: [String: Int] = [:]
        var sawUnsettledFile = false
        // Grouped by extension so the prompt shows one row per type.
        var unresolved: [String: [URL]] = [:]

        for url in items {
            let values = try? url.resourceValues(forKeys: Set(keys))
            if values?.isDirectory == true { continue }
            if values?.isSymbolicLink == true { continue }

            let lower = url.lastPathComponent.lowercased()
            if partialSuffixes.contains(where: { lower.hasSuffix($0) }) { continue }
            if leftAlone.contains(fileKey(url)) { continue }

            // Written to recently: may still be downloading.
            if let modified = values?.contentModificationDate,
               Date().timeIntervalSince(modified) < settleInterval {
                sawUnsettledFile = true
                continue
            }
            if !sizeStable(url) { sawUnsettledFile = true; continue }
            if !fm.fileExists(atPath: url.path) { continue } // vanished mid-loop

            let ext = url.pathExtension.lowercased()
            if !ext.isEmpty, ignored.contains(ext) { continue }

            if let folder = Categories.builtin[ext] {
                if move(url, toFolder: folder) { movedCounts[folder, default: 0] += 1 }
                continue
            }
            if !ext.isEmpty, let folder = learned[ext] {
                if move(url, toFolder: folder) { movedCounts[folder, default: 0] += 1 }
                continue
            }
            unresolved[ext, default: []].append(url)
        }

        if !movedCounts.isEmpty {
            onSortedBatch?(movedCounts)
        }
        if !unresolved.isEmpty {
            promptUnknownBatch(unresolved)
        }
        if sawUnsettledFile {
            scheduleRescan()
        }
    }

    /// Identifies a file across scans: same name and creation date.
    private func fileKey(_ url: URL) -> String {
        let created = (try? url.resourceValues(forKeys: [.creationDateKey]).creationDate)
            .map { String($0.timeIntervalSince1970) } ?? "0"
        return url.lastPathComponent + "|" + created
    }

    /// Settling files emit no further FS events, so come back once they finish.
    private func scheduleRescan() {
        guard !rescanPending else { return }
        rescanPending = true
        queue.asyncAfter(deadline: .now() + settleInterval + 0.5) { [weak self] in
            self?.rescanPending = false
            self?.performScan()
        }
    }

    /// True if the size holds steady for a moment, i.e. writing has finished.
    private func sizeStable(_ url: URL) -> Bool {
        let s1 = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -1
        Thread.sleep(forTimeInterval: 0.4)
        let s2 = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? -2
        return s1 == s2
    }

    // MARK: - Move

    @discardableResult
    private func move(_ url: URL, toFolder folder: String) -> Bool {
        // Never move outside Downloads, even if a bad name slips into the rules.
        guard FolderName.isValid(folder) else { return false }
        let base = Paths.downloads.standardizedFileURL
        let destDir = base.appendingPathComponent(folder, isDirectory: true).standardizedFileURL
        guard destDir.path.hasPrefix(base.path + "/") else { return false }

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

    /// Prompts once per unresolved extension, then applies each decision to its files.
    private func promptUnknownBatch(_ unresolved: [String: [URL]]) {
        onConfused?()
        let folders = existingFolders()
        let groups = unresolved
            .map { ext, urls in UnknownGroup(ext: ext, exampleName: urls[0].lastPathComponent, count: urls.count) }
            .sorted { $0.ext < $1.ext }

        var movedCounts: [String: Int] = [:]

        // UI runs on main; we are on `queue`, so sync is safe.
        DispatchQueue.main.sync {
            let decisions = UnknownFilePrompt.run(groups: groups, folders: folders)
            for decision in decisions {
                guard let urls = unresolved[decision.ext] else { continue }
                switch decision.kind {
                case .leave:
                    if decision.remember, !decision.ext.isEmpty {
                        Store.shared.ignoredExtensions.insert(decision.ext)
                    } else {
                        for url in urls { leftAlone.insert(fileKey(url)) }
                    }
                case .move:
                    var movedAny = false
                    for url in urls {
                        if move(url, toFolder: decision.folder) {
                            movedCounts[decision.folder, default: 0] += 1
                            movedAny = true
                        } else {
                            leftAlone.insert(fileKey(url)) // don't re-prompt on every rescan
                        }
                    }
                    if decision.remember, movedAny, !decision.ext.isEmpty {
                        Store.shared.learned[decision.ext] = decision.folder
                    }
                }
            }
        }

        if !movedCounts.isEmpty {
            onSortedBatch?(movedCounts)
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
