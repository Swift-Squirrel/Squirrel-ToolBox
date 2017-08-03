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

    var version: String = "3.1"

    var dependencies = [Dependency]()
    struct Dependency: CustomStringConvertible {
        let url: String
        let major: String
        let minor: String?

        init(url: String, major: String, minor: String? = nil) {
            self.url = url
            self.major = major
            self.minor = minor
        }

        var description: String {
            var minorString = ""
            if let minor = minor {
                minorString = ", minor: \(minor)"
            }

            return ".Package(url: \"\(url)\", majorVersion: \(major)\(minorString))"
        }
    }

    func generate() -> String {
        var dependenciesString = ""
        if dependencies.count > 0 {
            dependenciesString = dependencies.flatMap({ String(describing: $0) }).joined(separator: ",\n\t\t")
            dependenciesString = ",\n\tdependencies: [\n\t\t" + dependenciesString + "\n\t]"

        }
        return "// swift-tools-version:\(version)\n\nimport PackageDescription\n\nlet package = Package(\n\tname: \"\(name)\"\(dependenciesString)\n)"
    }
}
