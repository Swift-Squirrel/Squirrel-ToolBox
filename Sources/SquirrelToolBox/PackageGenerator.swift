//
//  PackageGenerator.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/1/17.
//
//

import Foundation

struct PackageGenerator {
    init(name: String) {
        self.name = name
    }
    let name: String

    var version: String = "4.0"

    var dependencies = [Dependency]()
    struct Dependency: CustomStringConvertible {
        let name: String
        let url: String
        let from: String

        init(name: String, url: String, from: String) {
            self.url = url
            self.from = from
            self.name = name
        }

        var description: String {
            return ".package(url: \"\(url)\", from: \"\(from)\")"
        }
    }

    func generate() -> String {
        var dependenciesString = ""
        if dependencies.count > 0 {
            dependenciesString = dependencies.flatMap({ String(describing: $0) }).joined(separator: ",\n\t\t")
            dependenciesString = ",\n\tdependencies: [\n\t\t" + dependenciesString + "\n\t]"

        }
        var targets = ""
        targets = dependencies.map({ "\"\($0.name)\""}).joined(separator: ", ")
        targets = ",\n\ttargets: [\n\t\t.target(\n\t\t\tname: \"\(name)\",\n\t\t\tdependencies: [\(targets)]),\n\t]"
        return "// swift-tools-version:\(version)\n\nimport PackageDescription\n\nlet package = Package(\n\tname: \"\(name)\""
        + ",\n\tproducts: [\n\t.executable(\n\t\tname: \"\(name)\",\n\t\ttargets: [\"\(name)\"]),\n\t]\(dependenciesString)\(targets)\n)\n"
    }
}
