// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "SquirrelToolBox",
    targets: [
        Target(name: "SquirrelToolBox", dependencies: ["SourceGenerator"])
    ],
    dependencies: [
        .Package(url: "https://github.com/jakeheis/SwiftCLI", majorVersion: 3, minor: 0),
        .Package(url: "https://github.com/kylef/PathKit.git", majorVersion: 0, minor: 8),
        .Package(url: "https://github.com/behrang/YamlSwift.git", majorVersion: 3, minor: 4),
        .Package(url: "https://github.com/jkandzi/Progress.swift.git", majorVersion: 0, minor: 2),
        .Package(url: "https://github.com/IBM-Swift/BlueSignals.git", majorVersion: 0, minor: 9)
    ]
)
