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
    static var tasks = [Process]()
    private init() {

    }
}

class ToolBox {
    private let pids = Pids.pids
    private let pidsDir = Pids.pidsDir
    let cli: CLI

    init() {
        cli = CLI(name: "Squirrel", version: "0.0.3", description: "Toolbox for squirrel framework")
//        cli
        cli.commands = [
            ServeCommand(),
            StopCommand(),
            CreateCommand(),
//            MigrationCommand(),
            SeedCommand(),
            WatchCommand()
            ]
        if !pidsDir.exists {
            try? pidsDir.mkpath() // TODO
        }
    }

    func run() {
        let a = cli.go()
        print(a)
    }
}

