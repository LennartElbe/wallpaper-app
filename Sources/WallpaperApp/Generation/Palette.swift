import AppKit

/// A hand-picked set of colors representing one "moment" in the day cycle.
/// `accents` are used for the scattered geometric shapes; `backgroundTop`/
/// `backgroundBottom` form the base gradient.
struct PhasePalette {
    let backgroundTop: NSColor
    let backgroundBottom: NSColor
    let accents: [NSColor]
}

enum Palette {
    /// Anchors around the 24h clock. Each palette was chosen to blend
    /// reasonably into its neighbors when cross-faded in RGB space, so we
    /// avoid hue-wheel interpolation (which tends to slide through unwanted
    /// hues like green when going from blue to orange).
    private static let anchors: [(hour: Double, palette: PhasePalette)] = [
        (0, PhasePalette( // deep night
            backgroundTop: NSColor(calibratedRed: 0.04, green: 0.05, blue: 0.14, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.09, green: 0.08, blue: 0.22, alpha: 1),
            accents: [
                NSColor(calibratedRed: 0.20, green: 0.22, blue: 0.45, alpha: 1),
                NSColor(calibratedRed: 0.35, green: 0.30, blue: 0.55, alpha: 1),
                NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.30, alpha: 1),
                NSColor(calibratedRed: 0.55, green: 0.50, blue: 0.75, alpha: 1)
            ]
        )),
        (5, PhasePalette( // pre-dawn, coldest
            backgroundTop: NSColor(calibratedRed: 0.03, green: 0.05, blue: 0.16, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.28, alpha: 1),
            accents: [
                NSColor(calibratedRed: 0.18, green: 0.24, blue: 0.50, alpha: 1),
                NSColor(calibratedRed: 0.30, green: 0.35, blue: 0.60, alpha: 1),
                NSColor(calibratedRed: 0.10, green: 0.16, blue: 0.34, alpha: 1),
                NSColor(calibratedRed: 0.45, green: 0.48, blue: 0.70, alpha: 1)
            ]
        )),
        (7.5, PhasePalette( // sunrise
            backgroundTop: NSColor(calibratedRed: 0.20, green: 0.18, blue: 0.38, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.75, green: 0.45, blue: 0.42, alpha: 1),
            accents: [
                NSColor(calibratedRed: 0.95, green: 0.65, blue: 0.45, alpha: 1),
                NSColor(calibratedRed: 0.85, green: 0.45, blue: 0.55, alpha: 1),
                NSColor(calibratedRed: 0.55, green: 0.35, blue: 0.60, alpha: 1),
                NSColor(calibratedRed: 0.98, green: 0.80, blue: 0.60, alpha: 1)
            ]
        )),
        (11, PhasePalette( // late morning, bright neutral-cool
            backgroundTop: NSColor(calibratedRed: 0.35, green: 0.55, blue: 0.85, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.70, green: 0.82, blue: 0.95, alpha: 1),
            accents: [
                NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.92, alpha: 1),
                NSColor(calibratedRed: 0.55, green: 0.75, blue: 0.95, alpha: 1),
                NSColor(calibratedRed: 0.20, green: 0.45, blue: 0.75, alpha: 1),
                NSColor(calibratedRed: 0.90, green: 0.70, blue: 0.55, alpha: 1)
            ]
        )),
        (15, PhasePalette( // early afternoon, peak brightness
            backgroundTop: NSColor(calibratedRed: 0.30, green: 0.52, blue: 0.88, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.68, green: 0.85, blue: 0.98, alpha: 1),
            accents: [
                NSColor(calibratedRed: 1.00, green: 0.95, blue: 0.80, alpha: 1),
                NSColor(calibratedRed: 0.50, green: 0.78, blue: 0.92, alpha: 1),
                NSColor(calibratedRed: 0.95, green: 0.60, blue: 0.35, alpha: 1),
                NSColor(calibratedRed: 0.20, green: 0.40, blue: 0.70, alpha: 1)
            ]
        )),
        (17.5, PhasePalette( // golden hour
            backgroundTop: NSColor(calibratedRed: 0.35, green: 0.30, blue: 0.55, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.95, green: 0.60, blue: 0.30, alpha: 1),
            accents: [
                NSColor(calibratedRed: 1.00, green: 0.75, blue: 0.30, alpha: 1),
                NSColor(calibratedRed: 0.95, green: 0.45, blue: 0.35, alpha: 1),
                NSColor(calibratedRed: 0.65, green: 0.35, blue: 0.55, alpha: 1),
                NSColor(calibratedRed: 1.00, green: 0.90, blue: 0.60, alpha: 1)
            ]
        )),
        (19.5, PhasePalette( // sunset peak
            backgroundTop: NSColor(calibratedRed: 0.20, green: 0.12, blue: 0.30, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.90, green: 0.35, blue: 0.25, alpha: 1),
            accents: [
                NSColor(calibratedRed: 1.00, green: 0.55, blue: 0.25, alpha: 1),
                NSColor(calibratedRed: 0.95, green: 0.30, blue: 0.35, alpha: 1),
                NSColor(calibratedRed: 0.55, green: 0.20, blue: 0.45, alpha: 1),
                NSColor(calibratedRed: 1.00, green: 0.80, blue: 0.45, alpha: 1)
            ]
        )),
        (21.5, PhasePalette( // dusk, cooling fast
            backgroundTop: NSColor(calibratedRed: 0.08, green: 0.07, blue: 0.20, alpha: 1),
            backgroundBottom: NSColor(calibratedRed: 0.28, green: 0.15, blue: 0.35, alpha: 1),
            accents: [
                NSColor(calibratedRed: 0.55, green: 0.25, blue: 0.50, alpha: 1),
                NSColor(calibratedRed: 0.35, green: 0.20, blue: 0.55, alpha: 1),
                NSColor(calibratedRed: 0.20, green: 0.15, blue: 0.40, alpha: 1),
                NSColor(calibratedRed: 0.70, green: 0.40, blue: 0.55, alpha: 1)
            ]
        ))
    ]

    /// Interpolates between the two nearest anchors (wrapping past midnight).
    static func palette(forHour hour: Double) -> PhasePalette {
        let sorted = anchors
        var lower = sorted[sorted.count - 1]
        var upper = sorted[0]
        var wrap = true

        for i in 0..<(sorted.count - 1) {
            if sorted[i].hour <= hour && hour <= sorted[i + 1].hour {
                lower = sorted[i]
                upper = sorted[i + 1]
                wrap = false
                break
            }
        }

        let span: Double
        let t: Double
        if wrap {
            // between last anchor and first anchor (+24h)
            span = (upper.hour + 24) - lower.hour
            let position = hour < lower.hour ? hour + 24 : hour
            t = span == 0 ? 0 : (position - lower.hour) / span
        } else {
            span = upper.hour - lower.hour
            t = span == 0 ? 0 : (hour - lower.hour) / span
        }

        return blend(lower.palette, upper.palette, t: t)
    }

    private static func blend(_ a: PhasePalette, _ b: PhasePalette, t: Double) -> PhasePalette {
        let accentCount = min(a.accents.count, b.accents.count)
        var accents: [NSColor] = []
        for i in 0..<accentCount {
            accents.append(a.accents[i].blended(withFraction: t, of: b.accents[i]) ?? a.accents[i])
        }
        return PhasePalette(
            backgroundTop: a.backgroundTop.blended(withFraction: t, of: b.backgroundTop) ?? a.backgroundTop,
            backgroundBottom: a.backgroundBottom.blended(withFraction: t, of: b.backgroundBottom) ?? a.backgroundBottom,
            accents: accents
        )
    }
}

extension NSColor {
    /// Returns a copy with saturation and brightness scaled (clamped to [0,1]).
    func adjusted(saturationScale: CGFloat = 1, brightnessScale: CGFloat = 1) -> NSColor {
        guard let hsb = usingColorSpace(.deviceRGB) else { return self }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        hsb.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        s = min(max(s * saturationScale, 0), 1)
        b = min(max(b * brightnessScale, 0), 1)
        return NSColor(hue: h, saturation: s, brightness: b, alpha: a)
    }
}
