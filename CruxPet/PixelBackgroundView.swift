import SwiftUI

struct PixelBackgroundView: View {
    private let px: CGFloat = 4

    var body: some View {
        TimelineView(.animation) { tl in
            Canvas { context, size in
                var ctx = context
                let t = tl.date.timeIntervalSinceReferenceDate
                draw(&ctx, size: size, t: t)
            }
        }
    }

    private func draw(_ ctx: inout GraphicsContext, size: CGSize, t: Double) {
        let skyEndY    = floor(size.height * 0.65 / px) * px
        let dirtStartY = floor(size.height * 0.85 / px) * px

        // Sky
        ctx.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: skyEndY)),
                 with: .color(Color(hex: "#92C8E8")))

        // Grass top highlight row
        ctx.fill(Path(CGRect(x: 0, y: skyEndY, width: size.width, height: px * 2)),
                 with: .color(Color(hex: "#7EC850")))

        // Grass fill
        ctx.fill(Path(CGRect(x: 0, y: skyEndY + px * 2,
                             width: size.width,
                             height: dirtStartY - skyEndY - px * 2)),
                 with: .color(Color(hex: "#5BA832")))

        // Dirt
        ctx.fill(Path(CGRect(x: 0, y: dirtStartY,
                             width: size.width,
                             height: size.height - dirtStartY)),
                 with: .color(Color(hex: "#8B5E3C")))

        // Cloud A: 12 blocks wide, speed 12, y at row 4
        drawCloud(&ctx, size: size, t: t,
                  bodyW: 12, bumpW: 6, speed: 12, yBlock: 4, phase: 0)

        // Cloud B: 10 blocks wide, speed 7, y at row 8, starts further right
        drawCloud(&ctx, size: size, t: t,
                  bodyW: 10, bumpW: 5, speed: 7, yBlock: 8, phase: size.width * 0.55)
    }

    private func drawCloud(_ ctx: inout GraphicsContext, size: CGSize, t: Double,
                           bodyW: Int, bumpW: Int,
                           speed: Double, yBlock: CGFloat, phase: CGFloat) {
        let cloudW = CGFloat(bodyW) * px
        let total  = size.width + cloudW
        let x = (CGFloat(t * speed) + phase).truncatingRemainder(dividingBy: total) - cloudW
        let y = yBlock * px

        // Main body (2 blocks tall)
        ctx.fill(Path(CGRect(x: x, y: y, width: cloudW, height: px * 2)),
                 with: .color(Color.white.opacity(0.88)))

        // Bump on top (1 block tall, centered)
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
