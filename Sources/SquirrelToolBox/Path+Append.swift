//
//  Path+Append.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 7/31/17.
//
//

import PathKit
import Foundation
import SwiftCLI

extension Path {
    func append(_ data: Data) throws {
        if exists {
            if let fileHandle = try? FileHandle(forUpdating: url) {
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()

            } else {
                throw CLI.Error(message: "Could not get file handle for path \(string)")
            }
        } else {
            guard (try? write(data)) != nil else {
                throw CLI.Error(message: "Could not write data to: \(string)")
            }
        }
    }

    func append(_ string: String) throws {
        if let data = string.data(using: .utf8) {
            try append(data)
        } else {
            throw CLI.Error(message: "Internal error - can not represent \(string) in utf8")
        }
    }
}
