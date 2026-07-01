import AppKit
import SwiftUI

struct UnknownGroup {
    let ext: String
    let exampleName: String
    let count: Int
}

struct UnknownGroupDecision {
    enum Kind { case move, leave }
    let ext: String
    let kind: Kind
    /// Valid when `kind == .move`.
    let folder: String
    let remember: Bool
}

/// Batches every unresolved extension from one scan into a single dialog,
/// instead of popping one alert per file.
enum UnknownFilePrompt {

    /// Must be called on the main thread.
    static func run(groups: [UnknownGroup], folders: [String]) -> [UnknownGroupDecision] {
        var decisions: [UnknownGroupDecision] = groups.map {
            UnknownGroupDecision(ext: $0.ext, kind: .leave, folder: "", remember: false)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 100),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.level = .modalPanel
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        let rows = groups.map { UnknownRowState(group: $0, folders: folders) }
        let view = UnknownBatchPromptView(rows: rows, folders: folders) { result in
            decisions = result
            NSApp.stopModal()
        }

        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        window.setContentSize(host.fittingSize)
        window.contentView = host
        window.center()

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        NSApp.runModal(for: window)
        window.orderOut(nil)
        return decisions
    }
}

private final class UnknownRowState: ObservableObject, Identifiable {
    let id = UUID()
    let ext: String
    let exampleName: String
    let count: Int
    @Published var selection: String
    @Published var newFolderName = ""
    @Published var remember = true

    init(group: UnknownGroup, folders: [String]) {
        self.ext = group.ext
        self.exampleName = group.exampleName
        self.count = group.count
        self.selection = folders.first ?? UnknownBatchPromptView.newFolderTag
    }
}

private struct UnknownBatchPromptView: View {
    fileprivate static let newFolderTag = "\u{1}__new_folder__"
    fileprivate static let leaveTag = "\u{1}__leave__"

    let rows: [UnknownRowState]
    let folders: [String]
    let onDone: ([UnknownGroupDecision]) -> Void

    private var isValid: Bool {
        rows.allSatisfy { row in
            guard row.selection == Self.newFolderTag else { return true }
            return !row.newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            rowList

            HStack {
                Button("Leave All in Downloads") {
                    onDone(rows.map {
                        UnknownGroupDecision(ext: $0.ext, kind: .leave, folder: "", remember: false)
                    })
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Done", action: done)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
        }
        .padding(20)
        .frame(width: 420)
    }

    @ViewBuilder
    private var rowList: some View {
        let stack = VStack(alignment: .leading, spacing: 12) {
            ForEach(rows) { row in
                UnknownRowView(row: row, folders: folders)
                if row.id != rows.last?.id {
                    Divider()
                }
            }
        }
        if rows.count > 6 {
            ScrollView { stack }.frame(maxHeight: 6 * 60)
        } else {
            stack
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            GhostAvatar(avatar: .surprise, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text(rows.count == 1
                     ? "Boo found a new file type."
                     : "Boo found \(rows.count) new file types.")
                    .font(.headline)
                Text("Where should they go?")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func done() {
        let decisions = rows.map { row -> UnknownGroupDecision in
            if row.selection == Self.leaveTag {
                return UnknownGroupDecision(ext: row.ext, kind: .leave, folder: "", remember: false)
            }
            let folder = row.selection == Self.newFolderTag
                ? row.newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
                : row.selection
            return UnknownGroupDecision(
                ext: row.ext,
                kind: .move,
                folder: folder,
                remember: row.ext.isEmpty ? false : row.remember
            )
        }
        onDone(decisions)
    }
}

private struct UnknownRowView: View {
    @ObservedObject var row: UnknownRowState
    let folders: [String]
    @FocusState private var nameFocused: Bool

    private var isNewFolder: Bool { row.selection == UnknownBatchPromptView.newFolderTag }
    private var isLeave: Bool { row.selection == UnknownBatchPromptView.leaveTag }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(row.ext.isEmpty ? "no ext" : ".\(row.ext)")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .frame(minWidth: 50, alignment: .leading)
                Text(row.count > 1 ? "\(row.exampleName) +\(row.count - 1) more" : row.exampleName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            HStack(spacing: 8) {
                Picker("", selection: $row.selection) {
                    ForEach(folders, id: \.self) { Text($0).tag($0) }
                    Label("New folder…", systemImage: "folder.badge.plus").tag(UnknownBatchPromptView.newFolderTag)
                    Text("Leave in Downloads").tag(UnknownBatchPromptView.leaveTag)
                }
                .labelsHidden()
                .frame(width: 160)
                .onChange(of: isNewFolder) { newValue in
                    if newValue { nameFocused = true }
                }

                if isNewFolder {
                    TextField("Folder name", text: $row.newFolderName)
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFocused)
                }

                if !isLeave && !row.ext.isEmpty {
                    Toggle("Remember", isOn: $row.remember)
                        .toggleStyle(.checkbox)
                        .font(.system(size: 11))
                }

                Spacer(minLength: 0)
            }
        }
    }
}
