import AppKit
import SwiftUI

/// What the user decided in the unknown-file popup.
struct UnknownDecision {
    enum Kind { case move, leave }
    let kind: Kind
    /// Destination folder name, valid when `kind == .move`.
    let folder: String
    /// Whether to remember this extension -> folder mapping.
    let remember: Bool
}

/// A single native popup that handles the whole "where should this go?" flow:
/// pick a folder (or name a new one inline) and choose whether to remember it.
enum UnknownFilePrompt {

    /// Presents the popup and blocks until the user decides.
    /// Must be called on the main thread.
    static func run(fileName: String, ext: String, folders: [String]) -> UnknownDecision {
        var decision = UnknownDecision(kind: .leave, folder: "", remember: false)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 100),
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

        let view = UnknownFilePromptView(fileName: fileName, ext: ext, folders: folders) { result in
            decision = result
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
        return decision
    }
}

private struct UnknownFilePromptView: View {
    let fileName: String
    let ext: String
    let folders: [String]
    let onDecide: (UnknownDecision) -> Void

    /// Sentinel selection that means "make a new folder".
    private static let newFolderTag = "\u{1}__new_folder__"

    @State private var selection: String
    @State private var newFolderName = ""
    @State private var remember = false
    @FocusState private var nameFocused: Bool

    init(fileName: String, ext: String, folders: [String], onDecide: @escaping (UnknownDecision) -> Void) {
        self.fileName = fileName
        self.ext = ext
        self.folders = folders
        self.onDecide = onDecide
        _selection = State(initialValue: folders.first ?? Self.newFolderTag)
    }

    private var isNewFolder: Bool { selection == Self.newFolderTag }
    private var trimmedName: String {
        newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var resolvedFolder: String { isNewFolder ? trimmedName : selection }
    private var canMove: Bool { !resolvedFolder.isEmpty }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(alignment: .leading, spacing: 10) {
                Picker("Move to", selection: $selection) {
                    ForEach(folders, id: \.self) { Text($0).tag($0) }
                    Label("New folder…", systemImage: "folder.badge.plus")
                        .tag(Self.newFolderTag)
                }

                if isNewFolder {
                    TextField("Folder name", text: $newFolderName)
                        .textFieldStyle(.roundedBorder)
                        .focused($nameFocused)
                        .onSubmit(move)
                }

                if !ext.isEmpty {
                    Toggle("Always send .\(ext) files here", isOn: $remember)
                        .toggleStyle(.checkbox)
                }
            }

            HStack {
                Button("Leave in Downloads") {
                    onDecide(UnknownDecision(kind: .leave, folder: "", remember: false))
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Move", action: move)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canMove)
            }
        }
        .padding(20)
        .frame(width: 340)
        .onChange(of: isNewFolder) { newValue in
            if newValue { nameFocused = true }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            GhostAvatar(avatar: .surprise, height: 40)
            VStack(alignment: .leading, spacing: 3) {
                Text("Where should this go?")
                    .font(.headline)
                Text(fileName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(ext.isEmpty
                     ? "Boo hasn't seen a file like this before."
                     : "Boo hasn't seen a .\(ext) file before.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func move() {
        guard canMove else { return }
        onDecide(UnknownDecision(
            kind: .move,
            folder: resolvedFolder,
            remember: ext.isEmpty ? false : remember
        ))
    }
}
