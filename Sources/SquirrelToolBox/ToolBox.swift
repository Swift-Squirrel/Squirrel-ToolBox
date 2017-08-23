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

    init() {
        CLI.setup(name: "Squirrel", version: "0.0.2", description: "Toolbox for squirrel framework")
        CLI.register(commands: [
            ServeCommand(),
            StopCommand(),
            CreateCommand(),
//            MigrationCommand(),
            SeedCommand()
            ])
        if !pidsDir.exists {
            try? pidsDir.mkpath() // TODO
        }
    }

    func run() {
        let a = CLI.go()
        print(a)
    }
}

