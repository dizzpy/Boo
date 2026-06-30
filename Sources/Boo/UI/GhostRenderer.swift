import AppKit

enum GhostState {
    case idle, eating, confused
}

/// Draws the little ghost as a template NSImage so the menu bar tints it
/// correctly in light and dark mode.
enum GhostRenderer {

    static func image(_ state: GhostState, frame: Int) -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            draw(in: ctx, rect: rect, state: state, frame: frame)
            return true
        }
        image.isTemplate = true
        return image
    }

    private static func draw(in ctx: CGContext, rect: CGRect, state: GhostState, frame: Int) {
        ctx.setFillColor(NSColor.black.cgColor)

        // Gentle vertical bob for the idle state.
        let bob: CGFloat = (state == .idle && (frame / 5) % 2 == 1) ? 1 : 0

        let cx = rect.midX
        let bodyW: CGFloat = 14
        let left = cx - bodyW / 2
        let right = cx + bodyW / 2
        let bottom: CGFloat = 2 + bob
        let shoulderY: CGFloat = 9 + bob
        let topY: CGFloat = 16 + bob
        let radius = bodyW / 2

        let body = CGMutablePath()
        body.move(to: CGPoint(x: left, y: bottom))
        body.addLine(to: CGPoint(x: left, y: shoulderY))
        // Domed head.
        body.addArc(center: CGPoint(x: cx, y: shoulderY),
                    radius: radius, startAngle: .pi, endAngle: 0, clockwise: false)
        body.addLine(to: CGPoint(x: right, y: bottom))
        // Scalloped bottom (3 bumps).
        let bumps = 3
        let step = bodyW / CGFloat(bumps)
        var x = right
        for _ in 0..<bumps {
            let nextX = x - step
            let midX = (x + nextX) / 2
            body.addQuadCurve(to: CGPoint(x: nextX, y: bottom),
                              control: CGPoint(x: midX, y: bottom + 3))
            x = nextX
        }
        body.closeSubpath()

        // Eyes (and mouth) are punched out with an even-odd fill.
        let eyeR: CGFloat = (state == .confused) ? 2.0 : 1.6
        let eyeY = shoulderY + 2 + (topY - shoulderY) * 0
        let eyeL = CGRect(x: cx - 3.5 - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)
        let eyeRr = CGRect(x: cx + 3.5 - eyeR, y: eyeY - eyeR, width: eyeR * 2, height: eyeR * 2)

        ctx.addPath(body)
        ctx.addEllipse(in: eyeL)
        ctx.addEllipse(in: eyeRr)

        if state == .eating {
            // Open, chomping mouth that pulses across frames.
            let open = (frame % 2 == 0) ? 3.2 : 1.6
            let mouth = CGRect(x: cx - 2.5, y: shoulderY - 1.5, width: 5, height: open)
            ctx.addEllipse(in: mouth)
        }

        ctx.fillPath(using: .evenOdd)

        if state == .confused {
            let q = NSAttributedString(string: "?", attributes: [
                .font: NSFont.boldSystemFont(ofSize: 8),
                .foregroundColor: NSColor.black
            ])
            q.draw(at: CGPoint(x: right - 3, y: topY - 5))
        }
    }
}
