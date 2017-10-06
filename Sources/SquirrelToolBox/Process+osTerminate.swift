//
//  Process+osTerminate.swift
//  SquirrelToolBox
//
//  Created by Filip Klembara on 10/6/17.
//

import Foundation

extension Process {
    func osTerminate() {
        guard isRunning else {
            return
        }
        #if os(Linux)
            kill(pid: processIdentifier)
        #else
            terminate()
        #endif
    }
}
