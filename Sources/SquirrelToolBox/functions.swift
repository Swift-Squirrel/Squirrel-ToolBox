//
//  functions.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/3/17.
//
//

import Foundation
import PathKit
import SwiftCLI
import Yams

enum SwiftCommand: String {
    case run
    case build
}

func swift(command: SwiftCommand, arguments: [String] = [], silenced: Bool = true) -> Process {
    let runTask = Process()
    runTask.launchPath = "/usr/bin/env"
    runTask.arguments = [
        "swift",
        command.rawValue,
        "--package-path",
        Path().absolute().string
        ] + arguments

    if silenced {
        #if os(Linux)
            let pipe = Pipe()
            runTask.standardOutput = pipe
            runTask.standardError = pipe
        #else
            runTask.standardOutput = FileHandle.nullDevice
            runTask.standardError = FileHandle.nullDevice
        #endif
    } else {
        runTask.standardError = FileHandle.standardError
        runTask.standardOutput = FileHandle.standardOutput
    }
    return runTask
}

func removePID(pid: String? = nil) throws {
    guard Pids.pids.exists else {
        return
    }
    guard let content: String = try? Pids.pids.read() else {
        throw CLI.Error(message: "Could not read content of \(Pids.pids.string)")
    }
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
    kill(pid: stoppingPID)
    var newContent = pids.joined(separator: "\n")
    if newContent != "" {
        newContent += "\n"
    }
    guard (try? Pids.pids.write(newContent)) != nil else {
        throw CLI.Error(message: "Could not write into \(Pids.pids.string)")
    }
}

func kill(pid: String) {
    let _ = shell(launchPath: "/usr/bin/env", executable: "kill", arguments: ["-9", pid])
}
func kill(pid: Int32) {
    kill(pid: pid.description)
}
