// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "aiXplainKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15),
        .visionOS(.v1),
        .driverKit(.v20)
      ],
    products: [
        .library(
            name: "aiXplainKit",
            targets: ["aiXplainKit"])
    ],
    targets: [
        .target(
            name: "aiXplainKit"),
        .testTarget(
            name: "aiXplainKitTests",
            dependencies: ["aiXplainKit"])
    ]
)
