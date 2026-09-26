import AppKit

enum DesktopWallpaper {
    static func savePNG(_ image: CGImage, to url: URL) throws {
        let bitmap = NSBitmapImageRep(cgImage: image)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw NSError(domain: "WallpaperApp", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode PNG"])
        }
        try data.write(to: url, options: .atomic)
    }

    /// Applies the image at `url` as the desktop picture on every connected
    /// screen and space.
    ///
    /// `NSWorkspace.setDesktopImageURL` looks like it succeeds but silently
    /// no-ops on newer macOS versions (it doesn't touch
    /// `~/Library/Application Support/com.apple.wallpaper/Store/Index.plist`
    /// at all) — driving System Events via Apple Events is the approach that
    /// actually persists. This requires one-time Automation permission
    /// (System Settings > Privacy & Security > Automation), which macOS will
    /// prompt for on first run.
    static func apply(imageURL: URL) throws {
        let escapedPath = imageURL.path.replacingOccurrences(of: "\"", with: "\\\"")
        let source = """
        tell application "System Events"
            tell every desktop
                set picture to "\(escapedPath)"
            end tell
        end tell
        """

        guard let script = NSAppleScript(source: source) else {
            throw NSError(domain: "WallpaperApp", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to compile AppleScript"])
        }

        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "unknown AppleScript error"
            throw NSError(domain: "WallpaperApp", code: 3, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
