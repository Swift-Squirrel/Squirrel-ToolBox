//
//  CreateCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/4/17.
//
//

import SwiftCLI
import PathKit
import SourceGenerator
import Foundation

final class CreateCommand: Command {
    let name = "create"
    let shortDescription = "Create model, controller or another file"

    let type = Key<String>("-t", "--type", description: "Values: [model|layout|view|subview]")
    let typeValues = ["model", "view", "layout", "subview"]

    private let fileName = Parameter()

    private let currentDir = Path().absolute()
    private let nutExtension = ".nut"
    private let viewRoot = "Resources/NutViews"

    func execute() throws {
        guard let type = type.value, typeValues.contains(type) else {
            let typeValues = self.typeValues.joined(separator: "|")
            throw CLI.Error(message:"Bad value for --type, expected one of [\(typeValues)]")
        }

        let fileName = self.fileName.value

        guard !fileName.contains(" ") else {
            throw CLI.Error(message: "fileName must be one word character", exitStatus: 1)
        }

        let fullName = fileName.split(separator: ".")
            .map { $0.description.capitalized }
            .joined(separator: "/")

        let factory: (String) throws -> Void
        switch type {
        case "model":
            factory = createModel
        case "view":
            factory = createView
        case "layout":
            factory = createLayout
        case "subview":
            factory = createSubview
        default:
            let typeValues = self.typeValues.joined(separator: "|")
            throw CLI.Error(message: "Bad value for --type, expected one of [\(typeValues)]"
                + " but got \(type)")
        }
        try factory(fullName)
    }

    private func mkdirs(path: Path) throws -> Bool {
        let dir = path.parent().absolute()
        if !dir.exists {
            guard (try? dir.mkpath()) != nil else {
                throw CLI.Error(message: "Can not make path '\(dir.string)'")
            }
        }

        if path.exists {
            guard Input.awaitYesNoInput(
                message: "File alraady exists, do you want to override it?") else {

                    return false
            }
        }
        return true
    }

    private func createFile(path: Path, content: String) throws {
        guard try mkdirs(path: path) else {
            return
        }
        guard (try? path.write(content)) != nil else {
            throw CLI.Error(message: "Could not write to '\(path.string)', check your permissions")
        }
    }

    private func createSubview(name: String) throws {
        let file = currentDir + "\(viewRoot)/Subviews/\(name)\(nutExtension)"

        let string = """
        <!-- \(name).html -->
        <h2>\(name)</h2>
        """
        try createFile(path: file, content: string)
    }

    private func createLayout(name: String) throws {
        let file = currentDir + "\(viewRoot)/Layouts/\(name)\(nutExtension)"

        let string = """
            <!-- \(name).html -->
            <!DOCTYPE html>
            <html lang="en">
            <head>
                <meta charset="UTF-8">
            </head>
            <body>
                <h1>\(name)</h1>
                \\View()
            </body>
            </html>
            """

        try createFile(path: file, content: string)
    }

    private func createView(name: String) throws {
        let file = currentDir + "\(viewRoot)/Views/\(name)\(nutExtension)"

        let string = "<!-- \(name).html -->\n\n\\Title(\"\(name)\")\n\n<h1>\(name)</h1>\n"

        try createFile(path: file, content: string)
    }

    private func createModel(name: String) throws {
        let modelPath = currentDir + "Models/\(name).swift"

        let generator = SourceGenerator()
        generator.imports += ["Foundation", "SquirrelConnector"]
        var modelStruct = Struct(
            name: modelPath.lastComponentWithoutExtension,
            protocols: ["Model"])

        modelStruct.variables += [
            Variable(name: "id", type: "ObjectId?", value: "nil"),
            Variable(name: "created", value: "Date()"),
            Variable(name: "modified", value: "Date()")
        ]
        generator.content.append(modelStruct)
        try createFile(path: modelPath, content: generator.generate)
    }
}
