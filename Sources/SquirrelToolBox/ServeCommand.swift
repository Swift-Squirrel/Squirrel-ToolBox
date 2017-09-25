//
//  ServeCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/3/17.
//
//

import SwiftCLI
import PathKit
import Signals

class ServeCommand: Command {
    let name = "serve"

    let shortDescription = "Run server"

    private let detach = Flag("-d", "--detach", description: "Run in background")
    private let build = Flag("-b", "--build", description: "Build project before run")
    private let configuration = Key<String>("-c", "--configuration", description: "Values: debug|release (default: debug)")
    private let configurationValues = ["debug", "release"]

    func execute() throws {
        let conf = configuration.value ?? configurationValues.first!
        guard configurationValues.contains(conf) else {
            throw CLI.Error(message: "--configuration expects \(configurationValues.joined(separator: "|")) but \(conf) given.", exitStatus: 1)
        }
        let path = Path(components: [Path().absolute().description, ".build/" + conf])
        guard let exe = getExecutableName() else {
            print("error")
            throw CLI.Error(message: "Error in parsing Package.swift", exitStatus: 1)
        }
        let packagePath = Path(components: [Path().absolute().description, "Package.swift"])
        if packagePath.exists && packagePath.isFile {
            if build.value {
                swiftBuild(root: Path().absolute(), configuration: conf)
            }
            let task = createTask(launchPath: path, executable: exe, detached: detach.value)
            task.launch()
            Pids.tasks.append(task)
            try! Pids.pids.append(String(describing: task.processIdentifier) + "\n") // TODO
            if !detach.value {
                signalTrap()
                task.waitUntilExit()
            }
        } else {
            print("Error! You are not in roject root directory")
        }
    }

    private func signalTrap() {
        Signals.trap(signals: [.int, .abrt, .kill, .term, .quit]) {
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
        }
    }
}

