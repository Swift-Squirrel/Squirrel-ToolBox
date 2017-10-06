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
    let all = Flag("-a", "--all")

    func execute() throws {
        if all.value {
            try removeAllPIDs()
        } else {
            if let stopingPid = stopingPid.value {
                try removePID(pid: stopingPid)
            } else {
                try removePID()
            }
        }
    }
}
