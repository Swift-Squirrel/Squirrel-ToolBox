//
//  SourcePartProtocol.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 8/4/17.
//
//

public protocol SourcePartProtocol {
    func intendedDescription(intends: String) -> String
    
}

public protocol SourceVariableProtocol: SourcePartProtocol {
    
}

public protocol SourceInitProtocol: SourcePartProtocol {

}

public protocol SourceFunctionProtocol: SourcePartProtocol {
    
}

