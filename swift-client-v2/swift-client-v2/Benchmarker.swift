//
//  Benchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/23/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
import ReachabilitySwift

enum Lifecycle: String {
    case START = "START"
    case START_TIME = "START_TIME"
    case OPEN = "OPEN"
    case FIRST_BYTE = "FIRST_BYTE"
    case LAST_BYTE = "LAST_BYTE"
    case CLOSED = "CLOSED"
}

 class ResultMgr {
    /** Array of benchmark datapoints for each server.
     Once these are collected they should be uploaded to the DataServer
     */
    
    var results: [Results?]!

    /** how many datapoints we have already collected */
    var done = 0
    
    var sema = Semaphore()

    init(numResults: Int) {
        self.results = [Results?](
            count: numResults,
            repeatedValue: nil
        )
    }
    
    /** This method MUST be overriden (otw RuntimeException!) */
    func uploadResults() {
        print("method not implemented")
        fatalError()
    }
    
    func addResult(result: Results, forIndex i: Int) {
        results[i] = result
        if ++done == results.count {
            uploadResults()
            sema.signal()
        }
    }
    
    func resultsConv() -> [[String : Int]] {
        var ugh = [[String:Int]]()
        for resultData in results {
            if let result = resultData {
                var dict = [String:Int]()
                for (k, v) in result {
                    dict[k.rawValue] = v
                }
                ugh.append(dict)
            }
            else {
                print("missing a result")
                fatalError()
            }
        }
        return ugh
    }
    
    func getOnWifi() -> Bool {
        let reachability : Reachability
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        }
        catch {
            print("Unable to create Reachability")
            fatalError()
        }
        
        if reachability.isReachableViaWiFi() {
            print("Reachable via WiFi")
            return true
        }
        else {
            print("Reachable via Cellular")
            return false
        }
    }
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
    
    /** return right now's time into a micro-second */
    func now() -> Int {
        // NSDate objects encapsulate a SINGLE point in
        // time and are IMMUTABLE.
        return secDblToMicroInt(NSDate().timeIntervalSince1970)
    }
}