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
        tablesDir = Path(components: [current.absolute().description, "Sources/Squirrel/Models/Database/Tables"])
        destRoot = Path(components: [current.absolute().description, ".squirrel", "Migration"])
        sourcesDir = Path(components: [destRoot.absolute().description, "Sources/Migration"])
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
        let tablesString = tables.flatMap({ $0.lastComponentWithoutExtension + "()" }).joined(separator: ", ")
        let main = Path(components: [sourcesDir.absolute().description, "main.swift"])
        var mainString = "import SquirrelMigrationManager\n\n"
        mainString += "let manager = MigrationManager(models: [\(tablesString)])\n\n"
        mainString += "manager.migrate()\n"
        try? main.write(mainString)
        let package = Path(components: [destRoot.absolute().description, "Package.swift"])
        var packageGenerator = PackageGenerator(name: "Migration")
        packageGenerator.dependencies.append(
            PackageGenerator.Dependency(
                url: "https://github.com/LeoNavel/MySqlSwiftNative.git",
                major: "1",
                minor: "3" 
            )
        )
        packageGenerator.dependencies.append(
            PackageGenerator.Dependency(
                url: "https://github.com/LeoNavel/Squirrel-MigrationManager.git",
                major: "0"
            )
        )
        try? package.write(packageGenerator.generate())
        progress.next()
        swiftBuild(root: destRoot, configuration: "release")
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

class ServeCommand: Command {
    let name = "serve"

    let shortDescription = "Run server"

    private let detach = Flag("-d", "--detach", usage: "Run in background")
    private let build = Flag("-b", "--build", usage: "Build project before run")
    private let configuration = Key<String>("-c", "--configuration", usage: "Values: debug|release (default: debug)")
    private let configurationValues = ["debug", "release"]

    func execute() throws {
        let conf = configuration.value ?? configurationValues.first!
        guard configurationValues.contains(conf) else {
            throw CLIError.error("--configuration expects \(configurationValues.joined(separator: "|")) but \(conf) given.")
        }
        let path = Path(components: [Path().absolute().description, ".build/" + conf])
        guard let exe = getExecutableName() else {
            print("error")
            throw CLIError.error("Error in parsing Package.swift")
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
