import Foundation

/// Derived from the current clock time: how "warm" the palette should feel
/// and how bright the scene should be. Both are smooth curves over the day
/// so wallpapers drift gradually rather than snapping between buckets.
struct TimeContext {
    let warmth: Double      // 0 = coldest (deep blue, pre-dawn) -> 1 = warmest (sunset orange)
    let brightness: Double  // 0 = darkest (midnight) -> 1 = brightest (midday)
    let hour: Double        // fractional hour, 0..<24, for logging

    /// Keyframes of (hour, warmth, brightness). Interpolated linearly with wraparound.
    private static let keyframes: [(hour: Double, warmth: Double, brightness: Double)] = [
        (0,  0.15, 0.08),   // midnight: cold, dark
        (5,  0.10, 0.05),   // pre-dawn: coldest point of the day
        (7,  0.45, 0.35),   // sunrise: warming quickly, brightening
        (11, 0.35, 0.95),   // late morning: bright, neutral-cool daylight
        (14, 0.40, 1.00),   // early afternoon: peak brightness
        (17, 0.65, 0.75),   // late afternoon: warming
        (19, 0.95, 0.45),   // sunset: peak warmth
        (21, 0.55, 0.20),   // dusk: cooling fast
        (24, 0.15, 0.08)    // back to midnight
    ]

    static func current(now: Date = Date()) -> TimeContext {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.hour, .minute], from: now)
        let hour = Double(comps.hour ?? 0) + Double(comps.minute ?? 0) / 60.0

        var lower = keyframes[0]
        var upper = keyframes[keyframes.count - 1]
        for i in 0..<(keyframes.count - 1) {
            if keyframes[i].hour <= hour && hour <= keyframes[i + 1].hour {
                lower = keyframes[i]
                upper = keyframes[i + 1]
                break
            }
        }

        let span = upper.hour - lower.hour
        let t = span == 0 ? 0 : (hour - lower.hour) / span
        let warmth = lower.warmth + (upper.warmth - lower.warmth) * t
        let brightness = lower.brightness + (upper.brightness - lower.brightness) * t

        return TimeContext(warmth: warmth, brightness: brightness, hour: hour)
    }
}
