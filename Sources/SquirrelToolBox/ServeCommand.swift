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
    private let configuration = Key<String>("-c", "--configuration",
                                            description: "Values: debug|release (default: debug)")
    private let configurationValues = ["debug", "release"]

    func execute() throws {
        let conf = configuration.value ?? configurationValues.first!
        guard configurationValues.contains(conf) else {
            let confValues = configurationValues.joined(separator: "|")
            throw CLI.Error(message: "--configuration expects \(confValues) but \(conf) given.")
        }

        let packagePath = Path(components: [Path().absolute().description, "Package.swift"])
        if packagePath.exists && packagePath.isFile {
            if build.value {
                let buildTask = swift(command: .build, arguments: ["-c", conf], silenced: false)
                buildTask.launch()
                buildTask.waitUntilExit()
                guard buildTask.terminationStatus == 0 else {
                    throw CLI.Error(message: "Build failed")
                }
            }
            let task = swift(command: .run, silenced: detach.value)
            task.launch()
            defer {
                task.osTerminate()
            }
            try Pids.pids.append("\(task.processIdentifier)\n")
            Pids.task = task
            if !detach.value {
                signalTrap()
                task.waitUntilExit()
            }
        } else {
            throw CLI.Error(
                message: "You are not in project root directory - missing Package.swift")
        }
    }

    private func signalTrap() {
        Signals.trap(signals: [.hup, .int, .quit, .abrt, .kill, .alrm, .term, .pipe]) {
            _ in
            let task = Pids.task
            task.osTerminate()
            let stoppingPID = String(describing: task.processIdentifier)
            guard Pids.pids.exists else {
                return
            }
            guard let content: String = try? Pids.pids.read() else {
                print("Culd not read PIDs, kill process by kill -9 <PID>")
                return
            }
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
            try? Pids.pids.write(newContent)

            try? removePID(pid: String(describing: task.processIdentifier))
        }
    }
}
