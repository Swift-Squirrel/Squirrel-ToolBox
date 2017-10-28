//
//  WatchCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 9/22/17.
//

import PathKit
import SwiftCLI
import Foundation
import Signals
#if os(Linux)
    import Dispatch
#endif

class WatchCommand: Command {
    var name: String = "watch"

    let shortDescription = "Watch for changes in directory and rerun server"

    private var info: [Path: Date] = [:]

    private var build: UInt64 = 0

    private var shouldRerun: Bool = false

    private static var currenTask: Process? = nil {
        willSet {
            if let old = currenTask {
                old.terminationHandler = nil
                old.osTerminate()
            }
        }
    }

    private static var currentBuild: Process? = nil {
        didSet {
            oldValue?.osTerminate()
        }
    }

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

    private func rerun() {
        build += 1
        print("Building (Build number: \(build))")
        let localBuild = build
        let buildTask = swift(command: .build, silenced: false)
        WatchCommand.currentBuild = buildTask
        buildTask.launch()
        buildTask.waitUntilExit()
        guard localBuild == build else {
            return
        }
        guard buildTask.terminationStatus == 0 else {
            print("Build \(localBuild) failed!")
            return
        }
        print("Build finished: \(build)")
        let runTask = swift(command: .run)
        runTask.terminationHandler = {
            [weak self] _ in
            guard let ss = self else {
                return
            }
            ss.shouldRerun = true
        }
        runTask.launch()
        WatchCommand.currenTask = runTask
        shouldRerun = false
        signalTrap()
    }

    private func signalTrap() {
        let signals: [Signals.Signal] = [.hup, .int, .quit, .abrt, .kill, .alrm, .term, .pipe]
        signals.forEach {
            signal in
            Signals.restore(signal: signal)
        }
        Signals.trap(signals: signals) {
            signal in
            WatchCommand.currenTask?.osTerminate()
            exit(signal)
        }
    }

    func execute() throws {
        let package = Path().absolute() + "Package.swift"
        guard package.exists, let lastModif = fileModificationDate(path: package) else {
            throw CLI.Error(message: "Package.swift does not exists")
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
                   ss.rerun()
                }
            }
            sleep(1)
        }
    }

    deinit {
        WatchCommand.currenTask?.osTerminate()
        WatchCommand.currentBuild?.osTerminate()
    }
}
