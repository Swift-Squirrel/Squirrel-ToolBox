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
    let output: String
    let status: Int32
    let description: String
    init(status: Int32, output: String) {
        self.output = output
        self.status = status
        self.description = "\(status)\n\(output)"
    }
}

/// Shell command with stored stderr and setout to variable
///
/// - Parameters:
///   - launchPath: launchpath
///   - executable: executable name
///   - arguments: arguments
/// - Returns: `ShellResult` containing stderr, stdout and status code of shell command
func shellWithOutput(
    launchPath: Path,
    executable: String,
    arguments: [String] = []) -> ShellResult {

    let task = Process()
    task.launchPath = launchPath.absolute().description
    task.arguments = [executable] + arguments
    let pipe = Pipe()
    task.standardOutput = pipe
    task.standardError = pipe
    task.launch()
    task.waitUntilExit()
    let output = String(
        data: pipe.fileHandleForReading.readDataToEndOfFile(),
        encoding: .utf8) ?? ""

    return ShellResult(status: task.terminationStatus, output: output)
}

/// Shell command with classic stderr and stdout
///
/// - Parameters:
///   - launchPath: launchpath
///   - executable: executable name
///   - arguments: arguments
/// - Returns: status code
func shell(launchPath: Path, executable: String, arguments: [String] = []) -> Int32 {
    let task = Process()
    task.launchPath = launchPath.absolute().description
    task.arguments = [executable] + arguments
    task.standardOutput = FileHandle.standardOutput
    task.standardError = FileHandle.standardError
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}
