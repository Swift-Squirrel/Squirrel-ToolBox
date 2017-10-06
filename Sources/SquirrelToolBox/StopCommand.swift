//
//  StopCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/3/17.
//
//

import SwiftCLI

class StopCommand: Command {
    let name = "stop"

    let shortDescription = "Stop server"

    let stopingPid = OptionalParameter()
    // TODO stop all tasks
    // TODO show all running tasks

    func execute() throws {
        if let stopingPid = stopingPid.value {
            try removePID(pid: stopingPid)
        } else {
            try removePID()
        }
    }
}
