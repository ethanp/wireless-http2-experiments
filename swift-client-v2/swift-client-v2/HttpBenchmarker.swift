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
class HttpBenchmarker {
    var httpVersion: HttpVersion
    var numTrials: Int
    let ipAddr = "localhost"
    
    var result = ["asdf":34534]
    
    init(version: HttpVersion, trials: Int) {
        self.httpVersion = version
        self.numTrials = trials
    }
    
    func collectAndUploadResults() {
        print("collecting data for http \(httpVersion)")
        for _ in 1..<2 {
            collectResult()
            uploadResult()
        }
    }
    
    func collectResult() {
        
    }
    
    func uploadResult() {
        DataUploader.uploadResults([
            "oo bee doo bee": "hey hey hey"
        ])
    }
    
    func port() -> Int? {
        return httpVersion == .ONE ? 8444 : 8443
    }
}
