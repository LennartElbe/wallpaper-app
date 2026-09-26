import Foundation
import IOKit.ps

struct BatteryContext {
    let percentage: Double  // 0...1
    let isCharging: Bool

    /// How "energetic" the pattern should look: denser/more shapes on full or
    /// charging battery, sparser and calmer when running low.
    var energy: Double {
        isCharging ? max(percentage, 0.6) : percentage
    }

    static func current() -> BatteryContext {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: AnyObject]
        else {
            // No battery info available (e.g. desktop Mac, or sandboxed environment) — assume full/plugged in.
            return BatteryContext(percentage: 1.0, isCharging: true)
        }

        let capacity = description[kIOPSCurrentCapacityKey] as? Int ?? 100
        let maxCapacity = description[kIOPSMaxCapacityKey] as? Int ?? 100
        let state = description[kIOPSPowerSourceStateKey] as? String
        let isCharging = state == kIOPSACPowerValue

        let percentage = maxCapacity > 0 ? Double(capacity) / Double(maxCapacity) : 1.0
        return BatteryContext(percentage: min(max(percentage, 0), 1), isCharging: isCharging)
    }
}
