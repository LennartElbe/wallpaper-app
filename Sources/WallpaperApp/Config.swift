import Foundation

struct Config: Codable {
    var latitude: Double?
    var longitude: Double?

    static let directory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("WallpaperApp", isDirectory: true)
    }()

    static let fileURL = directory.appendingPathComponent("config.json")
    static let wallpaperURL = directory.appendingPathComponent("wallpaper.png")
    static let logURL = directory.appendingPathComponent("wallpaper-app.log")

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
