import SwiftUI

struct SlimeView: View {
    let appearance: SlimeAppearance
    var isPomodoroActive: Bool = false
    var isWandering: Bool = false
    var emotion: EmotionState = .normal

    // 배회 시 캔버스를 확장해 클리핑 방지
    private var wanderPad: CGFloat { appearance.size * 0.60 }
    private var totalWidth:  CGFloat { appearance.size + 32 + wanderPad * 2 }
    private var totalHeight: CGFloat { appearance.size + 40 + wanderPad * 2 }

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate

                // ── 감정별 속도 배율 ─────────────────────────────
                let speedMult: Double = emotion == .sleepy ? 0.38 : emotion == .excited ? 1.3 : 1.0
                let bobAmp:  CGFloat  = emotion == .sleepy ? 1.0  : emotion == .excited ? 2.2 : 1.6

                // ── 수평 이동 ────────────────────────────────────────
                let wanderAmp: CGFloat = isWandering ? appearance.size * 0.33 : 0
                let wx: CGFloat = sin(t * 0.45 * speedMult) * wanderAmp
                let vxN: CGFloat = cos(t * 0.45 * speedMult)

                // ── 점프 ─────────────────────────────────────────────
                let jumpPeriod: Double = 3.2 / speedMult
                let jumpDuration: Double = 0.7
                let jumpHeight: CGFloat = isWandering ? appearance.size * 0.55 : 0
                let jumpPhase = t.truncatingRemainder(dividingBy: jumpPeriod)
                let inAir = isWandering && emotion != .sleepy && jumpPhase < jumpDuration
                let jumpFrac: Double = inAir ? jumpPhase / jumpDuration : 0
                let jumpArc: CGFloat = inAir ? -sin(CGFloat(jumpFrac) * .pi) * jumpHeight : 0

                // 착지 직후 squash (0.3초간 페이드)
                let afterLand: Double = inAir ? 0 : min(jumpPhase - jumpDuration, 0.3)
                let landSquash: CGFloat = isWandering ? CGFloat(max(0, 1.0 - afterLand / 0.3)) : 0

                // 공중이 아닐 때만 bob
                let bobY: CGFloat = (inAir ? 0 : sin(t * 2.5 * speedMult) * bobAmp) + jumpArc

                // ── 스쿼시/스트레치 ──────────────────────────────────
                let peakFrac: CGFloat = inAir ? CGFloat(sin(jumpFrac * .pi)) : 0
                let hStretch: CGFloat = inAir
                    ? 1 - peakFrac * 0.05
                    : 1 + landSquash * 0.18 + abs(vxN) * (isWandering ? 0.06 : 0)
                let vSquish: CGFloat = inAir
                    ? 1 + peakFrac * 0.08
                    : 1 - landSquash * 0.12 - abs(vxN) * (isWandering ? 0.04 : 0)

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

                drawContactShadow(context: &context, rect: bodyRect, jumpArc: jumpArc)

                // ── 기울기 컨텍스트 (몸통+눈만 적용) ───────────────
                var tiltCtx = context
                if isWandering {
                    let tiltRad = vxN * 0.10   // 최대 ±5.7°
                    tiltCtx.translateBy(x: bodyRect.midX, y: bodyRect.midY)
                    tiltCtx.rotate(by: .radians(Double(tiltRad)))
                    tiltCtx.translateBy(x: -bodyRect.midX, y: -bodyRect.midY)
                }

                drawBody(context: &tiltCtx, rect: bodyRect, t: t)
                drawDrip(context: &tiltCtx, bodyRect: bodyRect, t: t)
                if emotion == .happy || emotion == .excited {
                    drawBlush(context: &tiltCtx, bodyRect: bodyRect,
                              strong: emotion == .excited)
                }
                let eyeLookY: CGFloat = (isWandering && inAir)
                    ? -CGFloat(cos(jumpFrac * .pi)) * 0.12
                    : 0
                drawEyes(context: &tiltCtx, bodyRect: bodyRect,
                         lookX: isWandering ? vxN * 0.18 : 0,
                         lookY: eyeLookY,
                         emotion: emotion, t: t)
                drawEyebrows(context: &tiltCtx, bodyRect: bodyRect, emotion: emotion)
                drawMouth(context: &tiltCtx, bodyRect: bodyRect, emotion: emotion)
                if emotion == .sleepy {
                    drawZzz(context: &context, bodyRect: bodyRect, t: t)
                }

                // 왕관 / 반짝이 / 악세서리는 기울기 없이 원래 컨텍스트 사용
                if appearance.crownType != .none {
                    drawCrown(context: &context, bodyRect: bodyRect)
                }
                drawSparkles(context: &context, bodyRect: bodyRect, t: t,
                             count: appearance.sparkleCount)
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

    private func drawContactShadow(context: inout GraphicsContext, rect: CGRect, jumpArc: CGFloat = 0) {
        let cx = rect.midX
        let groundY = rect.maxY - jumpArc - 1
        let heightRatio: CGFloat = jumpArc != 0 ? max(0.3, 1 - abs(jumpArc) / (rect.height * 2.5)) : 1
        let w = rect.width * 0.82 * heightRatio
        let h = rect.height * 0.14
        for (ws, hs, op): (Double, Double, Double) in [(1.5,1.8,0.05),(1.1,1.3,0.08),(0.7,0.9,0.11)] {
            let sr = CGRect(x: cx - w*ws/2, y: groundY - h*hs/2, width: w*ws, height: h*hs)
            var ctx = context; ctx.opacity = op * Double(heightRatio)
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

    // MARK: - Eyebrows

    private func drawEyebrows(context: inout GraphicsContext, bodyRect: CGRect, emotion: EmotionState) {
        guard !isPomodoroActive else { return }
        let eyeY    = bodyRect.minY + bodyRect.height * 0.37
        let spacing = bodyRect.width * 0.22
        let browW   = bodyRect.width * 0.11
        let sw      = max(1.0, bodyRect.width * 0.026)
        let color   = Color(white: 0.18).opacity(0.55)
        let s       = bodyRect.width

        // (centerYOffset, leftEndDelta, rightEndDelta) for left brow, then right brow
        let (lSpec, rSpec): ((CGFloat, CGFloat, CGFloat), (CGFloat, CGFloat, CGFloat))
        switch emotion {
        case .sleepy:
            lSpec = ( s*0.03,  s*0.02, -s*0.01)
            rSpec = ( s*0.03, -s*0.01,  s*0.02)
        case .happy:
            lSpec = (-s*0.09,  s*0.02, -s*0.03)
            rSpec = (-s*0.09, -s*0.03,  s*0.02)
        case .excited:
            lSpec = (-s*0.13,  s*0.03, -s*0.05)
            rSpec = (-s*0.13, -s*0.05,  s*0.03)
        default:
            // 왼쪽 눈썹만 더 올라가고 기울어짐 → 멍청한 의아한 표정
            lSpec = (-s*0.11,  s*0.03, -s*0.05)
            rSpec = (-s*0.04,  s*0.01,  s*0.01)
        }

        for (i, spec) in [lSpec, rSpec].enumerated() {
            let (centerOff, leftDelta, rightDelta) = spec
            let cx = bodyRect.midX + (i == 0 ? -spacing : spacing)
            let cy = eyeY + centerOff
            var path = Path()
            path.move(to: CGPoint(x: cx - browW/2, y: cy + leftDelta))
            path.addQuadCurve(
                to:      CGPoint(x: cx + browW/2, y: cy + rightDelta),
                control: CGPoint(x: cx,           y: cy - s * 0.012)
            )
            context.stroke(path, with: .color(color), lineWidth: sw)
        }
    }

    // MARK: - Mouth

    private func drawMouth(context: inout GraphicsContext, bodyRect: CGRect, emotion: EmotionState) {
        guard !isPomodoroActive else { return }
        let cx     = bodyRect.midX + bodyRect.width * 0.025
        let mouthY = bodyRect.minY + bodyRect.height * 0.60
        let sw     = max(1.0, bodyRect.width * 0.028)
        let color  = Color(white: 0.12).opacity(0.70)

        var path = Path()
        switch emotion {
        case .sleepy:
            let w = bodyRect.width * 0.14
            path.move(to: CGPoint(x: cx - w/2, y: mouthY))
            path.addQuadCurve(
                to:      CGPoint(x: cx + w/2, y: mouthY + w*0.09),
                control: CGPoint(x: cx + w*0.1, y: mouthY + w*0.18)
            )
            context.stroke(path, with: .color(color), lineWidth: sw)

        case .happy:
            let w = bodyRect.width * 0.22
            path.move(to: CGPoint(x: cx - w/2, y: mouthY - w*0.04))
            path.addQuadCurve(
                to:      CGPoint(x: cx + w/2, y: mouthY - w*0.04),
                control: CGPoint(x: cx,       y: mouthY + w*0.40)
            )
            context.stroke(path, with: .color(color), lineWidth: sw)

        case .excited:
            let r = bodyRect.width * 0.12
            path.addArc(center: CGPoint(x: cx, y: mouthY),
                        radius: r,
                        startAngle: .degrees(10),
                        endAngle:   .degrees(170),
                        clockwise:  false)
            context.stroke(path, with: .color(color), lineWidth: sw * 1.15)

        default:
            // 멍청한 기본: 살짝 벌어진 반원
            let r = bodyRect.width * 0.08
            path.addArc(center: CGPoint(x: cx, y: mouthY),
                        radius: r,
                        startAngle: .degrees(15),
                        endAngle:   .degrees(165),
                        clockwise:  false)
            context.stroke(path, with: .color(color), lineWidth: sw)
        }
    }

    // MARK: - Drip

    private func drawDrip(context: inout GraphicsContext, bodyRect: CGRect, t: Double) {
        guard !isPomodoroActive else { return }
        let dripX   = bodyRect.midX - bodyRect.width * 0.09
        let dripTop = bodyRect.maxY - bodyRect.height * 0.09
        let dripLen = bodyRect.height * 0.20 + sin(t * 1.1) * bodyRect.height * 0.04
        let dripW   = bodyRect.width * 0.075

        let tip   = CGPoint(x: dripX, y: dripTop + dripLen)
        let left  = CGPoint(x: dripX - dripW/2, y: dripTop + dripLen * 0.28)
        let right = CGPoint(x: dripX + dripW/2, y: dripTop + dripLen * 0.28)

        var path = Path()
        path.move(to: left)
        path.addQuadCurve(to: right,
                          control: CGPoint(x: dripX, y: dripTop - dripW * 0.15))
        path.addQuadCurve(to: tip,
                          control: CGPoint(x: dripX + dripW * 0.32, y: dripTop + dripLen * 0.82))
        path.addQuadCurve(to: left,
                          control: CGPoint(x: dripX - dripW * 0.32, y: dripTop + dripLen * 0.82))
        path.closeSubpath()

        let baseColor: Color = appearance.isRainbow
            ? Color(hue: (t * 0.2).truncatingRemainder(dividingBy: 1.0), saturation: 0.75, brightness: 0.92)
            : Color(hex: appearance.bodyHex)

        context.fill(path, with: .color(baseColor))
        var hlCtx = context; hlCtx.opacity = 0.42
        let hlR = CGRect(x: dripX - dripW * 0.14, y: dripTop + dripLen * 0.10,
                         width: dripW * 0.30, height: dripLen * 0.20)
        hlCtx.fill(Path(ellipseIn: hlR), with: .color(.white))
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
