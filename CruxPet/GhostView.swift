import SwiftUI

struct GhostView: View {
    let level: Int
    var emotion: EmotionState = .normal
    var accessories: [AccessorySlot: String] = [:]
    var isPomodoroActive: Bool = false
    var isWandering: Bool = false
    var environmentAccessories: [EnvironmentAccessory] = []

    private var bodySize: CGFloat {
        switch level {
        case 1..<20:  return 32
        case 20..<30: return 36
        case 30..<40: return 40
        default:      return 44
        }
    }

    private var isNightTime: Bool {
        environmentAccessories.contains(.moon) || environmentAccessories.contains(.star)
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                drawGhost(&ctx, size: size, t: t)
            }
            .frame(width: bodySize + 32, height: bodySize + 40)
        }
    }

    // MARK: - Drawing

    private func drawGhost(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width / 2
        let cy = size.height / 2

        let floatY = CGFloat(sin(t * 0.7)) * 3.0
        let opacityBase: Double = isNightTime ? 1.0 : 0.82
        let opacity = opacityBase + sin(t * 1.2) * 0.08

        let ghostW = bodySize * 0.72
        let ghostH = bodySize * 0.95
        let topY   = cy - ghostH * 0.38 + floatY

        // Build ghost body path: semicircle dome + wavy bottom
        var ghost = Path()
        let domeCenter = CGPoint(x: cx, y: topY + ghostW / 2)
        ghost.addArc(center: domeCenter, radius: ghostW / 2,
                     startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        let bottomY = topY + ghostH
        ghost.addLine(to: CGPoint(x: cx + ghostW / 2, y: bottomY - ghostW * 0.20))

        let bumpW = ghostW / 3
        ghost.addQuadCurve(
            to: CGPoint(x: cx + ghostW / 2 - bumpW, y: bottomY - ghostW * 0.02),
            control: CGPoint(x: cx + ghostW / 2 - bumpW * 0.3, y: bottomY + ghostW * 0.13)
        )
        ghost.addQuadCurve(
            to: CGPoint(x: cx + ghostW / 2 - bumpW * 2, y: bottomY - ghostW * 0.20),
            control: CGPoint(x: cx + ghostW / 2 - bumpW * 1.5, y: bottomY - ghostW * 0.30)
        )
        ghost.addQuadCurve(
            to: CGPoint(x: cx - ghostW / 2, y: bottomY - ghostW * 0.20),
            control: CGPoint(x: cx + ghostW / 2 - bumpW * 2.6, y: bottomY + ghostW * 0.13)
        )
        ghost.closeSubpath()

        // Pomodoro: slow rotation around ghost center
        var drawCtx = ctx
        if isPomodoroActive {
            let rotCenter = CGPoint(x: cx, y: (topY + bottomY) / 2)
            drawCtx.translateBy(x: rotCenter.x, y: rotCenter.y)
            drawCtx.rotate(by: .radians(t * (30 * .pi / 180)))
            drawCtx.translateBy(x: -rotCenter.x, y: -rotCenter.y)
        }

        // Base color
        let baseColor: Color
        if level >= 35 {
            let hue = (t * 0.1).truncatingRemainder(dividingBy: 1.0)
            baseColor = Color(hue: hue, saturation: 0.45, brightness: 0.98)
        } else {
            baseColor = Color(hex: "#D8D8FF")
        }

        drawCtx.fill(ghost, with: .color(baseColor.opacity(opacity)))

        // Night glow overlay
        if isNightTime || level >= 35 {
            drawCtx.fill(ghost, with: .color(Color.cyan.opacity(0.10)))
        }

        // Level 40+: orbiting sparkles
        if level >= 40 {
            let sparkle = ctx.resolve(Text("✨").font(.system(size: bodySize * 0.20)))
            for i in 0..<3 {
                let angle = Double(i) * 2.094 + t * 0.5
                let orbitR = ghostW * 0.58
                let sx = cx + orbitR * CGFloat(cos(angle))
                let sy = (topY + bottomY) / 2 + orbitR * 0.4 * CGFloat(sin(angle))
                drawCtx.draw(sparkle, at: CGPoint(x: sx, y: sy), anchor: .center)
            }
        }

        // Level 45+: crown
        if level >= 45 {
            let crown = ctx.resolve(Text("👑").font(.system(size: bodySize * 0.38)))
            drawCtx.draw(crown, at: CGPoint(x: cx, y: topY), anchor: .bottom)
        }

        // Eyes
        let eyeY  = topY + ghostW * 0.55
        let eyeX1 = cx - ghostW * 0.22
        let eyeX2 = cx + ghostW * 0.22
        let er    = ghostW * 0.18

        drawGhostEyes(&drawCtx, x1: eyeX1, x2: eyeX2, y: eyeY, r: er)

        // Mouth
        let mouthY = eyeY + er * 2.0
        drawGhostMouth(&drawCtx, cx: cx, y: mouthY, r: er)

        // Accessories use original (non-rotated) context
        let bodyRect = CGRect(x: cx - ghostW / 2, y: topY, width: ghostW, height: ghostH)
        drawGhostAccessories(&ctx, bodyRect: bodyRect, topCenter: CGPoint(x: cx, y: topY))
        if isPomodoroActive {
            let tomato = ctx.resolve(Text("🍅").font(.system(size: bodySize * 0.3)))
            ctx.draw(tomato, at: CGPoint(x: cx, y: topY), anchor: .bottom)
        }
    }

    private func drawGhostEyes(_ ctx: inout GraphicsContext, x1: CGFloat, x2: CGFloat, y: CGFloat, r: CGFloat) {
        switch emotion {
        case .happy:
            for ex in [x1, x2] {
                var p = Path()
                p.addArc(center: CGPoint(x: ex, y: y + r * 0.28), radius: r,
                         startAngle: .degrees(210), endAngle: .degrees(330), clockwise: false)
                ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
        case .sleepy:
            for ex in [x1, x2] {
                var p = Path()
                p.addArc(center: CGPoint(x: ex, y: y), radius: r,
                         startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
                ctx.fill(p, with: .color(.black))
            }
        default:
            for ex in [x1, x2] {
                ctx.fill(Path(ellipseIn: CGRect(x: ex - r, y: y - r, width: r * 2, height: r * 2)), with: .color(.black))
                ctx.fill(Path(ellipseIn: CGRect(x: ex - r * 0.35, y: y - r * 0.6, width: r * 0.5, height: r * 0.5)), with: .color(.white))
            }
        }
    }

    private func drawGhostMouth(_ ctx: inout GraphicsContext, cx: CGFloat, y: CGFloat, r: CGFloat) {
        switch emotion {
        case .happy:
            var p = Path()
            p.move(to: CGPoint(x: cx - r, y: y))
            p.addQuadCurve(to: CGPoint(x: cx + r, y: y), control: CGPoint(x: cx, y: y + r * 0.9))
            ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        case .sleepy:
            var p = Path()
            p.move(to: CGPoint(x: cx - r * 0.55, y: y))
            p.addLine(to: CGPoint(x: cx + r * 0.55, y: y))
            ctx.stroke(p, with: .color(.black), lineWidth: 1.5)
        default:
            ctx.stroke(Path(ellipseIn: CGRect(x: cx - r * 0.38, y: y - r * 0.32, width: r * 0.76, height: r * 0.65)),
                       with: .color(.black), lineWidth: 1.2)
        }
    }

    private func drawGhostAccessories(_ ctx: inout GraphicsContext, bodyRect: CGRect, topCenter: CGPoint) {
        if let emoji = accessories[.head] {
            let r = ctx.resolve(Text(emoji).font(.system(size: bodyRect.width * 0.4)))
            ctx.draw(r, at: topCenter, anchor: .bottom)
        }
        if let emoji = accessories[.face] {
            let r = ctx.resolve(Text(emoji).font(.system(size: bodyRect.width * 0.3)))
            ctx.draw(r, at: CGPoint(x: bodyRect.midX, y: bodyRect.midY), anchor: .center)
        }
        if let emoji = accessories[.body] {
            let r = ctx.resolve(Text(emoji).font(.system(size: bodyRect.width * 0.35)))
            ctx.draw(r, at: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY), anchor: .bottomTrailing)
        }
        if let emoji = accessories[.aura] {
            let r = ctx.resolve(Text(emoji).font(.system(size: bodyRect.width * 0.35)))
            ctx.draw(r, at: CGPoint(x: bodyRect.minX, y: bodyRect.maxY), anchor: .bottomLeading)
        }
    }
}

#Preview {
    HStack(spacing: 8) {
        VStack(spacing: 4) {
            GhostView(level: 1)
            GhostView(level: 1, emotion: .happy)
            GhostView(level: 1, emotion: .sleepy)
            GhostView(level: 1, emotion: .excited)
        }
        VStack(spacing: 4) {
            GhostView(level: 1, isPomodoroActive: true)
            GhostView(level: 35, environmentAccessories: [.moon])
        }
    }
    .padding()
}
