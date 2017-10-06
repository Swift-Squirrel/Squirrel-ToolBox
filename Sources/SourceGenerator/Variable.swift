//
//  Variable.swift
//  SourceGenerator
//
//  Created by Filip Klembara on 10/6/17.
//

/// Variable
public struct Variable: SourceVariableProtocol {
    /// Intended code
    ///
    /// - Parameter intends: Intends
    /// - Returns: Intended code
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

    private let name: String
    private let type: String?
    private let value: String?

    /// Constructs variable
    ///
    /// - Parameters:
    ///   - name: Name
    ///   - value: Value
    public init(name: String, value: String) {
        self.name = name
        self.type = nil
        self.value = value
    }

    /// Constructs variable
    ///
    /// - Parameters:
    ///   - name: Name
    ///   - type: Type
    public init(name: String, type: String) {
        self.name = name
        self.type = type
        self.value = nil

    }

    /// Constructs variable
    ///
    /// - Parameters:
    ///   - name: Name
    ///   - type: Type
    ///   - value: Value
    public init(name: String, type: String, value: String) {
        self.name = name
        self.type = type
        self.value = value
    }
}
