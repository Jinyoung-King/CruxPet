import SwiftUI

struct PixelBackgroundView: View {
    private let px: CGFloat = 4

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { context, size in
                var ctx = context
                let t   = tl.date.timeIntervalSinceReferenceDate
                draw(&ctx, size: size, t: t)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let skyEndY    = floor(size.height * 0.65 / px) * px
        let dirtStartY = floor(size.height * 0.85 / px) * px

        ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: skyEndY)),
                 with: .color(Color(hex: "#92C8E8")))
        ctx.fill(Path(CGRect(x: 0, y: skyEndY, width: size.width, height: px * 2)),
                 with: .color(Color(hex: "#7EC850")))
        ctx.fill(Path(CGRect(x: 0, y: skyEndY + px * 2,
                             width: size.width,
                             height: dirtStartY - skyEndY - px * 2)),
                 with: .color(Color(hex: "#5BA832")))
        ctx.fill(Path(CGRect(x: 0, y: dirtStartY,
                             width: size.width,
                             height: size.height - dirtStartY)),
                 with: .color(Color(hex: "#8B5E3C")))

        drawCloud(&ctx, size: size, t: t, bodyW: 12, speed: 12, yBlock: 4, phase: 0)
        drawCloud(&ctx, size: size, t: t, bodyW: 10, speed: 7,  yBlock: 8, phase: 120)
    }

    private func drawCloud(_ ctx: inout GraphicsContext, size: CGSize, t: Double,
                           bodyW: Int, speed: Double, yBlock: CGFloat, phase: CGFloat) {
        let cloudW = CGFloat(bodyW) * px
        let bumpW  = bodyW / 2
        let total  = size.width + cloudW
        let x = (CGFloat(t * speed) + phase).truncatingRemainder(dividingBy: total) - cloudW
        let y = yBlock * px

        ctx.fill(Path(CGRect(x: x, y: y, width: cloudW, height: px * 2)),
                 with: .color(Color.white.opacity(0.88)))

        let bumpX = x + (cloudW - CGFloat(bumpW) * px) / 2
        ctx.fill(Path(CGRect(x: bumpX, y: y - px, width: CGFloat(bumpW) * px, height: px)),
                 with: .color(Color.white.opacity(0.88)))
    }
}

#Preview {
    PixelBackgroundView()
        .frame(width: 220, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8))
}
