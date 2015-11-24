//
//  Benchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/23/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation

enum Lifecycle : String {
    case START = "START"
    case START_TIME = "START_TIME"
    case OPEN = "OPEN"
    case FIRST_BYTE = "FIRST_BYTE"
    case LAST_BYTE = "LAST_BYTE"
    case CLOSED = "CLOSED"
    
    // http://stackoverflow.com/questions/24113126/how-to-get-the-name-of-enumeration-value-in-swift
    var stringName: String {
        get {
            return self.rawValue
        }
    }
}

protocol ResultMgr {
    func addResult(result: Results, forIndex i: Int)
}

class Benchmarker: NSObject/*<-necessary*/ {
    var collectedData = Results()
    var resultMgr: ResultMgr?
    init(resultMgr: ResultMgr?) {
        self.resultMgr = resultMgr
    }
    
    // `!` means it doesn't have to be init'd in init()
    var START_TIME: Int!
    
    func timestampEvent(event: Lifecycle) {
        if event == .START {
            START_TIME = now()
            collectedData[.START_TIME] = START_TIME
        }
        // # MICROSECONDS elapsed
        collectedData[event] = now() - START_TIME
    }
    
    /** turns a number of seconds given as a Double
     into a number of microseconds as an Int
     */
    func secDblToMicroInt(intvl: NSTimeInterval) -> Int {
        return Int(intvl * 1E6)
    }
    
    func now() -> Int {
        // NSDate objects encapsulate a SINGLE point in
        // time and are IMMUTABLE.
        return secDblToMicroInt(NSDate().timeIntervalSince1970)
    }
}