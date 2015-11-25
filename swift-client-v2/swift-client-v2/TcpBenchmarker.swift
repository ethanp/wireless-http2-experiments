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
    
    /** how many TCP servers to connect and download concurrently from */
    var syncCount: Int?
    
    var bytesToDwnld: Int?
    
    init(syncCount: Int, bytesToDwnld: Int) {
        super.init(numResults: syncCount)
        self.syncCount = syncCount
        self.bytesToDwnld = bytesToDwnld // TOTAL bytes over ALL conns
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
    func collectAndUploadResults() -> TcpBenchmarker {
        print("collecting results")
        for i in 0..<syncCount! {
            self.conns[i].recordDataFor(
                "70.114.214.99",
                onPort:BASE_PORT+i,
                bytesToDwnld: max(bytesToDwnld! / syncCount!, 1)
            )
        }
        sema.wait()
        return self
    }
    
    override func uploadResults() {
        print("uploading results: \(resultsAsJson())")
        DataUploader.uploadResults([
            "conns":   syncCount!,
            "exper":   "TCP",
            "results": resultsConv(),
            "onWifi":  getOnWifi(),
            "bytes":   bytesToDwnld!
        ])
    }

    
    private func resultsAsJson() -> JSON {
        // there must be a better way...needs combinators
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
    
    /** called by the EventedConn as part of implementing the `
        ResultMgr` protocol.
    */
    override func addResult(result: Results, forIndex i: Int) {
        results[i] = result
        print("added result \(result) to \(i)")
        if ++done == syncCount {
            uploadResults()
        }
    }
}

