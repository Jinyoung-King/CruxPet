import SwiftUI

struct CatView: View {
    let level: Int
    var emotion: EmotionState = .normal
    var accessories: [AccessorySlot: String] = [:]
    var isPomodoroActive: Bool = false
    var isWandering: Bool = false

    private var bodySize: CGFloat {
        switch level {
        case 1..<20:  return 32
        case 20..<30: return 36
        case 30..<40: return 40
        default:      return 44
        }
    }

    private var bodyColor: Color {
        if level >= 35 { return Color(red: 1.0, green: 0.84, blue: 0.0) }
        if level >= 25 { return Color(hex: "#E8A870") }
        return Color(hex: "#F4A460")
    }

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                drawCat(&ctx, size: size, t: t)
            }
            .frame(width: bodySize + 32, height: bodySize + 40)
        }
    }

    // MARK: - Drawing

    private func drawCat(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width / 2
        let cy = size.height / 2

        let speed: Double = isPomodoroActive ? 2.0 : (emotion == .sleepy ? 0.4 : 1.0)
        let bobAmp: CGFloat = isPomodoroActive ? 3.0 : (emotion == .sleepy ? 0.5 : 1.5)
        let bobY = CGFloat(sin(t * 2.5 * speed)) * bobAmp

        let tailSwing = CGFloat(sin(t * (isPomodoroActive ? 3.5 : 1.8)))
        let earTwitch: CGFloat = isWandering ? CGFloat(sin(t * 4.0)) * 2.0 : 0

        let bodyW = bodySize * 0.85
        let bodyH = bodySize * 0.58
        let bodyCenter = CGPoint(x: cx, y: cy + bodySize * 0.2 + bobY)
        let bodyRect = CGRect(
            x: bodyCenter.x - bodyW / 2, y: bodyCenter.y - bodyH / 2,
            width: bodyW, height: bodyH
        )
        let headR = bodySize * 0.38
        let headCenter = CGPoint(x: cx, y: bodyCenter.y - bodyH / 2 - headR * 0.75)

        // Tail (drawn before body so body overlaps the base)
        let tailBase = CGPoint(x: bodyRect.maxX - 2, y: bodyRect.midY)
        let tailCtrl = CGPoint(x: tailBase.x + bodySize * 0.32, y: tailBase.y - bodySize * 0.18)
        let tailTip = CGPoint(
            x: tailBase.x + bodySize * 0.42 + tailSwing * bodySize * 0.14,
            y: tailBase.y - bodySize * 0.52 + tailSwing * bodySize * 0.24
        )
        var tail = Path()
        tail.move(to: tailBase)
        tail.addQuadCurve(to: tailTip, control: tailCtrl)
        ctx.stroke(tail, with: .color(bodyColor), style: StrokeStyle(lineWidth: bodySize * 0.11, lineCap: .round))

        if level >= 35 {
            let sparkle = ctx.resolve(Text("✨").font(.system(size: bodySize * 0.25)))
            ctx.draw(sparkle, at: tailTip, anchor: .center)
        }

        // Body
        ctx.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))

        if level >= 15 && level < 35 {
            let bow = ctx.resolve(Text("🎀").font(.system(size: bodySize * 0.28)))
            ctx.draw(bow, at: CGPoint(x: bodyRect.minX + bodySize * 0.2, y: bodyRect.midY), anchor: .center)
        }
        if level >= 35 {
            let shimmer = ctx.resolve(Text("🌟").font(.system(size: bodySize * 0.25)))
            ctx.draw(shimmer, at: CGPoint(x: bodyRect.midX + bodySize * 0.22, y: bodyRect.midY), anchor: .center)
        }

        // Ears (outer then inner)
        let earH = headR * 0.75
        let earW = headR * 0.38
        let earBaseY = headCenter.y - headR * 0.55
        drawTriangleEar(&ctx, cx: headCenter.x - headR * 0.46, baseY: earBaseY, earW: earW, earH: earH, tilt: earTwitch, fill: bodyColor)
        drawTriangleEar(&ctx, cx: headCenter.x + headR * 0.46, baseY: earBaseY, earW: earW, earH: earH, tilt: -earTwitch, fill: bodyColor)
        drawTriangleEar(&ctx, cx: headCenter.x - headR * 0.46, baseY: earBaseY, earW: earW * 0.55, earH: earH * 0.58, tilt: earTwitch, fill: Color(hex: "#FFB6C1"))
        drawTriangleEar(&ctx, cx: headCenter.x + headR * 0.46, baseY: earBaseY, earW: earW * 0.55, earH: earH * 0.58, tilt: -earTwitch, fill: Color(hex: "#FFB6C1"))

        // Head
        ctx.fill(Path(ellipseIn: CGRect(
            x: headCenter.x - headR, y: headCenter.y - headR,
            width: headR * 2, height: headR * 2
        )), with: .color(bodyColor))

        if level >= 35 {
            let crown = ctx.resolve(Text("👑").font(.system(size: headR * 0.65)))
            ctx.draw(crown, at: CGPoint(x: headCenter.x, y: headCenter.y - headR * 1.5), anchor: .center)
        }

        drawCatEyes(&ctx, center: headCenter, headR: headR, t: t)

        // Nose
        ctx.fill(Path(ellipseIn: CGRect(
            x: headCenter.x - headR * 0.12, y: headCenter.y + headR * 0.28,
            width: headR * 0.24, height: headR * 0.16
        )), with: .color(Color(hex: "#FF9999")))

        drawWhiskers(&ctx, base: CGPoint(x: headCenter.x, y: headCenter.y + headR * 0.22), headR: headR)
        drawCatAccessories(&ctx, bodyRect: bodyRect, headCenter: headCenter, headR: headR)
    }

    private func drawTriangleEar(_ ctx: inout GraphicsContext, cx: CGFloat, baseY: CGFloat, earW: CGFloat, earH: CGFloat, tilt: CGFloat, fill: Color) {
        var p = Path()
        p.move(to: CGPoint(x: cx - earW, y: baseY + tilt))
        p.addLine(to: CGPoint(x: cx, y: baseY - earH))
        p.addLine(to: CGPoint(x: cx + earW, y: baseY + tilt))
        p.closeSubpath()
        ctx.fill(p, with: .color(fill))
    }

    private func drawCatEyes(_ ctx: inout GraphicsContext, center: CGPoint, headR: CGFloat, t: Double) {
        let eyeX1 = center.x - headR * 0.35
        let eyeX2 = center.x + headR * 0.35
        let eyeY  = center.y - headR * 0.06
        let ew = headR * 0.27
        let eh = headR * 0.32

        switch emotion {
        case .happy:
            for ex in [eyeX1, eyeX2] {
                var p = Path()
                p.addArc(center: CGPoint(x: ex, y: eyeY + ew * 0.25), radius: ew,
                         startAngle: .degrees(210), endAngle: .degrees(330), clockwise: false)
                ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
            }
        case .sleepy:
            for ex in [eyeX1, eyeX2] {
                var p = Path()
                p.move(to: CGPoint(x: ex - ew, y: eyeY))
                p.addLine(to: CGPoint(x: ex + ew, y: eyeY))
                ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
        case .excited:
            let er = ew * 1.3
            for ex in [eyeX1, eyeX2] {
                ctx.fill(Path(ellipseIn: CGRect(x: ex - er, y: eyeY - er, width: er * 2, height: er * 2)), with: .color(.black))
                ctx.fill(Path(ellipseIn: CGRect(x: ex - er * 0.38, y: eyeY - er * 0.6, width: er * 0.48, height: er * 0.48)), with: .color(.white))
            }
        default:
            for ex in [eyeX1, eyeX2] {
                ctx.fill(Path(ellipseIn: CGRect(x: ex - ew, y: eyeY - eh, width: ew * 2, height: eh * 2)), with: .color(.black))
                ctx.fill(Path(ellipseIn: CGRect(x: ex - ew * 0.25, y: eyeY - eh * 0.65, width: ew * 0.45, height: ew * 0.45)), with: .color(.white))
            }
        }
    }

    private func drawWhiskers(_ ctx: inout GraphicsContext, base: CGPoint, headR: CGFloat) {
        let style = StrokeStyle(lineWidth: 0.8, lineCap: .round)
        let shading = GraphicsContext.Shading.color(Color.gray.opacity(0.55))
        for (side, spread): (CGFloat, CGFloat) in [(-1, -headR * 0.76), (-1, -headR * 0.82), (1, headR * 0.76), (1, headR * 0.82)] {
            let dySign: CGFloat = spread < 0 ? -headR * 0.06 : headR * 0.06
            var p = Path()
            p.move(to: CGPoint(x: base.x + side * headR * 0.08, y: base.y + dySign))
            p.addLine(to: CGPoint(x: base.x + spread, y: base.y + dySign * 0.5))
            ctx.stroke(p, with: shading, style: style)
        }
    }

    private func drawCatAccessories(_ ctx: inout GraphicsContext, bodyRect: CGRect, headCenter: CGPoint, headR: CGFloat) {
        if let emoji = accessories[.head] {
            let r = ctx.resolve(Text(emoji).font(.system(size: headR * 0.8)))
            ctx.draw(r, at: CGPoint(x: headCenter.x, y: headCenter.y - headR), anchor: .bottom)
        }
        if let emoji = accessories[.face] {
            let r = ctx.resolve(Text(emoji).font(.system(size: headR * 0.6)))
            ctx.draw(r, at: CGPoint(x: headCenter.x, y: headCenter.y + headR * 0.2), anchor: .center)
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
            CatView(level: 1)
            CatView(level: 1, emotion: .happy)
            CatView(level: 1, emotion: .sleepy)
            CatView(level: 1, emotion: .excited)
        }
        VStack(spacing: 4) {
            CatView(level: 20, isPomodoroActive: true)
            CatView(level: 35, emotion: .happy, isWandering: true)
        }
    }
    .padding()
}
