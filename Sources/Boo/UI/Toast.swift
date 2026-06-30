import AppKit
import SwiftUI

/// Small floating toast near the top-right of the screen.
final class ToastManager {
    static let shared = ToastManager()
    private var panel: NSPanel?
    private var hideWork: DispatchWorkItem?

    func show(_ message: String) {
        // Reuse a single panel.
        let host = NSHostingView(rootView: ToastView(message: message))
        let contentSize = host.fittingSize
        let width = max(160, contentSize.width)
        let height = max(40, contentSize.height)

        let panel = self.panel ?? makePanel()
        panel.setContentSize(NSSize(width: width, height: height))
        panel.contentView = host
        positionTopRight(panel, size: NSSize(width: width, height: height))

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.18
            panel.animator().alphaValue = 1
        }

        self.panel = panel
        hideWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.hide() }
        hideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: work)
    }

    private func hide() {
        guard let panel = panel else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        return panel
    }

    private func positionTopRight(_ panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let x = visible.maxX - size.width - 16
        let y = visible.maxY - size.height - 12
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}

private struct ToastView: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            GhostAvatar(avatar: .happy, height: 20)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.12)))
        .fixedSize()
    }
}
