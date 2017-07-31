// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SquirrelToolBox",
    dependencies: [
        .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 3, minor: 0),
        .Package(url: "https://github.com/kylef/PathKit.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", majorVersion: 0, minor: 9)
    ]
)
