// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SquirrelToolBox",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 3, minor: 0)
    ]
)
