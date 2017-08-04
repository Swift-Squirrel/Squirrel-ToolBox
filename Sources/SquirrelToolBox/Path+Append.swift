//
//  Path+Append.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 7/31/17.
//
//

import PathKit
import Foundation

extension Path {
    func append(_ data: Data) throws {
        let path = absolute().description
        if exists {
            if let fileHandle = try? FileHandle(forUpdating: url) {
                defer {
                    fileHandle.closeFile()
                }
                fileHandle.seekToEndOfFile()
                fileHandle.write(data)
                fileHandle.closeFile()

            }
        } else {
            try write(data)
        }
    }

    func append(_ string: String) throws {
        if let data = string.data(using: .utf8) {
            try append(data)
        } else {
            print("Error")  // TODO else
        }
    }
}
