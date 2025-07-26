// swift-tools-version: 6.1

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
        .target(
            name: "Tokenizer",
            dependencies: []
        ),
        .executableTarget(
            name: "Tool",
            dependencies: [
                "NewRules",
                "Rewriter",
                "Tokenizer",
            ]
            ,swiftSettings: swiftSettings
        ),
       .testTarget(
            name: "NewRulesTests",
            dependencies: [
                "NewRules",
                "Rewriter",
                "Tokenizer",
            ]
        ),
    ]
)

let swiftSettings: [SwiftSetting] = [
    // Enable whole module optimization
    .unsafeFlags(["-whole-module-optimization"], .when(configuration: .release)),
    // Optimize for size
    .unsafeFlags(["-Osize"], .when(configuration: .release)),
    // Strip all symbols
    .unsafeFlags(["-Xlinker", "-strip-all"], .when(configuration: .release)),
    // Enable dead code stripping
    .unsafeFlags(["-Xlinker", "-dead_strip"], .when(configuration: .release)),
    // Embed Bitcode (if necessary, optional)
    //                .unsafeFlags(["-embed-bitcode"], .when(configuration: .release)),
]
