//
//  TCPBenchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/4/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
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
    func collectResults() -> TcpBenchmarker {
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
        DataUploader.uploadResults([
            "conns":   syncCount!,
            "exper":   "TCP",
            "results": resultsConv(),
            "onWifi":  getOnWifi(),
            "bytes":   bytesToDwnld!
        ])
    }
}

