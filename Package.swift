// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "AppleFontAwesome",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "AppleFontAwesome",
            targets: ["AppleFontAwesome"]
        ),
        .executable(
            name: "apple-font-awesome-generate",
            targets: ["AppleFontAwesomeGenerator"]
        ),
    ],
    targets: [
        .target(
            name: "AppleFontAwesome",
            resources: [
                .process("Resources"),
            ]
        ),
        .executableTarget(
            name: "AppleFontAwesomeGenerator"
        ),
    ]
)
