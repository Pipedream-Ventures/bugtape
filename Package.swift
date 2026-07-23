// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BugTape",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "BugTapeCore", targets: ["BugTapeCore"]),
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
        .testTarget(
            name: "BugTapeCoreTests",
            dependencies: ["BugTapeCore"]
        )
    ]
)
