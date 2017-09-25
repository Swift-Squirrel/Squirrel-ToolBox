//
//  WatchCommand.swift
//  SquirrelToolBoxPackageDescription
//
//  Created by Filip Klembara on 9/22/17.
//

import PathKit
import SwiftCLI
import Foundation
import Signals

class WatchCommand: Command {
    var name: String = "watch"

    let shortDescription = "Watch for changes in directory and rerun server"

    private func getFiles(from path: Path) -> [Path] {
        let items = path.glob("*")
        var files = [Path]()
        for item in items {
            if item.isFile && item.extension == "swift" {
                files.append(item)
            } else if item.isDirectory {
                files.append(contentsOf: getFiles(from: item))
            }
        }

        return files
    }

    func fileModificationDate(path: Path) -> Date? {
        let url = path.url
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }

    private var info: [Path: Date] = [:]

    private static var currenTask: Process? = nil {
        willSet {
            if let old = currenTask {
                old.terminationHandler = nil
                old.terminate()
            }
        }
    }

    private static var currentBuild: Process? = nil {
        didSet {
            oldValue?.terminate()
        }
    }

    private func check(path: Path) -> Bool {
        let files = getFiles(from: path)
        var rerun = false
        for file in files {
            if let oldModif = info[file] {
                if let lastModif = fileModificationDate(path: file), lastModif > oldModif {
                    rerun = true
                    info[file] = lastModif
                }
            } else {
                if let lastModif = fileModificationDate(path: file) {
                    info[file] = lastModif
                    rerun = true
                }
            }
        }
        if shouldRerun {
            shouldRerun = false
            return true
        }
        return rerun
    }
    private var build: UInt64 = 0
    private var shouldRerun: Bool = false

    private func rerun(executable exe: String) {
        print("building")
        build += 1
        let localBuild = build
        let buildTask = Process()
        WatchCommand.currentBuild = buildTask
        buildTask.launchPath = "/usr/bin/env"
        buildTask.arguments = ["swift", "build", "--package-path", Path().absolute().string]
        buildTask.standardOutput = FileHandle.standardOutput
        buildTask.standardError = FileHandle.standardError
        buildTask.launch()
        buildTask.waitUntilExit()
        if buildTask.terminationStatus == 0 {
            print("\(Date()): build successful")
            guard localBuild == build else {
                return
            }
            let path = Path().absolute() + ".build/debug"
            let task = createTask(launchPath: path, executable: exe, detached: true)
            WatchCommand.currenTask?.terminate()
            task.launch()
            task.terminationHandler = {
                [weak self] _ in
                guard let ss = self else {
                    return
                }
                ss.shouldRerun = true
            } as ((Process) -> Void)
            WatchCommand.currenTask = task
            shouldRerun = false
            signalTrap()
        }
    }

    private func signalTrap() {
        Signals.trap(signals: [.int, .abrt, .kill, .term, .quit]) {
            signal in
            WatchCommand.currenTask?.terminate()
            exit(signal)
        }
    }

    func execute() throws {
        let package = Path().absolute() + "Package.swift"
        guard package.exists, let lastModif = fileModificationDate(path: package) else {
            throw CLI.Error(message: "Package.swift does not exists")
        }
        guard let exeName = getExecutableName() else {
            throw CLI.Error(message: "Can not get executable")
        }
        info[package] = lastModif
        let path = Path().absolute() + "Sources"
        while true {
            DispatchQueue.global(qos: .background).async {
                [weak self] in
                guard let ss = self else {
                    return
                }
                if ss.check(path: path) {
                    ss.rerun(executable: exeName)
                }
            }
            sleep(1)
        }
    }
    deinit {
        WatchCommand.currenTask?.terminate()
        WatchCommand.currentBuild?.terminate()
    }
}
