import AppKit
import SwiftUI

final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let sorter: Sorter
    private let store = Store.shared

    /// Height of the menu-bar avatar, in points.
    private static let iconHeight: CGFloat = 15

    private var reactionTimer: Timer?
    private var temporaryState: GhostState = .idle
    private var temporaryUntil: Date?
    private var shownState: GhostState?
    private var downloadsAccessOK = true

    private var settingsWindow: NSWindow?
    private let statusMenuItem = NSMenuItem(title: "Boo is watching", action: nil, keyEquivalent: "")
    private let pauseMenuItem = NSMenuItem(title: "Pause", action: nil, keyEquivalent: "")

    init(sorter: Sorter) {
        self.sorter = sorter
        super.init()

        item.button?.imagePosition = .imageOnly
        buildMenu()
        refresh()
        refreshStatusText()
    }

    // MARK: - Avatar

    /// Picks the avatar that should be showing right now and updates it if needed.
    private func refresh() {
        let desired: GhostState
        if let until = temporaryUntil, Date() < until {
            desired = temporaryState
        } else {
            temporaryUntil = nil
            desired = store.paused ? .sleeping : .idle
        }
        guard desired != shownState else { return }
        shownState = desired
        item.button?.image = GhostRenderer.image(for: desired, height: Self.iconHeight)
    }

    func playEating() { setTemporary(.eating, for: 0.9) }
    func playConfused() { setTemporary(.confused, for: 1.4) }

    private func setTemporary(_ state: GhostState, for duration: TimeInterval) {
        temporaryState = state
        temporaryUntil = Date().addingTimeInterval(duration)
        refresh()

        // One-shot flip back to idle; .common so it fires while menus are open.
        reactionTimer?.invalidate()
        let t = Timer(timeInterval: duration + 0.05, repeats: false) { [weak self] _ in
            self?.refresh()
        }
        reactionTimer = t
        RunLoop.main.add(t, forMode: .common)
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        pauseMenuItem.target = self
        pauseMenuItem.action = #selector(togglePause)
        menu.addItem(pauseMenuItem)

        let sortNow = NSMenuItem(title: "Sort Now", action: #selector(sortNow), keyEquivalent: "s")
        sortNow.target = self
        menu.addItem(sortNow)

        let openDL = NSMenuItem(title: "Open Downloads", action: #selector(openDownloads), keyEquivalent: "")
        openDL.target = self
        menu.addItem(openDL)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let updates = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
        updates.target = self
        menu.addItem(updates)

        let quit = NSMenuItem(title: "Quit Boo", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
    }

    private func refreshStatusText() {
        if !downloadsAccessOK {
            statusMenuItem.title = "Boo can't see Downloads — click to fix"
            statusMenuItem.isEnabled = true
            statusMenuItem.target = self
            statusMenuItem.action = #selector(openPrivacySettings)
        } else {
            statusMenuItem.title = store.paused ? "Boo is napping" : "Boo is watching"
            statusMenuItem.isEnabled = false
            statusMenuItem.action = nil
        }
        pauseMenuItem.title = store.paused ? "Resume" : "Pause"
    }

    /// Called after each scan; surfaces missing Downloads permission instead
    /// of failing silently.
    func setDownloadsAccess(ok: Bool) {
        guard ok != downloadsAccessOK else { return }
        downloadsAccessOK = ok
        refreshStatusText()
        if !ok {
            ToastManager.shared.show("Boo can't see Downloads — check Privacy & Security")
        }
    }

    @objc private func openPrivacySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_FilesAndFolders")!
        NSWorkspace.shared.open(url)
    }

    @objc private func togglePause() {
        store.paused.toggle()
        refreshStatusText()
        refresh()
        if !store.paused { sorter.scan() }
    }

    @objc private func sortNow() {
        sorter.scan()
    }

    @objc private func openDownloads() {
        NSWorkspace.shared.open(Paths.downloads)
    }

    /// Opens the releases page in the browser; Boo itself makes no network calls.
    @objc private func checkForUpdates() {
        NSWorkspace.shared.open(URL(string: "https://github.com/dizzpy/Boo/releases/latest")!)
    }

    @objc private func openSettings() {
        if let w = settingsWindow {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let view = SettingsView(onClose: { [weak self] in self?.settingsWindow?.close() })
        let host = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: host)
        window.title = "Boo Settings"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 420, height: 520))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow = window
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
