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
import Signals

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
        CLI.setup(name: "Squirrel", version: "0.0.1", description: "Toolbox for squirrel framework")
//        let cmd =
        CLI.register(commands: [ServeCommand(), StopCommand()])
//        CLI.register(command: cmd)
        if !pidsDir.exists {
            try? pidsDir.mkpath() // TODO
        }
    }



    func run() {
//        return
        let a = CLI.go()
//        let a = CLI.debugGo(with: "serve")
        print(a)
    }
}

class StopCommand: Command {
    let name = "stop"

    let shortDescription = "Stop server"

    let stopingPid = OptionalParameter()

    func execute() throws {
        if let stopingPid = stopingPid.value {
            try! removePID(pid: stopingPid)
        } else {
            try! removePID()
        }

    }
}

func removePID(pid: String? = nil) throws {
    guard Pids.pids.exists else {
        return
    }
    let content: String = try! Pids.pids.read()
    guard content != "" else {
        return
    }

    var pids = content.components(separatedBy: "\n").filter({ $0 != "" })
    guard pids.count > 0 else {
        return
    }
    var stoppingPID = pids.first!
    if pid != nil {
        stoppingPID = pid!
    } else {
        guard pids.count == 1 else {
            return
        }
    }

    guard let index = pids.index(of: stoppingPID) else {
        return
    }
    pids.remove(at: index)
    let _ = shell(launchPath: "/usr/bin/env", executable: "kill", arguments: ["-9", stoppingPID])
    var newContent = pids.joined(separator: "\n")
    if newContent != "" {
        newContent += "\n"
    }
    try! Pids.pids.write(newContent)
}

class ServeCommand: Command {
    let name = "serve"

    let shortDescription = "Run server"

    let detach = Flag("-d", "--detach", usage: "Run in background")

    func execute() throws {
        let path = Path(components: [Path().absolute().description, ".build/debug"])
        let exe = "Squirrel"
        let fullPath = Path(components: [path.absolute().description, exe])
        if fullPath.exists && fullPath.isFile {
            let task = createTask(launchPath: path, executable: exe, detached: detach.value)
            task.launch()
            Pids.tasks.append(task)
            try! Pids.pids.append(String(describing: task.processIdentifier) + "\n") // TODO
            if !detach.value {
                Signals.trap(signals: [.int, .abrt, .kill, .term, .quit], action: {
                    _ in
                    for task in Pids.tasks {
                        task.terminate()
                        let stoppingPID = String(describing: task.processIdentifier)
                        guard Pids.pids.exists else {
                            return
                        }
                        let content: String = try! Pids.pids.read()
                        guard content != "" else {
                            return
                        }

                        var pids = content.components(separatedBy: "\n").filter({ $0 != "" })
                        guard pids.count > 0 else {
                            return
                        }

                        guard let index = pids.index(of: stoppingPID) else {
                            return
                        }
                        pids.remove(at: index)
                        var newContent = pids.joined(separator: "\n")
                        if newContent != "" {
                            newContent += "\n"
                        }
                        try! Pids.pids.write(newContent)

                        try! removePID(pid: String(describing: task.processIdentifier))
                    }
                })
                task.waitUntilExit()
            }
        } else {
            print("Error! You are not in roject root directory")
        }
    }
}
