//
//  TCPBenchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/4/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

/**
 
 TODO: make a renew() function or something so this thing drops all its
       data and can be re-used
 
 What this does is
 
 1. Connects to `syncCount` TCP servers at ports
 `BASE_PORT...BASE_PORT+syncCount-1`
 2. Collects performance data about those TCP connections
 3. Uploads the data to the Sinatra `dataserver.rb`
 */
class TcpBenchmarker: ResultMgr {
    
    /** Array of connections to each TCP server from which we shall
     concurrently download
     */
    var conns = [EventedConn]()
    
    /** Array of benchmark datapoints for each TCP server.
     Once these are collected they will be automatically uploaded
     to the DataServer
     */
    var results = [Results]()
    
    /** how many TCP servers to connect and download concurrently from */
    var syncCount: Int?
    
    /** how many TCP servers we have finished collecting performance data for */
    var done = 0
    
    var sema: Semaphore?
    
    var bytesToDwnld: Int?
    
    init(syncCount: Int, bytesToDwnld: Int, sema: Semaphore? = nil) {
        self.syncCount = syncCount
        self.bytesToDwnld = bytesToDwnld
        
        if let s = sema {
            self.sema = s
        }
        
        for _ in 1...syncCount {
            conns.append(EventedConn(resultMgr: self))
            results.append([:])
        }
    }
    
    /**
     Asynchronous method
     
     1. initiates `syncCount` connections
     2. collects performance benchmarks
     3. uploads collected data to `dataserver.rb`
     */
    func collectAndUploadResults() {
        print("collecting results")
        for i in 0..<syncCount! {
            self.conns[i].recordDataFor(
                "localhost",
                onPort:BASE_PORT+i,
                bytesToDwnld: bytesToDwnld!
            )
        }
    }
    
    // TODO: perhaps this should call a function on a DataUploader object
    //       that can be reused across experiments
    func uploadResults() {
        let DATASERVER_PORT = 4567 // default Sinatra port is 4567
        print("uploading results: \(resultsAsJson())")
        let request = Alamofire.request(.POST,
            "http://localhost:\(DATASERVER_PORT)/data",
            parameters: [
                "conns": syncCount!,
                "exper": "TCP",
                "results": resultsConv(),
                "bytes": bytesToDwnld!
            ],
            encoding: .JSON
        )
        debugPrint(request)
        if let s = self.sema {
            s.signal()
        }
    }
    
    private func resultsConv() -> [[String : Int]] {
        var ugh = [[String:Int]]()
        for resultData in results {
            var dict = [String:Int]()
            for (k, v) in resultData {
                dict[k.stringName] = v
            }
            ugh.append(dict)
        }
        return ugh
    }
    
    private func resultsAsJson() -> JSON {
        // there must be a better way...needs combinators
        var ugh = [JSON]()
        for resultData in results {
            var dict = [String:JSON]()
            for (k, v) in resultData {
                dict[k.stringName] = JSON(v)
            }
            ugh.append(JSON(dict))
        }
        return JSON(ugh)
    }
    
    /** called by the EventedConn as part of implementing the `
        ResultMgr` protocol.
    */
    func addResult(result: Results, forIndex i: Int) {
        results[i] = result
        print("added result \(result) to \(i)")
        done++
        if done == syncCount {
            uploadResults()
        }
    }
}

// https://gist.github.com/JadenGeller/c0a97893d4a35a960289
struct Semaphore {
    
    let semaphore: dispatch_semaphore_t
    
    init(value: Int = 0) {
        semaphore = dispatch_semaphore_create(value)
    }
    
    // Blocks the thread until the semaphore is free and returns true
    // or until the timeout passes and returns false
    func wait(nanosecondTimeout: Int64) -> Bool {
        return dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, nanosecondTimeout)) != 0
    }
    
    // Blocks the thread until the semaphore is free
    func wait() {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    // Alerts the semaphore that it is no longer being held by the current thread
    // and returns a boolean indicating whether another thread was woken
    func signal() -> Bool {
        return dispatch_semaphore_signal(semaphore) != 0
    }
}