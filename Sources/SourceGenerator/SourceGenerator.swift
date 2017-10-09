//
//  SourceGenerator.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/4/17.
//
//

/// Source Generator
public class SourceGenerator {

    /// Constructs Source Generator
    public init() {}

    /// Imports
    public var imports = [String]()

    /// Content
    public var content = [SourcePartProtocol]()

    /// Generates code
    public var generate: String {
        var res = imports.map { "import \($0)" }.joined(separator: "\n")
        res += "\n"
        content.forEach { (cont) in
            res += "\n"
            res += cont.intendedDescription(intends: "")
            res += "\n"
        }
        res += "\n"
        return res
    }

}
