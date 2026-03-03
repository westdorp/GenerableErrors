// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GenerableErrors",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        .library(
            name: "GenerableErrors",
            targets: ["GenerableErrors"]
        ),
        .library(
            name: "CuratedStyles",
            targets: ["CuratedStyles"]
        ),
        .library(
            name: "GenerableErrorsTesting",
            targets: ["GenerableErrorsTesting"]
        ),
    ],
    targets: [
        .target(
            name: "GenerableErrors",
            path: "Sources/GenerableErrors"
        ),
        .target(
            name: "CuratedStyles",
            dependencies: ["GenerableErrors"],
            path: "Sources/CuratedStyles"
        ),
        .target(
            name: "GenerableErrorsTesting",
            dependencies: ["GenerableErrors"],
            path: "Tests/GenerableErrorsTesting"
        ),
        .testTarget(
            name: "GenerableErrorsTests",
            dependencies: [
                "GenerableErrors",
                "CuratedStyles",
                "GenerableErrorsTesting",
            ],
            path: "Tests/GenerableErrorsTests"
        ),
    ]
)
