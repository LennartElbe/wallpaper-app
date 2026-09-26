// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WallpaperApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "WallpaperApp",
            path: "Sources/WallpaperApp"
        )
    ]
)
