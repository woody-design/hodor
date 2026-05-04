// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PromptPal",
    platforms: [
        .macOS(.v15)
    ],
    targets: [
        .executableTarget(
            name: "PromptPal",
            path: "Sources"
        )
    ]
)
