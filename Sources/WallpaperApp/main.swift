import AppKit
import Foundation

func log(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let line = "[\(timestamp)] \(message)"
    print(line)
    if let handle = try? FileHandle(forWritingTo: Config.logURL) {
        handle.seekToEndOfFile()
        handle.write((line + "\n").data(using: .utf8)!)
        try? handle.close()
    } else {
        try? (line + "\n").write(to: Config.logURL, atomically: true, encoding: .utf8)
    }
}

func pixelSizeOfMainScreen() -> CGSize {
    guard let screen = NSScreen.main else {
        return CGSize(width: 3840, height: 2160) // sane fallback for a headless run
    }
    let scale = screen.backingScaleFactor
    return CGSize(width: screen.frame.width * scale, height: screen.frame.height * scale)
}

let config = Config.load()
let time = TimeContext.current()
let battery = BatteryContext.current()

var weather: WeatherContext? = nil
if let lat = config.latitude, let lon = config.longitude {
    weather = await WeatherContext.fetch(latitude: lat, longitude: lon)
}

let size = pixelSizeOfMainScreen()
let renderer = WallpaperRenderer(size: size, time: time, battery: battery, weather: weather)

guard let cgImage = renderer.render() else {
    log("ERROR: failed to render wallpaper")
    exit(1)
}

do {
    try DesktopWallpaper.savePNG(cgImage, to: Config.wallpaperURL)
    try DesktopWallpaper.apply(imageURL: Config.wallpaperURL)

    let weatherDesc = weather.map { "\($0.mood.rawValue), \(Int($0.temperatureC))°C" } ?? "no location configured"
    let batteryDesc = "\(Int(battery.percentage * 100))%\(battery.isCharging ? " (charging)" : "")"
    log("Generated wallpaper — hour \(String(format: "%.1f", time.hour)), battery \(batteryDesc), weather: \(weatherDesc)")
} catch {
    log("ERROR: \(error.localizedDescription)")
    exit(1)
}
