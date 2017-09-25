//
//  Migration.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/3/17.
//
//

import SwiftCLI
import PathKit
import Progress
import Yaml

class MigrationCommand: Command {
    let name = "migrate"
    let shortDescription = "Create migrations"
    let current = Path().absolute()
    var tablesDir: Path = Path()
    var destRoot: Path = Path()
    var sourcesDir: Path = Path()
    var exeName: String = ""

    

    func execute() throws {
        var progress = ProgressBar(count: 7)
        progress.next()
        guard let exName = getExecutableName() else {
            throw CLI.Error(message: "Could not resolve executable name", exitStatus: 1)
        }
        exeName = exName
        tablesDir = current + ("Sources/" + exeName + "/Models/Database/Tables")
        destRoot = current + ".squirrel/Migration"
        sourcesDir = destRoot + "Sources/Migration"
        let config = current + ".squirrel.yaml"

        progress.next()

        let dbData = try getDB(from: config)

        progress.next()
        guard tablesDir.exists else {
            throw CLI.Error(message: "\(tablesDir.string) does not exists", exitStatus: 1)
        }
        try! destRoot.mkpath()
        try! sourcesDir.mkpath()

        progress.next()
        let tables = tablesDir.glob("*.swift")
        copyTables(tables: tables)
        progress.next()
        let tablesString = tables.flatMap({ $0.lastComponentWithoutExtension + ".self" }).joined(separator: ", ")
        let main = Path(components: [sourcesDir.absolute().description, "main.swift"])
        var mainString = "import SquirrelMigrationManager\nimport SquirrelConnector\n"

        mainString += "guard Connector.set(\(dbData)) else {\n    print(\"Can not set connector\")\n    exit(1)\n\n"
        mainString += "let models: [ModelProtocol] = [\(tablesString)]\n\n"
        mainString += "let manager = MigrationManager(models: models)\n\n"
        mainString += "manager.migrate()\n"
        try? main.write(mainString)
        let package = Path(components: [destRoot.absolute().description, "Package.swift"])
        var packageGenerator = PackageGenerator(name: "Migration")
        packageGenerator.dependencies.append(
            PackageGenerator.Dependency(
                name: "SquirrelConnector",
                url: "https://github.com/LeoNavel/Squirrel-Connector.git",
                from: "0.1.1"
            )
        )
        packageGenerator.dependencies.append(
            PackageGenerator.Dependency(
                name: "SquirrelMigrationManager",
                url: "https://github.com/LeoNavel/Squirrel-MigrationManager.git",
                from: "0"
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
