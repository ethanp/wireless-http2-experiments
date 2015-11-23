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
import ReachabilitySwift

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
        self.bytesToDwnld = bytesToDwnld // TOTAL bytes over ALL conns
        
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
                "70.114.214.99",
                onPort:BASE_PORT+i,
                bytesToDwnld: max(bytesToDwnld! / syncCount!, 1)
            )
        }
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
    
    func uploadResults() {
        print("uploading results: \(resultsAsJson())")
        DataUploader.uploadResults([
            "conns":   syncCount!,
            "exper":   "TCP",
            "results": resultsConv(),
            "onWifi":  getOnWifi(),
            "bytes":   bytesToDwnld!
        ])
        sema?.signal()
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

