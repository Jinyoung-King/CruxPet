import SwiftUI

struct SlimeView: View {
    let appearance: SlimeAppearance
    var isPomodoroActive: Bool = false
    var accessory: String = ""
    var isWandering: Bool = false

    // 배회 시 캔버스를 확장해 클리핑 방지
    private var wanderPad: CGFloat { isWandering ? appearance.size * 0.45 : 0 }
    private var totalWidth:  CGFloat { appearance.size + 32 + wanderPad * 2 }
    private var totalHeight: CGFloat { appearance.size + 40 + wanderPad * 2 }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // ── 배회 / 스쿼시 계산 ──────────────────────────────
                // 리사주 곡선: x 0.55Hz, y 1.1Hz → 피규어8 경로
                let wanderAmp: CGFloat = isWandering ? appearance.size * 0.33 : 0
                let wx: CGFloat = sin(t * 0.55 + .pi / 2) * wanderAmp
                let wy: CGFloat = sin(t * 1.10)            * wanderAmp * 0.38

                // 정규화 속도 (-1…1)
                let vxN: CGFloat = cos(t * 0.55 + .pi / 2)
                let vyN: CGFloat = cos(t * 1.10)

                let bobY: CGFloat = sin(t * 2.5) * 2 + wy

                // 이동 방향으로 가로 늘이기 / 세로 납작하기
                let hStretch: CGFloat = 1 + abs(vxN) * (isWandering ? 0.10 : 0)
                let vSquish:  CGFloat = 1 - abs(vxN) * (isWandering ? 0.065 : 0)

                let bodyW = appearance.size * hStretch
                let bodyH = appearance.size * vSquish

                let bodyRect = CGRect(
                    x: (size.width  - bodyW) / 2 + wx,
                    y: (size.height - bodyH) / 2 + bobY,
                    width:  bodyW,
                    height: bodyH * 0.85
                )

                // 후광
                if appearance.hasHalo {
                    drawHalo(context: &context,
                             center: CGPoint(x: bodyRect.midX, y: bodyRect.midY),
                             radius: appearance.size * 0.7)
                }

                drawContactShadow(context: &context, rect: bodyRect)

                // ── 기울기 컨텍스트 (몸통+눈만 적용) ───────────────
                var tiltCtx = context
                if isWandering {
                    let tiltRad = vxN * 0.10   // 최대 ±5.7°
                    tiltCtx.translateBy(x: bodyRect.midX, y: bodyRect.midY)
                    tiltCtx.rotate(by: .radians(Double(tiltRad)))
                    tiltCtx.translateBy(x: -bodyRect.midX, y: -bodyRect.midY)
                }

                drawBody(context: &tiltCtx, rect: bodyRect, t: t)
                drawEyes(context: &tiltCtx, bodyRect: bodyRect,
                         lookX: isWandering ? vxN * 0.18 : 0,
                         lookY: isWandering ? vyN * 0.10 : 0)

                // 왕관 / 반짝이 / 악세서리는 기울기 없이 원래 컨텍스트 사용
                if appearance.crownType != .none {
                    drawCrown(context: &context, bodyRect: bodyRect)
                }
                drawSparkles(context: &context, bodyRect: bodyRect, t: t,
                             count: appearance.sparkleCount)
                if !accessory.isEmpty {
                    drawAccessory(context: &context, bodyRect: bodyRect)
                }
            }
            .frame(width: totalWidth, height: totalHeight)
        }
    }

    // MARK: - Body

    private func drawBody(context: inout GraphicsContext, rect: CGRect, t: Double) {
        if isPomodoroActive {
            let tomato = context.resolve(Text("🍅").font(.system(size: rect.width * 0.9)))
            context.draw(tomato, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
            return
        }

        let path = Path(ellipseIn: rect)
        let bodyColor: Color
        if appearance.isRainbow {
            let hue = (t * 0.2).truncatingRemainder(dividingBy: 1.0)
            bodyColor = Color(hue: hue, saturation: 0.75, brightness: 0.92)
        } else {
            bodyColor = Color(hex: appearance.bodyHex)
        }

        // 외곽선
        var outCtx = context; outCtx.opacity = 0.22
        outCtx.stroke(path, with: .color(bodyColor), lineWidth: rect.width * 0.07)

        // 기본 몸통
        context.fill(path, with: .color(bodyColor))

        // 조명 (좌상단)
        let lc = CGPoint(x: rect.minX + rect.width * 0.30, y: rect.minY + rect.height * 0.20)
        context.fill(path, with: .radialGradient(
            Gradient(stops: [
                .init(color: .white.opacity(0.55), location: 0.0),
                .init(color: .white.opacity(0.15), location: 0.50),
                .init(color: .clear,               location: 1.0),
            ]),
            center: lc, startRadius: 0, endRadius: rect.width * 0.9
        ))

        // 하단 음영
        context.fill(path, with: .linearGradient(
            Gradient(colors: [.clear, .black.opacity(0.22)]),
            startPoint: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.25),
            endPoint:   CGPoint(x: rect.midX, y: rect.maxY)
        ))

        // 광택 스팟
        let sp = CGRect(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.06,
                        width: rect.width * 0.35, height: rect.height * 0.24)
        var spCtx = context; spCtx.opacity = 0.82
        spCtx.fill(Path(ellipseIn: sp), with: .radialGradient(
            Gradient(colors: [.white, .clear]),
            center: CGPoint(x: sp.midX, y: sp.midY),
            startRadius: 0, endRadius: max(sp.width, sp.height) * 0.65
        ))

        // 림라이트
        let rr = CGRect(x: rect.minX + rect.width * 0.22, y: rect.maxY - rect.height * 0.20,
                        width: rect.width * 0.56, height: rect.height * 0.16)
        var rrCtx = context; rrCtx.opacity = 0.22
        rrCtx.fill(Path(ellipseIn: rr), with: .linearGradient(
            Gradient(colors: [.clear, .white.opacity(0.6)]),
            startPoint: CGPoint(x: rr.midX, y: rr.minY),
            endPoint:   CGPoint(x: rr.midX, y: rr.maxY)
        ))

        // 펄
        if appearance.isPearl {
            var pCtx = context; pCtx.opacity = 0.25 + 0.2 * sin(t * 4)
            pCtx.fill(path, with: .linearGradient(
                Gradient(colors: [
                    Color(hue: (t * 0.1).truncatingRemainder(dividingBy: 1.0),
                          saturation: 0.5, brightness: 1.0).opacity(0.6), .clear
                ]),
                startPoint: CGPoint(x: rect.maxX, y: rect.minY),
                endPoint:   CGPoint(x: rect.minX, y: rect.maxY)
            ))
        }
    }

    // MARK: - Contact Shadow

    private func drawContactShadow(context: inout GraphicsContext, rect: CGRect) {
        let cx = rect.midX, y = rect.maxY - 1
        let w = rect.width * 0.82, h = rect.height * 0.14
        for (ws, hs, op): (Double, Double, Double) in [(1.5,1.8,0.05),(1.1,1.3,0.08),(0.7,0.9,0.11)] {
            let sr = CGRect(x: cx - w*ws/2, y: y - h*hs/2, width: w*ws, height: h*hs)
            var ctx = context; ctx.opacity = op
            ctx.fill(Path(ellipseIn: sr), with: .color(.black))
        }
    }

    // MARK: - Eyes

    private func drawEyes(context: inout GraphicsContext, bodyRect: CGRect,
                          lookX: CGFloat = 0, lookY: CGFloat = 0) {
        let eyeY    = bodyRect.minY + bodyRect.height * 0.37
        let eyeSize = bodyRect.width * 0.13
        let pupilSz = eyeSize * 0.56
        let spacing = bodyRect.width * 0.22

        for xOffset in [-spacing, spacing] {
            let cx = bodyRect.midX + xOffset

            let whiteRect = CGRect(x: cx - eyeSize/2, y: eyeY - eyeSize/2,
                                   width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: whiteRect), with: .color(.white))
            context.fill(Path(ellipseIn: whiteRect), with: .radialGradient(
                Gradient(colors: [.clear, .black.opacity(0.10)]),
                center: CGPoint(x: cx, y: eyeY - eyeSize * 0.05),
                startRadius: eyeSize * 0.25, endRadius: eyeSize * 0.58
            ))

            // 동공 — 보는 방향으로 이동
            let pupilX = cx       + eyeSize * lookX
            let pupilY = eyeY + eyeSize * 0.07 + eyeSize * lookY
            let pr = CGRect(x: pupilX - pupilSz/2, y: pupilY - pupilSz/2,
                            width: pupilSz, height: pupilSz)
            context.fill(Path(ellipseIn: pr), with: .color(Color(white: 0.08)))

            // 캐치라이트
            let cs = pupilSz * 0.32
            let cr = CGRect(x: pupilX - pupilSz*0.04, y: pupilY - pupilSz*0.28,
                            width: cs, height: cs)
            context.fill(Path(ellipseIn: cr), with: .color(.white.opacity(0.92)))
        }
    }

    // MARK: - Crown

    private func drawCrown(context: inout GraphicsContext, bodyRect: CGRect) {
        let text = context.resolve(Text(appearance.crownType.symbol)
            .font(.system(size: bodyRect.width * 0.45)))
        let ts = text.measure(in: CGSize(width: 100, height: 100))
        context.draw(text, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY - ts.height * 0.3))
    }

    // MARK: - Halo

    private func drawHalo(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius * 0.3,
                          width: radius * 2, height: radius * 0.6)
        let path = Path(ellipseIn: rect)
        for (lw, op): (Double, Double) in [(7,0.07),(4.5,0.14),(2.5,0.35),(1.5,0.65)] {
            var ctx = context
            ctx.stroke(path, with: .color(Color.yellow.opacity(op)), lineWidth: lw)
        }
    }

    // MARK: - Sparkles

    private func drawSparkles(context: inout GraphicsContext, bodyRect: CGRect,
                               t: Double, count: Int) {
        guard count > 0 else { return }
        let pos: [(Double,Double)] = [
            (-1.1,-0.6),(1.1,-0.4),(-0.9,0.4),(1.0,0.6),
            (-1.3,0.0),(1.3,0.1),(-0.7,-1.0),(0.8,-0.9),
            (-1.2,0.9),(1.1,1.0)
        ]
        for i in 0..<min(count, pos.count) {
            let (dx,dy) = pos[i]
            let x = bodyRect.midX + CGFloat(dx) * bodyRect.width  * 0.65
            let y = bodyRect.midY + CGFloat(dy) * bodyRect.height * 0.65
            let phase = Double(i) * 0.7
            let alpha = 0.4 + 0.6 * abs(sin(t * 3 + phase))
            let scale = 0.7 + 0.4 * abs(sin(t * 2.5 + phase + 1.0))
            var ctx = context; ctx.opacity = alpha
            let s = ctx.resolve(Text("✦").font(.system(size: 8 * scale)))
            ctx.draw(s, at: CGPoint(x: x, y: y), anchor: .center)
        }
    }

    // MARK: - Accessory

    private func drawAccessory(context: inout GraphicsContext, bodyRect: CGRect) {
        let size = bodyRect.width * 0.38
        let r = context.resolve(Text(accessory).font(.system(size: size)))
        context.draw(r, at: CGPoint(x: bodyRect.maxX - size*0.1,
                                    y: bodyRect.minY - size*0.1), anchor: .bottomTrailing)
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)          / 255
        self.init(red: r, green: g, blue: b)
    }
}

#Preview {
    VStack(spacing: 8) {
        SlimeView(appearance: PetModel.appearance(for: 1),  isWandering: true)
        SlimeView(appearance: PetModel.appearance(for: 10), isWandering: true)
        SlimeView(appearance: PetModel.appearance(for: 30), isWandering: true)
        SlimeView(appearance: PetModel.appearance(for: 100),isWandering: true)
    }
    .padding()
    .background(Color(hex: "#F5F5F5"))
}
