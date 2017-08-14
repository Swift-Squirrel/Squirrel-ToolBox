public class SourceGenerator {

    public init() {

    }

    public var imports = [String]()

    public var content = [SourcePartProtocol]()

    public var generate: String {
        var res = imports.flatMap( { "import " + $0 }).joined(separator: "\n")
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

public struct SourceStruct: SourcePartProtocol {
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

    public let name: String
    public var protocols = [String]()
    public var variables = [SourceVariableProtocol]()
    public var inits = [SourceInitProtocol]()
    public var functions = [SourceFunctionProtocol]()

    public init(name: String, protocols: [String] = [String()]) {
        self.name = name
        self.protocols = protocols
    }
}

public struct SourceFunction: SourceFunctionProtocol {
    private let name: String
    public var body = [String]()
    private let isThrowing: Bool
    private let isMutating: Bool

    public init(name: String, throws isThrowing: Bool = false, mutating isMutating: Bool = false) {
        self.name = name
        self.isThrowing = isThrowing
        self.isMutating = isMutating
    }

    public func intendedDescription(intends: String) -> String {
        var res = intends
        if isMutating {
            res += "mutating "
        }
        res += "func \(name)() "
        if isThrowing {
            res += "throws "
        }
        res += "{\n"
        res += intends + "\t" + body.joined(separator: "\n\(intends)\t") + "\n"
        res += intends + "}\n"
        return res
    }
}

public struct SourceInit: SourceInitProtocol {
    public func intendedDescription(intends: String) -> String {
        var res = intends + "init("
        res += variables.map( { $0.name + ": " + $0.type } ).joined(separator: ", ")
        res += ") {\n"
        if variables.count > 0 {
            res += variables.map( { intends + "\tself." + $0.name + " = " + $0.name } ).joined(separator: "\n") + "\n"
        }
        if body.count > 0 {
            res += "\n" + intends + "\t" + body.joined(separator: "\n\(intends)\t") + "\n"
        }
        res += intends + "}\n"
        return res
    }

    public var body = [String]()

    private let variables: [(name: String, type: String)]

    public init(variables: [(name: String, type: String)]) {
        self.variables = variables
    }
}

public struct SourceVariable: SourceVariableProtocol {
    public func intendedDescription(intends: String = "") -> String {
        var res = intends + "var "
        res += name
        if let type = self.type {
            res += ": " + type
        }
        if let value = self.value {
            res += " = " + value
        }
        res += "\n"
        return res
    }

    let name: String
    let type: String?
    let value: String?

    public init(name: String, value: String) {
        self.name = name
        self.type = nil
        self.value = value
    }

    public init(name: String, type: String) {
        self.name = name
        self.type = type
        self.value = nil

    }

    public init(name: String, type: String, value: String) {
        self.name = name
        self.type = type
        self.value = value
    }
}
