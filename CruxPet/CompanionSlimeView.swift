import SwiftUI

struct CompanionSlimeView: View {
    let companion: Companion

    private let bodySize: CGFloat = 14
    private var canvasSize: CGFloat { bodySize + 20 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { (_ timeline: TimelineViewDefaultContext) in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let bobY = CGFloat(sin(t * 1.1)) * 1.5
                let bodyRect = CGRect(
                    x: (size.width - bodySize) / 2,
                    y: (size.height - bodySize) / 2 + bobY + 3,
                    width: bodySize,
                    height: bodySize * 0.85
                )

                // 그림자
                let shadowRect = CGRect(
                    x: bodyRect.midX - bodyRect.width * 0.4,
                    y: bodyRect.maxY - 1,
                    width: bodyRect.width * 0.8,
                    height: bodyRect.height * 0.12
                )
                var shadowCtx = context; shadowCtx.opacity = 0.12
                shadowCtx.fill(Path(ellipseIn: shadowRect), with: .color(.black))

                // 몸통
                let color = Color(hex: companion.bodyHex)
                // 외곽선 (fill 전에 그려야 stroke의 내측이 fill로 덮임)
                var outCtx = context; outCtx.opacity = 0.2
                outCtx.stroke(Path(ellipseIn: bodyRect), with: .color(color), lineWidth: bodyRect.width * 0.08)
                context.fill(Path(ellipseIn: bodyRect), with: .color(color))

                // 하이라이트
                let hlRect = CGRect(
                    x: bodyRect.minX + bodyRect.width * 0.15,
                    y: bodyRect.minY + bodyRect.height * 0.08,
                    width: bodyRect.width * 0.3,
                    height: bodyRect.height * 0.22
                )
                var hlCtx = context; hlCtx.opacity = 0.75
                hlCtx.fill(Path(ellipseIn: hlRect), with: .radialGradient(
                    Gradient(colors: [.white, .clear]),
                    center: CGPoint(x: hlRect.midX, y: hlRect.midY),
                    startRadius: 0, endRadius: max(hlRect.width, hlRect.height) * 0.7
                ))

                // 눈 (작은 점 두 개)
                let eyeY = bodyRect.minY + bodyRect.height * 0.40
                let eyeSize: CGFloat = bodyRect.width * 0.13
                for xOff: CGFloat in [-bodyRect.width * 0.20, bodyRect.width * 0.20] {
                    let eyeRect = CGRect(
                        x: bodyRect.midX + xOff - eyeSize / 2,
                        y: eyeY - eyeSize / 2,
                        width: eyeSize, height: eyeSize
                    )
                    context.fill(Path(ellipseIn: eyeRect), with: .color(.black.opacity(0.75)))
                }

                // 아이콘 (슬라임 위)
                let resolved = context.resolve(
                    Text(Image(systemName: companion.sfSymbol))
                        .font(.system(size: 8))
                        .foregroundStyle(Color.primary)
                )
                context.draw(resolved,
                             at: CGPoint(x: size.width / 2, y: bodyRect.minY - 1),
                             anchor: .bottom)
            }
            .frame(width: canvasSize, height: canvasSize)
        }
    }
}

#Preview {
    HStack {
        ForEach(CompanionModel.all) { c in
            CompanionSlimeView(companion: c)
        }
    }
    .padding()
}
