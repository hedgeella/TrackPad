// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrackPad",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "TrackPad",
            path: "TrackPad",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "TrackPad.entitlements",
                "Preview Content"
            ]
        )
    ]
)
