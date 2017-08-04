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

class CreateCommand: Command {
    let name = "create"
    let shortDescription = "Create model, controller or another file"

    let type = Key<String>("-t", "--type", usage: "Values: [model]")
    let typeValues = ["model"]

    let fileName = Parameter()

    var exeName = ""

    func execute() throws {
        guard let type = type.value, typeValues.contains(type) else {
            throw CLIError.error("Bad value for --type, expected one of [\(typeValues.joined(separator: "|"))]")
        }

        guard let pom = getExecutableName() else {
            throw CLIError.error("Can not get executable name, check if you are in project root directory")
        }

        exeName = pom

        let fileName = self.fileName.value

        guard !fileName.contains(" ") && !fileName.contains(".") else {
            throw CLIError.error("fileName must be one word without '.' character")
        }

        switch type {
        case "model":
            createModel(name: fileName)
        default:
            throw CLIError.error("Bad value for --type, expected one of [\(typeValues.joined(separator: "|"))], got \(type)")
        }
    }

    private func createModel(name: String) {
        let modelDirPath = Path(components: [Path().absolute().description, "Sources", exeName, "Models", "Database", "Tables"])
        if !modelDirPath.exists {
            try! modelDirPath.mkpath()
        }

        let modelPath = Path(components: [modelDirPath.absolute().description, name.capitalized + ".swift"])
        if modelPath.exists {
            guard Input.awaitYesNoInput(message: "File alraady exists, do you want to override it?") else {
                return
            }
        }
        let generator = SourceGenerator()
        generator.imports += ["Foundation", "SquirrelConnector"]
        var modelStruct = SourceStruct(name: modelPath.lastComponentWithoutExtension, protocols: ["ModelProtocol"])
        modelStruct.inits.append(SourceInit(variables: []))
        modelStruct.variables += [
            SourceVariable(name: "created", value: "Date()"),
            SourceVariable(name: "modified", value: "Date()")
        ]
        generator.content.append(modelStruct)
        print(generator.generate)
        try! modelPath.write(generator.generate)
    }
}
