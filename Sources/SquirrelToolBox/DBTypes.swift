//
//  DBTypes.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/14/17.
//
//

import Yaml

enum DBTypes {
    case mysql

    func parse(yaml: [Yaml: Yaml]) -> [String: Any] {
        switch self {
        case .mysql:
            return parseMySQL(yaml: yaml)
        }
    }

    private func parseMySQL(yaml: [Yaml: Yaml]) -> [String: Any] {
        var res = [String: Any]()
        for (keyYaml, valueYaml) in yaml {
            guard let name = keyYaml.string else {
                continue
            }
            switch name {
            case "host":
                guard let value = valueYaml.string else {
                    continue
                }
                res[name] = value
            case "username":
                guard let value = valueYaml.string else {
                    continue
                }
                res[name] = value
            case "dbname":
                guard let value = valueYaml.string else {
                    continue
                }
                res[name] = value
            case "password":
                guard let value = valueYaml.string else {
                    continue
                }
                res[name] = value
            case "port":
                guard let value = valueYaml.int else {
                    continue
                }
                res[name] = value
            default:
                break
            }
        }
        if res["port"] == nil {
            res["port"] = 3306
        }
        return res
    }

    var package: PackageGenerator.Dependency {
        switch self {
        case .mysql:
            return PackageGenerator.Dependency(
                url: "https://github.com/LeoNavel/Squirrel-MySQL.git",
                major: "0"
            )
        }
    }

    var imp: String {
        switch self {
        case .mysql:
            return "import SquirrelMySQL"
        }
    }

    var connectorName: String {
        switch self {
        case .mysql:
            return "MySQLConnector"
        }
    }
}
