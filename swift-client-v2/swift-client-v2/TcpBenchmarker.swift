//
//  TCPBenchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/4/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
import SwiftyJSON

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
    
    init(syncCount: Int) {
        self.syncCount = syncCount
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
        for i in 0...syncCount!-1 {
            self.conns[i].recordDataFor("localhost", onPort:BASE_PORT+i, bytesToDwnld: 5)
        }
    }
    
    /** called by the EventedConn as part of implementing the `
        ResultMgr` protocol.
    */
    func addResult(result: Results, forIndex i: Int) {
        results[i] = result
        print("added result \(result) to \(i)")
        done++
        if done == syncCount {
            print("TODO: uploading results")
            // TODO: this is where I upload the results to the DataServer
            
            // convert the data to JSON (there must be a better way)
            var forAllJson = [JSON]()
            for resultData in results {
                var dict = [String:JSON]()
                for (k, v) in resultData {
                    dict[k.stringName] = JSON(v)
                }
                forAllJson.append(JSON(dict))
            }
            let json: JSON = JSON(forAllJson)
            print("json: \(json)")
            
        }
    }
}