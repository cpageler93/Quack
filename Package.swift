// swift-tools-version:4.0

import PackageDescription

#if os(Linux)
let httpPackageDependency = Package.Dependency.package(url: "https://github.com/vapor/engine.git", from: "2.2.1")
let httpTargetDependency = Target.Dependency.byNameItem(name: "HTTP")
#else
let httpPackageDependency = Package.Dependency.package(url: "https://github.com/Alamofire/Alamofire", from: "4.6.0")
let httpTargetDependency = Target.Dependency.byNameItem(name: "Alamofire")
#endif

let package = Package(
    name: "Quack",
    products: [
        .library(name: "Quack", targets: ["Quack"])
    ],
    dependencies: [
        httpPackageDependency,
        .package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", from: "17.0.0"),
        .package(url: "https://github.com/antitypical/Result.git", from: "3.2.4")
    ],
    targets: [
        .target(name: "Quack", dependencies: [
            httpTargetDependency,
            .byNameItem(name: "SwiftyJSON"),
            .byNameItem(name: "Result")
        ]),
        .testTarget(name: "QuackUnitTests", dependencies: ["Quack"])
    ]
)