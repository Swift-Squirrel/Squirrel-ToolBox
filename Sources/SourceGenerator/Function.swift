//
//  Function.swift
//  SourceGenerator
//
//  Created by Filip Klembara on 10/6/17.
//

/// Function
public struct Function: SourceFunctionProtocol {
    private let name: String
    /// Function body
    public var body = [String]()
    private let isThrowing: Bool
    private let isMutating: Bool

    /// Constructs function
    ///
    /// - Parameters:
    ///   - name: Name
    ///   - isThrowing: if is throwing (default: false)
    ///   - isMutating: if is mutating (default: false)
    public init(name: String, throws isThrowing: Bool = false, mutating isMutating: Bool = false) {
        self.name = name
        self.isThrowing = isThrowing
        self.isMutating = isMutating
    }

    /// Intended code
    ///
    /// - Parameter intends: Intends
    /// - Returns: Intended code
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
