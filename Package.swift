// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Quack",
    products: [
        .library(name: "QuackBase", targets: ["QuackBase"]),
        .library(name: "Quack", targets: ["Quack"]),
        .library(name: "QuackLinux", targets: ["QuackLinux"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/engine.git", from: "2.2.1"),            // networking linux
        .package(url: "https://github.com/Alamofire/Alamofire", from: "4.6.0"),         // networking ios, tvos, macos
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from: "17.0.0"),   // json parsing
        .package(url: "https://github.com/antitypical/Result.git", from: "3.2.4")       // result enum
    ],
    targets: [
        .target(name: "QuackBase", dependencies: [
            .byNameItem(name: "SwiftyJSON"),
            .byNameItem(name: "Result")
        ]),
        .target(name: "Quack", dependencies: [
            .byNameItem(name: "QuackBase"),
            .byNameItem(name: "Alamofire")
        ]),
        .target(name: "QuackLinux", dependencies: [
            .byNameItem(name: "QuackBase"),
            .byNameItem(name: "HTTP")
        ]),
        .testTarget(name: "QuackBaseUnitTests", dependencies: ["QuackBase"]),
        .testTarget(name: "QuackUnitTests", dependencies: ["Quack"]),
        .testTarget(name: "QuackLinuxUnitTests", dependencies: ["QuackLinux"])
    ]
)