// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "aiXplainKit",
    platforms: [
        .iOS(.v15) // Specify iOS 15 as the minimum supported platform
      ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "aiXplainKit",
            targets: ["aiXplainKit"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "aiXplainKit"),
        .testTarget(
            name: "aiXplainKitTests",
            dependencies: ["aiXplainKit"]),
    ]
)
