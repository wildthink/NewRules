// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NewRules",
    platforms: [
        .macOS(.v14),
        .iOS(.v16),
        .tvOS(.v16),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "NewRules",
            targets: ["NewRules"]),
        .library(
            name: "Examples",
            targets: ["Examples"]),
    ],
    targets: [
        .target(
            name: "NewRules"),
        .target(
            name: "Examples",
            dependencies: ["NewRules"]
        ),
       .testTarget(
            name: "NewRulesTests",
            dependencies: [
                "NewRules",
                "Examples",
            ]
        ),
    ]
)
