//
//  NewCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 11/5/17.
//

import SwiftCLI
import Foundation
import PathKit

class NewCommand: Command {
    let name: String = "new"
    let shortDescription = "Creates new project from template"
    private let templateName = Parameter()
    private let type = Key<String>("-t", "--type", description: "Values: \(NewCommand.typeValuesDescription)")
    private static let typeValues: [Types] = [.web]
    private static var typeValuesDescription: String {
        return "[\(typeValues.map{$0.rawValue}.joined(separator: "|"))]"
    }
    enum Types: String {
        case web
    }
    func execute() throws {
        guard self.type.value != nil, let type = Types(rawValue: self.type.value!) else {
            throw CLI.Error(message:"Bad value for --type, expected one of \(NewCommand.typeValuesDescription)")
        }
        switch type {
        case .web:
            let url = "https://github.com/Swift-Squirrel/WebTemplate.git"
            guard Git.clone(url: url, to: templateName.value) == 0 else {
                throw CLI.Error(message: "Git clone failed")
            }

            let dir = Path() + templateName.value
            let moduleDir = dir + "Sources/WebTemplate"
            guard moduleDir.exists && moduleDir.isDirectory else {
                throw CLI.Error(message: "\(moduleDir.absolute().string) does not exists or is not a directory")
            }
            let newModuleName = dir + "Sources/\(templateName.value)"
            try moduleDir.move(newModuleName)
            let package = dir + "Package.swift"
            try replaceContent(in: package, needle: "WebTemplate", with: templateName.value)
            try replaceContent(in: dir + ".squirrel.yaml", needle: "WebTemplate", with: templateName.value)
        }
    }

    private func replaceContent(in file: Path, needle: String, with: String) throws {
        guard file.exists && file.isFile && file.isWritable else {
            throw CLI.Error(message: "File does not exists or is not writable")
        }
        let content: String = try file.read()
        let newContent = content.replacingOccurrences(of: needle, with: with)
        try file.write(newContent)
    }
}

fileprivate struct Git {
    private static func runTask(arguments: [String]) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["git"] + arguments
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    static func clone(url: String, to: String? = nil) -> Int32 {
        var baseArgs = ["clone", url]
        if let dest = to {
            baseArgs.append(dest)
        }
        return runTask(arguments: baseArgs)
    }
}
