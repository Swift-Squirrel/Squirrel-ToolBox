// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SquirrelToolBox",
    products: [
        .executable(
            name: "SquirrelToolBox",
            targets: ["SquirrelToolBox"]),
        ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git",  from: "0.8.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI",  from: "3.0.0"),
        .package(url: "https://github.com/jpsim/Yams.git",  from: "0.3.6"),
        .package(url: "https://github.com/jkandzi/Progress.swift.git",  from: "0.2.0"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals",  from: "0.9.0"),
    ],
    targets: [
        .target(
            name: "SquirrelToolBox",
            dependencies: ["SourceGenerator", "SwiftCLI", "PathKit", "Yams", "Progress", "Signals"]),
        .target(
            name: "SourceGenerator"),
    ]
)
