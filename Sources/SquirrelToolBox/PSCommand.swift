//
//  PSCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 10/7/17.
//

import SwiftCLI

class PSCommand: Command {
    let name = "ps"

    let shortDescription = "Show running processes"

    func execute() throws {
        guard let content: String = try? Pids.pids.read() else {
            throw CLI.Error(message: "Could not read from \(Pids.pids.string)")
        }
        print(content)
    }
}
