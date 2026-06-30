import AppKit
import SwiftUI

final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let sorter: Sorter
    private let store = Store.shared

    private var animTimer: Timer?
    private var frame = 0
    private var temporaryState: GhostState = .idle
    private var temporaryUntil: Date?

    private var settingsWindow: NSWindow?
    private let statusMenuItem = NSMenuItem(title: "Boo is watching", action: nil, keyEquivalent: "")
    private let pauseMenuItem = NSMenuItem(title: "Pause", action: nil, keyEquivalent: "")

    init(sorter: Sorter) {
        self.sorter = sorter
        super.init()

        item.button?.image = GhostRenderer.image(.idle, frame: 0)
        item.button?.imagePosition = .imageOnly
        buildMenu()
        startAnimation()
        refreshStatusText()
    }

    // MARK: - Animation

    private func startAnimation() {
        animTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { [weak self] _ in
            self?.tick()
        }
        if let t = animTimer { RunLoop.main.add(t, forMode: .common) }
    }

    private func tick() {
        frame &+= 1
        let now = Date()
        let active: GhostState
        if let until = temporaryUntil, now < until {
            active = temporaryState
        } else {
            temporaryUntil = nil
            active = .idle
        }
        item.button?.image = GhostRenderer.image(active, frame: frame)
    }

    func playEating() { setTemporary(.eating, for: 0.9) }
    func playConfused() { setTemporary(.confused, for: 1.4) }

    private func setTemporary(_ state: GhostState, for duration: TimeInterval) {
        temporaryState = state
        temporaryUntil = Date().addingTimeInterval(duration)
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

        let quit = NSMenuItem(title: "Quit Boo", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
    }

    private func refreshStatusText() {
        statusMenuItem.title = store.paused ? "Boo is napping" : "Boo is watching"
        pauseMenuItem.title = store.paused ? "Resume" : "Pause"
    }

    @objc private func togglePause() {
        store.paused.toggle()
        refreshStatusText()
        if !store.paused { sorter.scan() }
    }

    @objc private func sortNow() {
        sorter.scan()
    }

    @objc private func openDownloads() {
        NSWorkspace.shared.open(Paths.downloads)
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
