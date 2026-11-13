// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "NewRules",
    platforms: [
        .macOS(.v14),
        .iOS(.v16),
        .tvOS(.v16),
//        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "NewRules",
            targets: ["NewRules"]),
        .library(
            name: "Tokenizer",
            targets: ["Tokenizer"]),
        .library(
            name: "Rewriter",
            targets: [
                "Rewriter",
                "NewRules",
            ]),
        .library(
            name: "XMLBuilder",
            targets: [
                "XMLBuilder",
                "NewRules",
            ]),
        .executable(name: "clone", targets: ["Tool"]),
    ],
    dependencies: [
        .package(url: "https://github.com/davdroman/swift-builders.git", from: "0.11.0"),
    ],
    targets: [
        .target(
            name: "NewRules",
        dependencies: [
            .product(name: "Builders", package: "swift-builders"),
        ]),
        .target(
            name: "Rewriter",
            dependencies: [
                "NewRules"
            ]
        ),
        .target(
            name: "XMLBuilder",
            dependencies: ["NewRules"]
        ),
        .target(
            name: "Tokenizer",
            dependencies: []
        ),
        .target(
            name: "Benders",
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
//                "NewRules",
                "Rewriter",
                "Tokenizer",
                "Benders",
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
