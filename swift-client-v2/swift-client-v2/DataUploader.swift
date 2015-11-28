//
//  DataUploader.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/23/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation
import Alamofire

class DataUploader {
    static let DATASERVER_PORT = 4567 // default Sinatra port is 4567
    static func uploadResults(params: [String: AnyObject]) {
        let request = Alamofire.request(.POST,
//            "http://70.114.214.99:\(DATASERVER_PORT)/data",
            "http://209.6.146.184:\(DATASERVER_PORT)/data",
            parameters: params,
            encoding: .JSON
        )
        debugPrint(request)
    }
}