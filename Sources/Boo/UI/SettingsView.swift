import SwiftUI

struct SettingsView: View {
    @ObservedObject private var store = Store.shared
    var onClose: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            header
            Form {
                controlsSection
                learnedSection
                categoriesSection
            }
            .formStyle(.grouped)
        }
        .frame(width: 420, height: 520)
    }

    private var header: some View {
        HStack(spacing: 12) {
            GhostAvatar(avatar: .happy, height: 34)
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("Boo").font(.title3.bold())
                    Text(AppInfo.displayVersion)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Text("Eats your downloads, neatly.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(store.paused ? "💤 napping" : "👀 watching")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.bar)
    }

    private var controlsSection: some View {
        Section("Controls") {
            Toggle("Watch Downloads", isOn: Binding(
                get: { !store.paused },
                set: { store.paused = !$0 }
            ))
            Toggle("Show a toast when a file is sorted", isOn: $store.notificationsEnabled)
        }
    }

    private var learnedSection: some View {
        Section("Remembered types") {
            if store.learned.isEmpty && store.ignoredExtensions.isEmpty {
                HStack(spacing: 8) {
                    GhostAvatar(avatar: .smile, height: 22)
                    Text("Nothing learned yet. Boo remembers whenever you file a new type.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(store.learned.sorted(by: { $0.key < $1.key }), id: \.key) { ext, folder in
                    HStack {
                        Text(".\(ext)")
                            .monospaced()
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(folder)
                        Spacer()
                        Button {
                            store.learned.removeValue(forKey: ext)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Forget this rule")
                    }
                }
                ForEach(store.ignoredExtensions.sorted(), id: \.self) { ext in
                    HStack {
                        Text(".\(ext)")
                            .monospaced()
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("Stays in Downloads")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button {
                            store.ignoredExtensions.remove(ext)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                        .help("Forget this rule")
                    }
                }
            }
        }
    }

    private var categoriesSection: some View {
        Section("Built-in folders") {
            Text(Categories.names.joined(separator: " · "))
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
