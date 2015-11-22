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

/**
What this does is: TODO
*/
class HttpBenchmarker {
    var httpVersion: Int?
    var numTrials: Int?
    
    init(version: Int, trials: Int) {
        self.httpVersion = version
        self.numTrials = trials
    }
}