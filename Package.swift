// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "Quack",
    dependencies: [
        .Package(url: "https://github.com/Alamofire/Alamofire.git", majorVersion: 4),
        .Package(url: "https://github.com/IBM-Swift/SwiftyJSON.git", majorVersion: 17)
    ]
)
