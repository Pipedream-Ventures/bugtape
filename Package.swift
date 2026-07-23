// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BugTape",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "BugTapeCore", targets: ["BugTapeCore"]),
        .executable(name: "TAPE", targets: ["AppTapeApp"]),
        .executable(name: "AppTape", targets: ["AppTapeApp"]),
        .executable(name: "apptape", targets: ["BugTapeCLI"]),
        .executable(name: "bugtape", targets: ["BugTapeCLI"])
    ],
    targets: [
        .target(
            name: "BugTapeCore",
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ImageIO")
            ]
        ),
        .executableTarget(
            name: "BugTapeCLI",
            dependencies: ["BugTapeCore"]
        ),
        .executableTarget(
            name: "AppTapeApp",
            dependencies: ["BugTapeCore"],
            path: "Sources/AppTapeApp",
            resources: [
                .copy("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVKit")
            ]
        ),
        .testTarget(
            name: "BugTapeCoreTests",
            dependencies: ["BugTapeCore"]
        )
    ]
)
