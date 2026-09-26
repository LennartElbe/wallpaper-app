import AppKit

enum ShapeKind: CaseIterable {
    case circle
    case ring
    case triangle
    case hexagon
    case square
}

struct WallpaperRenderer {
    let size: CGSize
    let time: TimeContext
    let battery: BatteryContext
    let weather: WeatherContext?

    /// Renders directly into a pixel-sized bitmap context (rather than
    /// NSImage.lockFocus, which defaults to 1x) so the wallpaper is sharp on
    /// Retina displays. `size` is expected to already be in device pixels.
    func render() -> CGImage? {
        let width = Int(size.width)
        let height = Int(size.height)
        guard width > 0, height > 0 else { return nil }

        guard let ctx = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        let palette = adjustedPalette()
        drawBackground(ctx, palette: palette)
        drawShapes(ctx, palette: palette)
        drawWeatherOverlay(ctx)

        return ctx.makeImage()
    }

    // MARK: - Palette adjustment

    private func adjustedPalette() -> PhasePalette {
        var palette = Palette.palette(forHour: time.hour)

        var saturationScale: CGFloat = 1
        var brightnessScale: CGFloat = 1

        switch weather?.mood {
        case .cloudy, .fog:
            saturationScale = 0.6
            brightnessScale = 0.9
        case .rain, .drizzle:
            saturationScale = 0.65
            brightnessScale = 0.8
        case .thunderstorm:
            saturationScale = 0.55
            brightnessScale = 0.65
        case .snow:
            saturationScale = 0.75
            brightnessScale = 1.05
        case .clear, .none:
            saturationScale = 1.05
            brightnessScale = 1.0
        }

        palette = PhasePalette(
            backgroundTop: palette.backgroundTop.adjusted(saturationScale: saturationScale, brightnessScale: brightnessScale),
            backgroundBottom: palette.backgroundBottom.adjusted(saturationScale: saturationScale, brightnessScale: brightnessScale),
            accents: palette.accents.map { $0.adjusted(saturationScale: saturationScale, brightnessScale: brightnessScale) }
        )

        return palette
    }

    // MARK: - Background

    private func drawBackground(_ ctx: CGContext, palette: PhasePalette) {
        let colors = [palette.backgroundTop.cgColor, palette.backgroundBottom.cgColor] as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
        ctx.drawLinearGradient(
            gradient,
            start: CGPoint(x: size.width / 2, y: size.height),
            end: CGPoint(x: size.width / 2, y: 0),
            options: []
        )
    }

    // MARK: - Shapes

    private func drawShapes(_ ctx: CGContext, palette: PhasePalette) {
        let energy = battery.energy
        let shapeCount = Int(28 + energy * 110)
        let minDimension = min(size.width, size.height)

        // Big, soft, translucent shapes first for depth, then smaller crisper ones on top.
        for pass in 0..<2 {
            let countForPass = pass == 0 ? shapeCount / 3 : shapeCount - shapeCount / 3
            for _ in 0..<countForPass {
                let kind = ShapeKind.allCases.randomElement()!
                let color = palette.accents.randomElement()!

                let sizeFraction: CGFloat = pass == 0
                    ? CGFloat.random(in: 0.18...0.42)
                    : CGFloat.random(in: 0.04...0.16)
                let shapeSize = minDimension * sizeFraction

                let alpha: CGFloat = pass == 0
                    ? CGFloat.random(in: 0.08...0.22)
                    : CGFloat.random(in: 0.20...0.55) * (0.6 + 0.4 * energy)

                let center = CGPoint(
                    x: CGFloat.random(in: -shapeSize * 0.3...(size.width + shapeSize * 0.3)),
                    y: CGFloat.random(in: -shapeSize * 0.3...(size.height + shapeSize * 0.3))
                )
                let rotation = CGFloat.random(in: 0...(2 * .pi))

                draw(kind: kind, center: center, size: shapeSize, rotation: rotation, color: color.withAlphaComponent(alpha), in: ctx)
            }
        }
    }

    private func draw(kind: ShapeKind, center: CGPoint, size shapeSize: CGFloat, rotation: CGFloat, color: NSColor, in ctx: CGContext) {
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: rotation)
        ctx.setFillColor(color.cgColor)
        ctx.setStrokeColor(color.cgColor)

        let r = shapeSize / 2
        switch kind {
        case .circle:
            ctx.addEllipse(in: CGRect(x: -r, y: -r, width: shapeSize, height: shapeSize))
            ctx.fillPath()
        case .ring:
            ctx.setLineWidth(max(2, shapeSize * 0.08))
            ctx.addEllipse(in: CGRect(x: -r, y: -r, width: shapeSize, height: shapeSize))
            ctx.strokePath()
        case .square:
            ctx.addRect(CGRect(x: -r, y: -r, width: shapeSize, height: shapeSize))
            ctx.fillPath()
        case .triangle:
            addRegularPolygon(ctx, sides: 3, radius: r)
            ctx.fillPath()
        case .hexagon:
            addRegularPolygon(ctx, sides: 6, radius: r)
            ctx.fillPath()
        }
        ctx.restoreGState()
    }

    private func addRegularPolygon(_ ctx: CGContext, sides: Int, radius: CGFloat) {
        let angleStep = (2 * CGFloat.pi) / CGFloat(sides)
        ctx.beginPath()
        for i in 0..<sides {
            let angle = angleStep * CGFloat(i) - .pi / 2
            let point = CGPoint(x: radius * cos(angle), y: radius * sin(angle))
            if i == 0 {
                ctx.move(to: point)
            } else {
                ctx.addLine(to: point)
            }
        }
        ctx.closePath()
    }

    // MARK: - Weather overlays

    private func drawWeatherOverlay(_ ctx: CGContext) {
        guard let mood = weather?.mood else { return }

        switch mood {
        case .rain, .drizzle, .thunderstorm:
            drawRain(ctx, intensity: mood == .drizzle ? 0.5 : (mood == .thunderstorm ? 1.3 : 1.0))
            if mood == .thunderstorm {
                drawLightningBolts(ctx)
            }
        case .snow:
            drawSnow(ctx)
        case .fog:
            drawFog(ctx)
        case .clear, .cloudy:
            break
        }
    }

    private func drawRain(_ ctx: CGContext, intensity: Double) {
        let dropCount = Int(140 * intensity)
        ctx.saveGState()
        ctx.setLineCap(.round)
        for _ in 0..<dropCount {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let length = CGFloat.random(in: 20...60)
            let width = CGFloat.random(in: 1...2.5)
            let alpha = CGFloat.random(in: 0.10...0.30)

            ctx.setStrokeColor(NSColor.white.withAlphaComponent(alpha).cgColor)
            ctx.setLineWidth(width)
            ctx.move(to: CGPoint(x: x, y: y))
            // Slight diagonal for a wind-blown look.
            ctx.addLine(to: CGPoint(x: x - length * 0.25, y: y - length))
            ctx.strokePath()
        }
        ctx.restoreGState()
    }

    private func drawSnow(_ ctx: CGContext) {
        ctx.saveGState()
        for _ in 0..<220 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let r = CGFloat.random(in: 1.5...4.5)
            let alpha = CGFloat.random(in: 0.25...0.7)
            ctx.setFillColor(NSColor.white.withAlphaComponent(alpha).cgColor)
            ctx.fillEllipse(in: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2))
        }
        ctx.restoreGState()
    }

    private func drawFog(_ ctx: CGContext) {
        ctx.saveGState()
        ctx.setFillColor(NSColor.white.withAlphaComponent(0.14).cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        ctx.restoreGState()
    }

    private func drawLightningBolts(_ ctx: CGContext) {
        ctx.saveGState()
        let boltCount = Int.random(in: 1...2)
        for _ in 0..<boltCount {
            let startX = CGFloat.random(in: size.width * 0.2...size.width * 0.8)
            var point = CGPoint(x: startX, y: size.height * CGFloat.random(in: 0.7...0.95))
            ctx.beginPath()
            ctx.move(to: point)
            let segments = Int.random(in: 4...6)
            for _ in 0..<segments {
                point = CGPoint(
                    x: point.x + CGFloat.random(in: -40...40),
                    y: point.y - size.height / CGFloat(segments) * CGFloat.random(in: 0.6...1.0)
                )
                ctx.addLine(to: point)
            }
            ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.35).cgColor)
            ctx.setLineWidth(2)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
}
