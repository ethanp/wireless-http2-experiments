//
//  Benchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/23/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
import ReachabilitySwift
import SwiftyJSON

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
     Once these are collected they are auto-uploaded
     to the `DataServer`
     */
    var results = [Results?]()

    /** how many datapoints we have already collected */
    var done = 0
    
    let sema = Semaphore()

    init(numResults: Int) {
        results.reserveCapacity(numResults)
    }
    
    /** This method MUST be overriden (otw RuntimeException!)
     What I want is an `abstract class` but I haven't found a
     way to do that in Swift
     */
    func uploadResults() {
        print("method not implemented")
        fatalError()
    }
    
    func addResult(result: Results, forIndex i: Int) {
        results[i] = result
        if ++done == results.count {
            print("uploading results: \(resultsAsJson())")
            uploadResults()
            sema.signal()
        }
    }

    /** learning Swift */
    func resultsConv() -> [[String : Int]] {
        if results.contains(nill) {
            print("missing a result")
            fatalError()
        }
        func extractRawValues(result: Results?) -> [String : Int] {
            return result!.mapPairs {
                (k, v) in (k.rawValue, v)
            }
        }
        
        return results.map(extractRawValues)
    }
    
    private func resultsAsJson() -> JSON {
        var ugh = [JSON]()
        for resultData in results {
            var dict = [String:JSON]()
            if let result = resultData {
                for (k, v) in result {
                    dict[k.rawValue] = JSON(v)
                }
                ugh.append(JSON(dict))
            } else {
                print("result missing")
                fatalError()
            }
        }
        return JSON(ugh)
    }
    
    func getOnWifi() -> Bool {
        let reachability : Reachability
        do {
            reachability = try Reachability
                .reachabilityForInternetConnection()
        }
        catch {
            print("Unable to create Reachability")
            fatalError()
        }
        return reachability.isReachableViaWiFi()
    }
}

class Benchmarker: NSObject/*<-necessary*/ {
    var collectedData = Results()
    var resultMgr: ResultMgr?
    init(resultMgr: ResultMgr?) {
        self.resultMgr = resultMgr
    }
    
    /** `!` means it doesn't have to be init'd in `init()` */
    var START_TIME: Int!
    
    /** Records the number of *microseconds* elapsed since
     recording the last `.START` */
    func timestampEvent(event: Lifecycle) {
        if event == .START {
            START_TIME = now()
            collectedData[.START_TIME] = START_TIME
        }
        // record microseconds elapsed
        collectedData[event] = now() - START_TIME
    }
    
    /** (_seconds_`:Double`) -> _microseconds_`:Int` */
    func secDblToMicroInt(intvl: NSTimeInterval) -> Int {
        return Int(intvl * 1E6)
    }
    
    /** Current time as _microsecond_`:Int` */
    func now() -> Int {
        // NSDate objects encapsulate a SINGLE point in
        // time and are IMMUTABLE.
        return secDblToMicroInt(NSDate().timeIntervalSince1970)
    }
}

// from stackoverflow.com/a/24219069/1959155
extension Dictionary {
    init(_ pairs: [Element]) {
        self.init()
        for (k, v) in pairs {
            self[k] = v
        }
    }
    
    func mapPairs<OutKey: Hashable, OutValue>(@noescape transform: Element throws -> (OutKey, OutValue)) rethrows -> [OutKey: OutValue] {
        return Dictionary<OutKey, OutValue>(try map(transform))
    }
    
    func filterPairs(@noescape includeElement: Element throws -> Bool) rethrows -> [Key: Value] {
        return Dictionary(try filter(includeElement))
    }
}

// this is silly, but I like it
func nill<T>(arg: T?) -> Bool { return arg == nil }
