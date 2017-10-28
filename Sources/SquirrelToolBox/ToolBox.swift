//
//  ToolBox.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 7/30/17.
//
//

import Foundation
import SwiftCLI
import PathKit

struct Pids {
    static let stringPidsDir = "/usr/local/squirrel"
    static let stringPidsFile = "squirrel.pid"
    static let pids = Path(components: [stringPidsDir, stringPidsFile])
    static let pidsDir = Path(stringPidsDir)
    static var task = Process() {
        willSet {
            task.osTerminate()
        }
    }
    private init() { }
}

final class ToolBox {
    private let pids = Pids.pids
    private let pidsDir = Pids.pidsDir
    private let cli: CLI
    private let version = "0.1.1"

    init() throws {
        cli = CLI(
            name: "Squirrel",
            version: version,
            description: "Toolbox for swift Squirrel framework")

        cli.commands = [
            ServeCommand(),
            StopCommand(),
            PSCommand(),
            WatchCommand(),
            CreateCommand()
        ]
        if !pidsDir.exists {
            try pidsDir.mkpath()
        }
    }

    func run() -> Int32 {
        return cli.go()
    }
}
