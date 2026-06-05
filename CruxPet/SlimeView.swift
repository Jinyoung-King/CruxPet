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
                let bobY = sin(t * 2.5) * 3

                // 후광 (Lv 80+)
                if appearance.hasHalo {
                    drawHalo(context: &context, center: CGPoint(x: size.width/2, y: size.height/2 - 4 + bobY), radius: appearance.size * 0.7)
                }

                // 슬라임 몸통
                let bodyRect = CGRect(
                    x: (size.width - appearance.size) / 2,
                    y: (size.height - appearance.size) / 2 + bobY,
                    width: appearance.size,
                    height: appearance.size * 0.85
                )
                drawBody(context: &context, rect: bodyRect, t: t)

                // 눈
                drawEyes(context: &context, bodyRect: bodyRect)

                // 왕관
                if appearance.crownType != .none {
                    drawCrown(context: &context, bodyRect: bodyRect)
                }

                // 반짝이
                drawSparkles(context: &context, bodyRect: bodyRect, t: t, count: appearance.sparkleCount)

                // 악세서리 (왕관 오른쪽 위)
                if !accessory.isEmpty {
                    drawAccessory(context: &context, bodyRect: bodyRect)
                }
            }
            .frame(width: totalWidth, height: totalHeight)
        }
    }

    private func drawBody(context: inout GraphicsContext, rect: CGRect, t: Double) {
        // 포모도로 진행 중엔 🍅 오버레이
        if isPomodoroActive {
            let tomato = context.resolve(Text("🍅").font(.system(size: rect.width * 0.9)))
            context.draw(tomato, at: CGPoint(x: rect.midX, y: rect.midY), anchor: .center)
            return
        }
        let path = Path(roundedRect: rect, cornerRadius: rect.width * 0.4)
        let bodyColor: Color
        if appearance.isRainbow {
            let hue = (t * 0.2).truncatingRemainder(dividingBy: 1.0)
            bodyColor = Color(hue: hue, saturation: 0.8, brightness: 0.9)
        } else {
            bodyColor = Color(hex: appearance.bodyHex)
        }
        context.fill(path, with: .color(bodyColor))
        let shadowRect = CGRect(x: rect.minX + 2, y: rect.maxY - 6, width: rect.width - 4, height: 6)
        let shadowPath = Path(roundedRect: shadowRect, cornerRadius: 3)
        context.fill(shadowPath, with: .color(bodyColor.opacity(0.5)))

        if appearance.isPearl {
            let highlightRect = CGRect(x: rect.minX + rect.width * 0.2, y: rect.minY + rect.height * 0.1, width: rect.width * 0.25, height: rect.height * 0.2)
            let highlightPath = Path(ellipseIn: highlightRect)
            context.fill(highlightPath, with: .color(Color.white.opacity(0.6 + 0.3 * sin(t * 4))))
        }
    }

    private func drawEyes(context: inout GraphicsContext, bodyRect: CGRect) {
        let eyeY = bodyRect.minY + bodyRect.height * 0.35
        let eyeSize = bodyRect.width * 0.12
        let pupilSize = eyeSize * 0.6
        let spacing = bodyRect.width * 0.22

        for xOffset in [-spacing, spacing] {
            let cx = bodyRect.midX + xOffset
            let white = Path(ellipseIn: CGRect(x: cx - eyeSize/2, y: eyeY - eyeSize/2, width: eyeSize, height: eyeSize))
            context.fill(white, with: .color(.white))
            let black = Path(ellipseIn: CGRect(x: cx - pupilSize/2, y: eyeY - pupilSize/2 + 1, width: pupilSize, height: pupilSize))
            context.fill(black, with: .color(.black))
        }
    }

    private func drawCrown(context: inout GraphicsContext, bodyRect: CGRect) {
        let text = context.resolve(Text(appearance.crownType.symbol).font(.system(size: bodyRect.width * 0.45)))
        let textSize = text.measure(in: CGSize(width: 100, height: 100))
        context.draw(text, at: CGPoint(x: bodyRect.midX, y: bodyRect.minY - textSize.height * 0.3))
    }

    private func drawHalo(context: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let haloPath = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius * 0.3, width: radius * 2, height: radius * 0.6))
        context.stroke(haloPath, with: .color(Color.yellow.opacity(0.6)), lineWidth: 2)
    }

    private func drawSparkles(context: inout GraphicsContext, bodyRect: CGRect, t: Double, count: Int) {
        guard count > 0 else { return }
        let positions: [(Double, Double)] = [
            (-1.1, -0.6), (1.1, -0.4), (-0.9, 0.4), (1.0, 0.6),
            (-1.3, 0.0), (1.3, 0.1), (-0.7, -1.0), (0.8, -0.9),
            (-1.2, 0.9), (1.1, 1.0)
        ]
        for i in 0..<min(count, positions.count) {
            let (dx, dy) = positions[i]
            let x = bodyRect.midX + CGFloat(dx) * bodyRect.width * 0.65
            let y = bodyRect.midY + CGFloat(dy) * bodyRect.height * 0.65
            let phase = Double(i) * 0.7
            let alpha = 0.4 + 0.6 * abs(sin(t * 3 + phase))
            var sparkleContext = context
            sparkleContext.opacity = alpha
            let sparkle = sparkleContext.resolve(Text("✦").font(.system(size: 8)))
            sparkleContext.draw(sparkle, at: CGPoint(x: x, y: y), anchor: .center)
        }
    }

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
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
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
}
