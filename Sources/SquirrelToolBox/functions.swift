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
import Yaml

func swiftRun(root path: Path) {
    let path = Path(components: [path.absolute().description, ".build/release"])
    guard let exe = getExecutableName(path: path) else {
        print("Error")
        return
    }
    let task = createTask(launchPath: path, executable: exe, detached: false)
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    task.launch()
    task.waitUntilExit()
}

@discardableResult
func swiftBuild(root path: Path, configuration: String = "debug") -> Int32 {
    let res = shell(launchPath: "/usr/bin/env", executable: "swift", arguments: ["build", "--package-path", path.absolute().description, "-c", configuration])
    return res.status
}

func stringRepresentation(of: Any) -> String {
    switch of {
    case let int as Int:
        return String(int)
    case let string as String:
        return  "\"" + string + "\""
    default:
        return String(describing: of)
    }
}

func getConfig(path: Path) -> Yaml? {
    guard let content: String = try? path.read() else {
        return nil
    }
    guard let yaml = try? Yaml.load(content) else {
        return nil
    }
    return yaml
}

func getDB(from path: Path) throws -> String {
    guard let yaml = getConfig(path: path) else {
        throw CLI.Error(message: "Error in \(path.string)", exitStatus: 1)
    }

    guard let databaseYaml = yaml["MongoDB"].dictionary else {
        throw CLI.Error(message: "Missing database informations in \(path.string)", exitStatus: 1)
    }
    guard let host = databaseYaml["host"]?.string else {
        throw CLI.Error(message: "Missing host information in \(path.string)", exitStatus: 1)
    }
    let dbname = databaseYaml["dbname"]?.string ?? "squirrel"
    let port = databaseYaml["port"]?.int ?? 27017

    if let username = databaseYaml["username"]?.string, let password = databaseYaml["password"]?.string {
        return "username: \"\(username)\", password: \"\(password)\", host: \"\(host)\", port: \(port), dbname: \"\(dbname)\""
    } else {
        return "host: \"\(host)\", port: \(port), dbname: \"\(dbname)\""
    }
}

func getExecutableName(path: Path = Path()) -> String? {
    let res = shellWithOutput(launchPath: "/usr/bin/env", executable: "swift", arguments: [
        "package", "--chdir",
        path.absolute().description,
        "describe"
        ])

    let output = res.output
    guard output != "" && res.status == 0 else {
        return nil
    }

    let rows = output.components(separatedBy: "\n")
    var name: String? = nil
    for row in rows {
        if row.contains("Name: ") {
            name = row.components(separatedBy: " ").last!
        } else if row.contains("Type: executable") {
            return name
        }
    }

    return nil
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
