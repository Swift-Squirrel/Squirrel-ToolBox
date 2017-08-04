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

class MigrationCommand: Command {
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
