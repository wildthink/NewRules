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
            name: "Rewriter",
            targets: [
                "Rewriter",
                "NewRules",
            ]),
        .executable(name: "clone", targets: ["Tool"]),
    ],
    targets: [
        .target(
            name: "NewRules"),
        .target(
            name: "Rewriter",
            dependencies: ["NewRules"]
        ),
        .executableTarget(
            name: "Tool",
            dependencies: [
                "NewRules",
                "Rewriter",
            ]
        ),
       .testTarget(
            name: "NewRulesTests",
            dependencies: [
                "NewRules",
                "Rewriter",
            ]
        ),
    ]
)
