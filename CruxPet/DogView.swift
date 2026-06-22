import SwiftUI

struct DogView: View {
    let level: Int
    var emotion: EmotionState = .normal
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

    private var bodyColor: Color  { Color(hex: level >= 35 ? "#EDD5A3" : "#DEB887") }
    private var earColor:  Color  { Color(hex: level >= 35 ? "#C9963F" : "#C49A6C") }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { tl in
            Canvas { ctx, size in
                let t = tl.date.timeIntervalSinceReferenceDate
                drawDog(&ctx, size: size, t: t)
            }
            .frame(width: bodySize + 32, height: bodySize + 40)
        }
    }

    // MARK: - Drawing

    private func drawDog(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let cx = size.width / 2
        let cy = size.height / 2

        let speed: Double = isPomodoroActive ? 2.5 : (emotion == .sleepy ? 0.4 : 1.0)
        let bobAmp: CGFloat = isPomodoroActive ? 4.0 : (emotion == .excited ? 3.0 : (emotion == .sleepy ? 0.5 : 1.5))
        let floatOffset: CGFloat = emotion == .excited ? -3.0 : 0
        let bobY = CGFloat(sin(t * 2.5 * speed)) * bobAmp + floatOffset

        let tailSwing = CGFloat(sin(t * (isPomodoroActive ? 5.0 : 3.0)))

        let bodyW = bodySize * 0.82
        let bodyH = bodySize * 0.62
        let bodyCenter = CGPoint(x: cx, y: cy + bodySize * 0.18 + bobY)
        let bodyRect = CGRect(
            x: bodyCenter.x - bodyW / 2, y: bodyCenter.y - bodyH / 2,
            width: bodyW, height: bodyH
        )
        let headR = bodySize * 0.42
        let headCenter = CGPoint(x: cx, y: bodyCenter.y - bodyH / 2 - headR * 0.68)

        // Tail (behind body)
        let tailBase = CGPoint(x: bodyRect.maxX, y: bodyRect.midY - bodyH * 0.08)
        let tailCtrl  = CGPoint(x: tailBase.x + bodySize * 0.2, y: tailBase.y - bodySize * 0.08)
        let tailTip   = CGPoint(
            x: tailBase.x + bodySize * 0.26 + tailSwing * bodySize * 0.12,
            y: tailBase.y - bodySize * 0.32 - tailSwing * bodySize * 0.14
        )
        var tail = Path()
        tail.move(to: tailBase)
        tail.addQuadCurve(to: tailTip, control: tailCtrl)
        ctx.stroke(tail, with: .color(bodyColor), style: StrokeStyle(lineWidth: bodySize * 0.13, lineCap: .round))

        // Body
        ctx.fill(Path(ellipseIn: bodyRect), with: .color(bodyColor))

        // Collar (level 25+)
        if level >= 25 {
            let collarRect = CGRect(
                x: bodyRect.minX + bodyW * 0.1, y: bodyRect.minY - 3,
                width: bodyW * 0.8, height: 5
            )
            ctx.fill(Path(ellipseIn: collarRect), with: .color(Color(hex: "#CC3333")))
            if level >= 35 {
                let gem = ctx.resolve(Text("💎").font(.system(size: bodySize * 0.2)))
                ctx.draw(gem, at: CGPoint(x: cx, y: bodyRect.minY - 1), anchor: .center)
            }
        }

        // Floppy ears (drawn before head)
        let earW = headR * 0.55
        let earH = headR * 0.85
        let earBobDiff = CGFloat(sin(t * 2.5 * speed)) * (isPomodoroActive ? 2.5 : 0.8)
        let earCenterY = headCenter.y + headR * 0.08

        ctx.fill(Path(ellipseIn: CGRect(
            x: headCenter.x - headR * 0.85 - earW,
            y: earCenterY - earH / 2 + earBobDiff,
            width: earW * 2, height: earH
        )), with: .color(earColor))

        ctx.fill(Path(ellipseIn: CGRect(
            x: headCenter.x + headR * 0.85 - earW,
            y: earCenterY - earH / 2 - earBobDiff,
            width: earW * 2, height: earH
        )), with: .color(earColor))

        // Head
        ctx.fill(Path(ellipseIn: CGRect(
            x: headCenter.x - headR, y: headCenter.y - headR,
            width: headR * 2, height: headR * 2
        )), with: .color(bodyColor))

        // Snout
        let snoutW = headR * 0.55
        let snoutH = headR * 0.38
        let snoutCenter = CGPoint(x: headCenter.x, y: headCenter.y + headR * 0.3)
        ctx.fill(Path(ellipseIn: CGRect(
            x: snoutCenter.x - snoutW / 2, y: snoutCenter.y - snoutH / 2,
            width: snoutW, height: snoutH
        )), with: .color(Color(hex: "#F5DEB3")))

        // Nose
        ctx.fill(Path(ellipseIn: CGRect(
            x: headCenter.x - headR * 0.18, y: headCenter.y + headR * 0.14,
            width: headR * 0.36, height: headR * 0.26
        )), with: .color(.black))

        drawDogEyes(&ctx, center: headCenter, headR: headR)

        // Tongue (happy / excited)
        if emotion == .happy || emotion == .excited {
            ctx.fill(Path(ellipseIn: CGRect(
                x: headCenter.x - headR * 0.15,
                y: snoutCenter.y + snoutH * 0.28,
                width: headR * 0.3, height: headR * 0.3
            )), with: .color(Color(hex: "#FF6B8A")))
        }

        if level >= 35 {
            let sparkle = ctx.resolve(Text("✨").font(.system(size: bodySize * 0.22)))
            ctx.draw(sparkle, at: CGPoint(x: bodyRect.minX + 2, y: bodyRect.minY + 2), anchor: .center)
        }

        if isPomodoroActive {
            let tomato = ctx.resolve(Text("🍅").font(.system(size: headR * 0.6)))
            ctx.draw(tomato, at: CGPoint(x: headCenter.x, y: headCenter.y - headR * 1.1), anchor: .bottom)
        }
    }

    private func drawDogEyes(_ ctx: inout GraphicsContext, center: CGPoint, headR: CGFloat) {
        let eyeX1 = center.x - headR * 0.32
        let eyeX2 = center.x + headR * 0.32
        let eyeY  = center.y - headR * 0.14
        let er    = headR * 0.26

        switch emotion {
        case .happy:
            for ex in [eyeX1, eyeX2] {
                var p = Path()
                p.addArc(center: CGPoint(x: ex, y: eyeY + er * 0.28), radius: er,
                         startAngle: .degrees(210), endAngle: .degrees(330), clockwise: false)
                ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 2.0, lineCap: .round))
            }
        case .sleepy:
            for ex in [eyeX1, eyeX2] {
                var p = Path()
                p.move(to: CGPoint(x: ex - er, y: eyeY + er * 0.28))
                p.addLine(to: CGPoint(x: ex + er, y: eyeY + er * 0.28))
                ctx.stroke(p, with: .color(.black), style: StrokeStyle(lineWidth: 2.0))
            }
        case .excited:
            let bigR = er * 1.3
            for ex in [eyeX1, eyeX2] {
                ctx.fill(Path(ellipseIn: CGRect(x: ex - bigR, y: eyeY - bigR, width: bigR * 2, height: bigR * 2)), with: .color(.black))
                ctx.fill(Path(ellipseIn: CGRect(x: ex - bigR * 0.35, y: eyeY - bigR * 0.55, width: bigR * 0.45, height: bigR * 0.45)), with: .color(.white))
            }
        default:
            for ex in [eyeX1, eyeX2] {
                ctx.fill(Path(ellipseIn: CGRect(x: ex - er, y: eyeY - er, width: er * 2, height: er * 2)), with: .color(.black))
                ctx.fill(Path(ellipseIn: CGRect(x: ex - er * 0.3, y: eyeY - er * 0.58, width: er * 0.48, height: er * 0.48)), with: .color(.white))
            }
        }
    }

}

#Preview {
    HStack(spacing: 8) {
        VStack(spacing: 4) {
            DogView(level: 1)
            DogView(level: 1, emotion: .happy)
            DogView(level: 1, emotion: .sleepy)
            DogView(level: 1, emotion: .excited)
        }
        VStack(spacing: 4) {
            DogView(level: 25, isPomodoroActive: true)
            DogView(level: 35, emotion: .happy)
        }
    }
    .padding()
}
