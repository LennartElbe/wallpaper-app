import Foundation

struct Config: Codable {
    var latitude: Double?
    var longitude: Double?

    static let directory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("WallpaperApp", isDirectory: true)
    }()

    static let fileURL = directory.appendingPathComponent("config.json")
    static let logURL = directory.appendingPathComponent("wallpaper-app.log")
    private static let variantStateURL = directory.appendingPathComponent(".last-variant")

    /// macOS caches the desktop picture by file URL: overwriting the same
    /// path in place doesn't reliably trigger a redraw, even though the
    /// bytes on disk changed. Alternating between two filenames each run
    /// forces the OS to treat every update as a genuinely new picture.
    static func nextWallpaperURL() -> URL {
        let lastVariant = (try? String(contentsOf: variantStateURL, encoding: .utf8)) ?? "2"
        let nextVariant = lastVariant.trimmingCharacters(in: .whitespacesAndNewlines) == "1" ? "2" : "1"
        try? nextVariant.write(to: variantStateURL, atomically: true, encoding: .utf8)
        return directory.appendingPathComponent("wallpaper-\(nextVariant).png")
    }

    static func load() -> Config {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        guard let data = try? Data(contentsOf: fileURL),
              let config = try? JSONDecoder().decode(Config.self, from: data) else {
            let placeholder = Config(latitude: nil, longitude: nil)
            placeholder.writeIfMissing()
            return placeholder
        }
        return config
    }

    private func writeIfMissing() {
        guard !FileManager.default.fileExists(atPath: Config.fileURL.path) else { return }
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: Config.fileURL)
        }
    }

    var hasLocation: Bool { latitude != nil && longitude != nil }
}
