//
//  SeedCommand.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/13/17.
//
//

import SwiftCLI
import PathKit
import Progress

class SeedCommand: Command {

    let name = "seed"
    let shortDescription = "run seeders"
    let current = Path()
    var tablesDir: Path = Path()
    var destRoot: Path = Path()
    var sourcesDir: Path = Path()
    var seedersDir = Path()
    var exeName: String = ""

    
    func execute() throws {

        var progress = ProgressBar(count: 7)
        progress.next()
        guard let exName = getExecutableName() else {
            return
        }
        exeName = exName
        tablesDir = Path(components: [current.absolute().description, "Sources/" + exeName + "/Models/Database/Tables"])
        seedersDir = Path(components: [current.absolute().description, "Sources/" + exeName + "/Models/Database/Seeders"])
        destRoot = Path(components: [current.absolute().description, ".squirrel", "Seeders"])
        sourcesDir = Path(components: [destRoot.absolute().description, "Sources/Seeders"])
        let config = current + "squirrel.yaml"
        progress.next()
        let (db, data) = try getDB(from: config)

        guard tablesDir.exists else {
            return
        }
        guard seedersDir.exists else {
            return
        }
        progress.next()
        try! destRoot.mkpath()
        try! sourcesDir.mkpath()
        progress.next()
        let tables = tablesDir.glob("*.swift")
        copySeeders(tables: tables)
        let seeders = seedersDir.glob("*.swift")
        copySeeders(tables: seeders)
        progress.next()
        let seedersString = seeders.flatMap({ $0.lastComponentWithoutExtension + "()" }).joined(separator: ", ")
        let main = Path(components: [sourcesDir.absolute().description, "main.swift"])
        var mainString = "import SquirrelSeederManager\nimport SquirrelConnector\n\n"
        mainString += db.imp + "\n\n"

        let dbDataString = data.map( { "    \"" + $0.key + "\": " + stringRepresentation(of: $0.value) } ).joined(separator: ",\n    ")
        mainString += "let dbData: [String: Any] = [\n    " + dbDataString + "\n]\n\n"
        mainString += "let connector = try \(db.connectorName)(with: dbData)\n\n"
        mainString += "let _ = Connector.set(connector: connector)\n\n"

        mainString += "let manager = SeederManager(seeders: [\(seedersString)])\n\n"
        mainString += "manager.seeds()\n"
        try? main.write(mainString)
        let package = Path(components: [destRoot.absolute().description, "Package.swift"])
        var packageGenerator = PackageGenerator(name: "Seeders")
        packageGenerator.dependencies.append(
            db.package
        )
        packageGenerator.dependencies.append(
            PackageGenerator.Dependency(
                url: "https://github.com/LeoNavel/Squirrel-SeederManager.git",
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

    private func copySeeders(tables: [Path]) {
        for table in tables {
            let dest = Path(components: [sourcesDir.absolute().description, table.lastComponent])
            if dest.exists {
                try! dest.delete()
            }
            try! table.copy(dest) // TODO
        }
    }
}

