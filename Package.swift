// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Quack",
    products: [
        .library(name: "Quack", targets: ["Quack"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/engine.git", from: "2.2.1"),
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from: "17.0.0")
    ],
    targets: [
        .target(name: "Quack", dependencies: [
            .byNameItem(name: "HTTP"),
            .byNameItem(name: "SwiftyJSON")
        ]),
        .testTarget(name: "UnitTests", dependencies: ["Quack"])
    ]
)