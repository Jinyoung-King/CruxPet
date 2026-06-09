import SwiftUI

struct SlimeView: View {
    let appearance: SlimeAppearance
    var isPomodoroActive: Bool = false
    var accessories: [AccessorySlot: String] = [:]
    var isWandering: Bool = false
    var emotion: EmotionState = .normal

    // 배회 시 캔버스를 확장해 클리핑 방지
    private var wanderPad: CGFloat { isWandering ? appearance.size * 0.45 : 0 }
    private var totalWidth:  CGFloat { appearance.size + 32 + wanderPad * 2 }
    private var totalHeight: CGFloat { appearance.size + 40 + wanderPad * 2 }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // ── 감정별 속도 배율 ─────────────────────────────
                let speedMult: Double = emotion == .sleepy ? 0.38 : emotion == .excited ? 1.3 : 1.0
                let bobAmp:  CGFloat  = emotion == .sleepy ? 1.0  : emotion == .excited ? 2.2 : 1.6

                // ── 배회 / 스쿼시 계산 ──────────────────────────────
                let wanderAmp: CGFloat = isWandering ? appearance.size * 0.33 : 0
                let wx: CGFloat = sin(t * 0.55 * speedMult + .pi / 2) * wanderAmp
                let wy: CGFloat = sin(t * 1.10 * speedMult)            * wanderAmp * 0.38

                // 정규화 속도 (-1…1)
                let vxN: CGFloat = cos(t * 0.55 * speedMult + .pi / 2)
                let vyN: CGFloat = cos(t * 1.10 * speedMult)

                let bobY: CGFloat = sin(t * 2.5 * speedMult) * bobAmp + wy

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
                if emotion == .happy || emotion == .excited {
                    drawBlush(context: &tiltCtx, bodyRect: bodyRect,
                              strong: emotion == .excited)
                }
                drawEyes(context: &tiltCtx, bodyRect: bodyRect,
                         lookX: isWandering ? vxN * 0.18 : 0,
                         lookY: isWandering ? vyN * 0.10 : 0,
                         emotion: emotion, t: t)
                if emotion == .sleepy {
                    drawZzz(context: &context, bodyRect: bodyRect, t: t)
                }

                // 왕관 / 반짝이 / 악세서리는 기울기 없이 원래 컨텍스트 사용
                if appearance.crownType != .none {
                    drawCrown(context: &context, bodyRect: bodyRect)
                }
                drawSparkles(context: &context, bodyRect: bodyRect, t: t,
                             count: appearance.sparkleCount)
                drawSlotAccessories(context: &context, bodyRect: bodyRect)
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
                          lookX: CGFloat = 0, lookY: CGFloat = 0,
                          emotion: EmotionState = .normal, t: Double = 0) {
        // 깜빡임 — 3.4s, 6.1s 주기 두 개 조합 (자연스러운 불규칙성)
        let blinkScale: CGFloat
        if emotion == .sleepy {
            blinkScale = 1.0  // sleepy는 자체 눈 처리
        } else {
            let b1 = t.truncatingRemainder(dividingBy: 3.4)
            let b2 = t.truncatingRemainder(dividingBy: 6.1)
            let bt = b1 < 0.18 ? b1 : (b2 < 0.18 ? b2 : -1)
            blinkScale = bt >= 0 ? max(0.05, 1 - sin(bt / 0.18 * .pi)) : 1.0
        }

        let eyeY    = bodyRect.minY + bodyRect.height * 0.37
        let spacing = bodyRect.width * 0.22

        for xOffset in [-spacing, spacing] {
            let cx = bodyRect.midX + xOffset

            switch emotion {
            case .sleepy:
                // 반쯤 감긴 눈 — 납작한 타원
                let slitH = bodyRect.width * 0.05
                let slitW = bodyRect.width * 0.13
                let slitRect = CGRect(x: cx - slitW/2, y: eyeY - slitH/2 + slitH,
                                      width: slitW, height: slitH)
                context.fill(Path(ellipseIn: slitRect), with: .color(Color(white: 0.12)))

            case .excited:
                // 크게 뜬 눈 + 이중 캐치라이트
                let eyeSize = bodyRect.width * 0.155
                let pupilSz = eyeSize * 0.52
                let eyeH = eyeSize * blinkScale
                let whiteRect = CGRect(x: cx - eyeSize/2, y: eyeY - eyeH/2,
                                       width: eyeSize, height: eyeH)
                context.fill(Path(ellipseIn: whiteRect), with: .color(.white))
                let pupilX = cx + eyeSize * lookX
                let pupilY = eyeY - eyeSize * 0.04 + eyeSize * lookY
                let pr = CGRect(x: pupilX - pupilSz/2, y: pupilY - pupilSz/2,
                                width: pupilSz, height: pupilSz)
                context.fill(Path(ellipseIn: pr), with: .color(Color(white: 0.08)))
                // 큰 캐치라이트
                let cs1 = pupilSz * 0.36
                context.fill(Path(ellipseIn: CGRect(x: pupilX - pupilSz*0.02,
                                                     y: pupilY - pupilSz*0.30,
                                                     width: cs1, height: cs1)),
                             with: .color(.white.opacity(0.95)))
                // 작은 캐치라이트
                let cs2 = pupilSz * 0.18
                context.fill(Path(ellipseIn: CGRect(x: pupilX + pupilSz*0.18,
                                                     y: pupilY - pupilSz*0.10,
                                                     width: cs2, height: cs2)),
                             with: .color(.white.opacity(0.75)))

            default:
                // normal / happy — 기본 눈 (happy는 동공이 살짝 위)
                let eyeSize = bodyRect.width * 0.13
                let pupilSz = eyeSize * 0.56
                let eyeH = eyeSize * blinkScale
                let whiteRect = CGRect(x: cx - eyeSize/2, y: eyeY - eyeH/2,
                                       width: eyeSize, height: eyeH)
                context.fill(Path(ellipseIn: whiteRect), with: .color(.white))
                context.fill(Path(ellipseIn: whiteRect), with: .radialGradient(
                    Gradient(colors: [.clear, .black.opacity(0.10)]),
                    center: CGPoint(x: cx, y: eyeY - eyeSize * 0.05),
                    startRadius: eyeSize * 0.25, endRadius: eyeSize * 0.58
                ))
                let happyOffset: CGFloat = emotion == .happy ? -eyeSize * 0.10 : 0
                let pupilX = cx + eyeSize * lookX
                let pupilY = eyeY + eyeSize * 0.07 + eyeSize * lookY + happyOffset
                let pr = CGRect(x: pupilX - pupilSz/2, y: pupilY - pupilSz/2,
                                width: pupilSz, height: pupilSz)
                context.fill(Path(ellipseIn: pr), with: .color(Color(white: 0.08)))
                let cs = pupilSz * 0.32
                context.fill(Path(ellipseIn: CGRect(x: pupilX - pupilSz*0.04,
                                                     y: pupilY - pupilSz*0.28,
                                                     width: cs, height: cs)),
                             with: .color(.white.opacity(0.92)))
            }
        }
    }

    // MARK: - Blush

    private func drawBlush(context: inout GraphicsContext, bodyRect: CGRect, strong: Bool) {
        let blushW = bodyRect.width * 0.16
        let blushH = blushW * 0.55
        let blushY = bodyRect.minY + bodyRect.height * 0.52
        let opacity: Double = strong ? 0.45 : 0.28
        for xOff in [-bodyRect.width * 0.36, bodyRect.width * 0.36] {
            let r = CGRect(x: bodyRect.midX + xOff - blushW/2,
                           y: blushY - blushH/2, width: blushW, height: blushH)
            var ctx = context; ctx.opacity = opacity
            ctx.fill(Path(ellipseIn: r),
                     with: .radialGradient(
                        Gradient(colors: [Color(red: 1, green: 0.35, blue: 0.45), .clear]),
                        center: CGPoint(x: r.midX, y: r.midY),
                        startRadius: 0, endRadius: blushW * 0.6))
        }
    }

    // MARK: - Zzz

    private func drawZzz(context: inout GraphicsContext, bodyRect: CGRect, t: Double) {
        // 두 개의 z가 시간차를 두고 떠오름
        for (offset, size, phaseShift) in [(8.0, 9.0, 0.0), (14.0, 7.0, 0.5)] {
            let phase = (t * 0.4 + phaseShift).truncatingRemainder(dividingBy: 1.0)
            let floatY = bodyRect.minY - 4 - CGFloat(phase * 22)
            let opacity = phase < 0.6 ? phase / 0.6 : (1.0 - phase) / 0.4
            var ctx = context; ctx.opacity = opacity * 0.75
            let z = ctx.resolve(Text("z").font(.system(size: size, weight: .bold, design: .rounded)))
            ctx.draw(z, at: CGPoint(x: bodyRect.midX + CGFloat(offset), y: floatY), anchor: .center)
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

    // MARK: - Accessories

    private func drawSlotAccessories(context: inout GraphicsContext, bodyRect: CGRect) {
        if let emoji = accessories[.head] {
            let size = bodyRect.width * 0.40
            let r = context.resolve(Text(emoji).font(.system(size: size)))
            context.draw(r, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY), anchor: .bottom)
        }
        if let emoji = accessories[.face] {
            let size = bodyRect.width * 0.30
            let r = context.resolve(Text(emoji).font(.system(size: size)))
            context.draw(r, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY + bodyRect.height * 0.3), anchor: .center)
        }
        if let emoji = accessories[.body] {
            let size = bodyRect.width * 0.35
            let r = context.resolve(Text(emoji).font(.system(size: size)))
            context.draw(r, at: CGPoint(x: bodyRect.maxX, y: bodyRect.maxY), anchor: .bottomTrailing)
        }
        if let emoji = accessories[.aura] {
            let size = bodyRect.width * 0.35
            let r = context.resolve(Text(emoji).font(.system(size: size)))
            context.draw(r, at: CGPoint(x: bodyRect.minX, y: bodyRect.maxY), anchor: .bottomLeading)
        }
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
