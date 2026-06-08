import SwiftUI

struct SlimeView: View {
    let appearance: SlimeAppearance
    var isPomodoroActive: Bool = false
    var accessory: String = ""

    private var totalWidth: CGFloat { appearance.size + 32 }
    private var totalHeight: CGFloat { appearance.size + 40 }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let bobY: CGFloat = sin(t * 2.5) * 3

                if appearance.hasHalo {
                    drawHalo(context: &context,
                             center: CGPoint(x: size.width/2, y: size.height/2 - 4 + bobY),
                             radius: appearance.size * 0.7)
                }

                let bodyRect = CGRect(
                    x: (size.width - appearance.size) / 2,
                    y: (size.height - appearance.size) / 2 + bobY,
                    width: appearance.size,
                    height: appearance.size * 0.85
                )

                drawContactShadow(context: &context, rect: bodyRect)
                drawBody(context: &context, rect: bodyRect, t: t)
                drawEyes(context: &context, bodyRect: bodyRect)

                if appearance.crownType != .none {
                    drawCrown(context: &context, bodyRect: bodyRect)
                }
                drawSparkles(context: &context, bodyRect: bodyRect, t: t, count: appearance.sparkleCount)
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

        let path = Path(roundedRect: rect, cornerRadius: rect.width * 0.4)
        let bodyColor: Color
        if appearance.isRainbow {
            let hue = (t * 0.2).truncatingRemainder(dividingBy: 1.0)
            bodyColor = Color(hue: hue, saturation: 0.75, brightness: 0.92)
        } else {
            bodyColor = Color(hex: appearance.bodyHex)
        }

        // 1. 기본 몸통
        context.fill(path, with: .color(bodyColor))

        // 2. 조명 효과: 좌상단에서 오는 빛 (radial gradient 오버레이)
        let lightCenter = CGPoint(x: rect.minX + rect.width * 0.32, y: rect.minY + rect.height * 0.22)
        context.fill(path, with: .radialGradient(
            Gradient(stops: [
                .init(color: .white.opacity(0.40), location: 0.0),
                .init(color: .white.opacity(0.10), location: 0.45),
                .init(color: .clear,               location: 1.0),
            ]),
            center: lightCenter,
            startRadius: 0,
            endRadius: rect.width * 0.85
        ))

        // 3. 하단 어둠 (음영)
        context.fill(path, with: .linearGradient(
            Gradient(colors: [.clear, .black.opacity(0.16)]),
            startPoint: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.3),
            endPoint:   CGPoint(x: rect.midX, y: rect.maxY)
        ))

        // 4. 광택 스팟 (specular highlight)
        let specRect = CGRect(
            x: rect.minX + rect.width * 0.17,
            y: rect.minY + rect.height * 0.07,
            width:  rect.width  * 0.28,
            height: rect.height * 0.18
        )
        var specCtx = context
        specCtx.opacity = 0.65
        specCtx.fill(Path(ellipseIn: specRect), with: .radialGradient(
            Gradient(colors: [.white, .clear]),
            center: CGPoint(x: specRect.midX, y: specRect.midY),
            startRadius: 0,
            endRadius: max(specRect.width, specRect.height) * 0.6
        ))

        // 5. 하단 림라이트 (바닥 반사광)
        let rimRect = CGRect(
            x: rect.minX + rect.width * 0.2,
            y: rect.maxY - rect.height * 0.18,
            width:  rect.width  * 0.6,
            height: rect.height * 0.18
        )
        var rimCtx = context
        rimCtx.opacity = 0.18
        rimCtx.fill(
            Path(roundedRect: rimRect, cornerRadius: rimRect.height / 2),
            with: .linearGradient(
                Gradient(colors: [.clear, .white.opacity(0.5)]),
                startPoint: CGPoint(x: rimRect.midX, y: rimRect.minY),
                endPoint:   CGPoint(x: rimRect.midX, y: rimRect.maxY)
            )
        )

        // 6. 펄 광채 (isPearl)
        if appearance.isPearl {
            var pearlCtx = context
            pearlCtx.opacity = 0.25 + 0.2 * sin(t * 4)
            pearlCtx.fill(path, with: .linearGradient(
                Gradient(colors: [
                    Color(hue: (t * 0.1).truncatingRemainder(dividingBy: 1.0),
                          saturation: 0.5, brightness: 1.0).opacity(0.6),
                    .clear
                ]),
                startPoint: CGPoint(x: rect.maxX, y: rect.minY),
                endPoint:   CGPoint(x: rect.minX, y: rect.maxY)
            ))
        }
    }

    // MARK: - Contact Shadow

    private func drawContactShadow(context: inout GraphicsContext, rect: CGRect) {
        let cx  = rect.midX
        let y   = rect.maxY - 1
        let w   = rect.width * 0.82
        let h   = rect.height * 0.14
        // 바깥→안으로 점점 진해지는 3겹
        for (ws, hs, op) in [(1.5, 1.8, 0.05), (1.1, 1.3, 0.08), (0.7, 0.9, 0.11)] as [(Double,Double,Double)] {
            let sr = CGRect(x: cx - w * ws / 2, y: y - h * hs / 2,
                            width: w * ws, height: h * hs)
            var ctx = context
            ctx.opacity = op
            ctx.fill(Path(ellipseIn: sr), with: .color(.black))
        }
    }

    // MARK: - Eyes

    private func drawEyes(context: inout GraphicsContext, bodyRect: CGRect) {
        let eyeY    = bodyRect.minY + bodyRect.height * 0.37
        let eyeSize = bodyRect.width * 0.13
        let pupilSz = eyeSize * 0.56
        let spacing = bodyRect.width * 0.22

        for xOffset in [-spacing, spacing] {
            let cx = bodyRect.midX + xOffset

            // 흰자
            let whiteRect = CGRect(x: cx - eyeSize/2, y: eyeY - eyeSize/2,
                                   width: eyeSize, height: eyeSize)
            context.fill(Path(ellipseIn: whiteRect), with: .color(.white))

            // 흰자 하단 미세 음영
            context.fill(Path(ellipseIn: whiteRect), with: .radialGradient(
                Gradient(colors: [.clear, .black.opacity(0.10)]),
                center: CGPoint(x: cx, y: eyeY - eyeSize * 0.05),
                startRadius: eyeSize * 0.25,
                endRadius:   eyeSize * 0.58
            ))

            // 동공 (약간 아래)
            let pupilY = eyeY + eyeSize * 0.07
            let pupilRect = CGRect(x: cx - pupilSz/2, y: pupilY - pupilSz/2,
                                   width: pupilSz, height: pupilSz)
            context.fill(Path(ellipseIn: pupilRect), with: .color(Color(white: 0.08)))

            // 캐치라이트 (반짝임)
            let catchSz = pupilSz * 0.32
            let catchRect = CGRect(x: cx - pupilSz * 0.04, y: pupilY - pupilSz * 0.28,
                                   width: catchSz, height: catchSz)
            context.fill(Path(ellipseIn: catchRect), with: .color(.white.opacity(0.92)))
        }
    }

    // MARK: - Crown

    private func drawCrown(context: inout GraphicsContext, bodyRect: CGRect) {
        let text = context.resolve(Text(appearance.crownType.symbol)
            .font(.system(size: bodyRect.width * 0.45)))
        let textSize = text.measure(in: CGSize(width: 100, height: 100))
        context.draw(text, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY - textSize.height * 0.3))
    }

    // MARK: - Halo

    private func drawHalo(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let rect = CGRect(x: center.x - radius, y: center.y - radius * 0.3,
                          width: radius * 2, height: radius * 0.6)
        let path = Path(ellipseIn: rect)
        // 겹치는 글로우 레이어
        for (lw, op) in [(7.0, 0.07), (4.5, 0.14), (2.5, 0.35), (1.5, 0.65)] as [(Double, Double)] {
            var ctx = context
            ctx.stroke(path, with: .color(Color.yellow.opacity(op)), lineWidth: lw)
        }
    }

    // MARK: - Sparkles

    private func drawSparkles(context: inout GraphicsContext, bodyRect: CGRect, t: Double, count: Int) {
        guard count > 0 else { return }
        let positions: [(Double, Double)] = [
            (-1.1, -0.6), (1.1, -0.4), (-0.9, 0.4), (1.0, 0.6),
            (-1.3, 0.0),  (1.3, 0.1),  (-0.7, -1.0), (0.8, -0.9),
            (-1.2, 0.9),  (1.1, 1.0)
        ]
        for i in 0..<min(count, positions.count) {
            let (dx, dy) = positions[i]
            let x = bodyRect.midX + CGFloat(dx) * bodyRect.width * 0.65
            let y = bodyRect.midY + CGFloat(dy) * bodyRect.height * 0.65
            let phase = Double(i) * 0.7
            let alpha = 0.4 + 0.6 * abs(sin(t * 3 + phase))
            let scale = 0.7 + 0.4 * abs(sin(t * 2.5 + phase + 1.0))
            var ctx = context
            ctx.opacity = alpha
            let sparkle = ctx.resolve(Text("✦").font(.system(size: 8 * scale)))
            ctx.draw(sparkle, at: CGPoint(x: x, y: y), anchor: .center)
        }
    }

    // MARK: - Accessory

    private func drawAccessory(context: inout GraphicsContext, bodyRect: CGRect) {
        let size = bodyRect.width * 0.38
        let resolved = context.resolve(Text(accessory).font(.system(size: size)))
        let x = bodyRect.maxX - size * 0.1
        let y = bodyRect.minY - size * 0.1
        context.draw(resolved, at: CGPoint(x: x, y: y), anchor: .bottomTrailing)
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
        SlimeView(appearance: PetModel.appearance(for: 1))
        SlimeView(appearance: PetModel.appearance(for: 10))
        SlimeView(appearance: PetModel.appearance(for: 30))
        SlimeView(appearance: PetModel.appearance(for: 100))
    }
    .padding()
    .background(Color(hex: "#F5F5F5"))
}
