//
//  Struct.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 10/6/17.
//

/// Source of struct
public struct Struct: SourcePartProtocol {
    /// Intended code
    ///
    /// - Parameter intends: Intends (default: "")
    /// - Returns: Intended code
    public func intendedDescription(intends: String = "") -> String {
        var res = intends + "struct \(name)"
        if protocols.count > 0 {
            res += ": " + protocols.joined(separator: ", ")
        }
        res += " {\n"
        inits.forEach { (ini) in
            res += "\n"
            res += ini.intendedDescription(intends: intends + "\t")
        }
        res += "\n"
        variables.forEach { variable in
            res += variable.intendedDescription(intends: intends + "\t")
        }

        if functions.count > 0 {
            res += "\n"
            functions.forEach({ (function) in
                res += function.intendedDescription(intends: intends + "\t")
            })
        }

        res += intends + "}\n"
        return res
    }

    /// Name
    public let name: String
    /// Protocols
    public var protocols = [String]()
    /// Variables
    public var variables = [SourceVariableProtocol]()
    /// Inits
    public var inits = [SourceInitProtocol]()
    /// Functions
    public var functions = [SourceFunctionProtocol]()

    /// Constructs struct
    ///
    /// - Parameters:
    ///   - name: Name
    ///   - protocols: Protocols
    public init(name: String, protocols: [String] = [String()]) {
        self.name = name
        self.protocols = protocols
    }
}

/// Source of Init
public struct Init: SourceInitProtocol {

    /// Body
    public var body = [String]()

    /// Variables
    private let variables: [(name: String, type: String)]

    /// Intended code
    ///
    /// - Parameter intends: Intends
    /// - Returns: Intended code
    public func intendedDescription(intends: String) -> String {
        var res = intends + "init("
        res += variables.map { "\($0.name): \($0.type)" }.joined(separator: ", ")
        res += ") {\n"
        if variables.count > 0 {
            res += variables.map { "\(intends)\tself.\($0.name) = \($0.name)"}
                .joined(separator: "\n") + "\n"
        }
        if body.count > 0 {
            res += "\n" + intends + "\t" + body.joined(separator: "\n\(intends)\t") + "\n"
        }
        res += intends + "}\n"
        return res
    }

    /// Constructs init of struct or class
    ///
    /// - Parameter variables: Variables
    public init(variables: [(name: String, type: String)]) {
        self.variables = variables
    }
}
