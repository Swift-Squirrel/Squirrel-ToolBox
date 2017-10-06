//
//  SourcePartProtocol.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/4/17.
//
//

/// Source part
public protocol SourcePartProtocol {
    func intendedDescription(intends: String) -> String
}

/// Variable
public protocol SourceVariableProtocol: SourcePartProtocol { }

/// Init of struct or class
public protocol SourceInitProtocol: SourcePartProtocol { }

/// Function
public protocol SourceFunctionProtocol: SourcePartProtocol { }
