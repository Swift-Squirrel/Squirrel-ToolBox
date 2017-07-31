//
//  Shell.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 7/30/17.
//
//

import Foundation
import PathKit

struct ShellResult: CustomStringConvertible {
    let output: String?
    let status: Int32
    var description: String {
        return String(describing: output) + " " + String(describing: status)
    }
}

func shell(launchPath: Path, executable: String, arguments: [String] = []) -> ShellResult {
    let task = Process()
    task.launchPath = launchPath.absolute().description
    task.arguments = [executable] + arguments
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    print(task.processIdentifier)
    task.waitUntilExit()
    let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
    return ShellResult(output: output, status: task.terminationStatus)
}

func createTask(launchPath: Path, executable: String, arguments: [String] = [], detached: Bool) -> Process {
    let task = Process()
    task.launchPath = launchPath.absolute().description + "/" + executable
    task.arguments = arguments
    if detached {
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
    } else {
        task.standardOutput = FileHandle.standardOutput
        task.standardError = FileHandle.standardOutput
    }

    return task
}
