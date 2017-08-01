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
import Progress

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
        CLI.register(commands: [ServeCommand(), StopCommand(), Migration()])
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

class Migration: Command {
    let name = "migrate"
    let shortDescription = "Create migrations"
    let current = Path()
    let tablesDir: Path
    let destRoot: Path
    let sourcesDir: Path



    init() {
        tablesDir = Path(components: [current.absolute().description, "Sources/App/Models/Database/Tables"])
        destRoot = Path(components: [current.absolute().description, ".squirrel", "Migration"])
        sourcesDir = Path(components: [destRoot.absolute().description, "Sources"])
    }

    func execute() throws {
        print("migrate")
               guard tablesDir.exists else {
            return
        }
        var progress = ProgressBar(count: 4)
        progress.next()
        let tables = tablesDir.glob("*.swift")
        copyTables(tables: tables)
        progress.next()
        let main = Path(components: [sourcesDir.absolute().description, "main.swift"])
        try? main.write("let users = User(id: 3, name: \"Tom\")\nprint(users.id)\nprint(users.name)\n")
        let package = Path(components: [destRoot.absolute().description, "Package.swift"])
        try? package.write("// swift-tools-version:3.1\nimport PackageDescription\nlet package = Package(\n\tname: \"Migration\"\n)")
        progress.next()
        swiftBuild(root: destRoot)
        progress.next()
        swiftRun(root: destRoot)
        progress.next()
    }

    private func copyTables(tables: [Path]) {
        for table in tables {
            let dest = Path(components: [sourcesDir.absolute().description, table.lastComponent])
            if dest.exists {
                try! dest.delete()
            }
            try! table.copy(dest) // TODO
        }
    }
}

func swiftRun(root path: Path) {
    let path = Path(components: [path.absolute().description, ".build/release"])
    let task = createTask(launchPath: path, executable: "Migration", detached: false)
    task.standardOutput = FileHandle.nullDevice
    task.standardError = FileHandle.nullDevice
    task.launch()
    task.waitUntilExit()
}

func swiftBuild(root path: Path) {
    let _ = shell(launchPath: "/usr/bin/env", executable: "swift", arguments: ["build", "--chdir", path.absolute().description, "-c", "release"])
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
