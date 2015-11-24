//
//  HttpBenchmarker.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/22/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
import Alamofire
import ReachabilitySwift

enum HttpVersion {
    case ONE
    case TWO
}

/**
What this does is: TODO
*/
class HttpBenchmarker: Benchmarker, ResultMgr {
    
    var httpVersion: HttpVersion
    var numTrials: Int
    
    let ipAddr = "localhost"
    let page = "index.html"
    
    var result = [String:AnyObject]()
    
    init(version: HttpVersion, trials: Int) {
        self.httpVersion = version
        self.numTrials = trials
        super.init(resultMgr: nil /* TODO!!! */)
    }
    
    func collectAndUploadResults() {
        print("collecting data for http \(httpVersion)")
        for _ in 1..<2 {
            collectResult()
            uploadResult()
        }
    }
    
    func collectResult() {
        timestampEvent(.START)
        Alamofire.request(.GET, "https://\(ipAddr):\(port())/\(page)")
            .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in
                if totalBytesRead == 0 {
                    self.timestampEvent(.FIRST_BYTE)
                }
            }
            .responseData { response -> Void in
                self.timestampEvent(.CLOSED)
        }
    }
    
    func uploadResult() {
        DataUploader.uploadResults([
            "oo bee doo bee": "hey hey hey"
        ])
    }
    
    func addResult(result: Results, forIndex i: Int) { /* TODO */ }
    
    func port() -> Int? {
        return httpVersion == .ONE ? 8444 : 8443
    }
}
