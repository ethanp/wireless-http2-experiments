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
    case ONE, TWO
    static let allValues = [ONE, TWO]
}

/**
What this does is: TODO
*/

class HttpBenchmarker: ResultMgr {
    let vc: ViewController!
    
    let NUM_REPS_PER_PROTOCOL = 2
    init(vc: ViewController) {
        self.vc = vc
    }
    func collectAndUploadResults() {
        var results = [[String: AnyObject]]()
        for vrsn in HttpVersion.allValues {
            print("collecting data for http 1")
            for _ in 1...NUM_REPS_PER_PROTOCOL {
                results.append(collectResult(vrsn))
            }
        }
        uploadResults(results)
    }
    
    func collectResult(vrsn: HttpVersion) -> [String: AnyObject] {
        let ev = EventedHttp(version: vrsn, resultMgr: self, vc: vc)
        return ev.collectResult()
    }
    
    func uploadResults(results: [[String: AnyObject]]) {
        DataUploader.uploadResults([
            "results": results,
            "test": "http"
        ])
    }
    
    func addResult(result: Results, forIndex i: Int) {
        /* TODO */
    }
    

}
class EventedHttp: Benchmarker, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    var httpVersion: HttpVersion
    var vc: ViewController
    
    let ipAddr = "localhost"
    let page = "index.html"
    
    var result = [String:AnyObject]()
    
    lazy var sessionConfig: NSURLSessionConfiguration = {
        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
        conf.HTTPMaximumConnectionsPerHost = 5
        conf.HTTPShouldUsePipelining = false
        conf.URLCache = nil             // no caching is to be performed
        conf.URLCredentialStorage = nil // no credential storage is to be used
        conf.HTTPCookieStorage = nil    // no cookies should be handled
        conf.allowsCellularAccess = true
        conf.requestCachePolicy = .ReloadIgnoringLocalCacheData
        conf.HTTPShouldSetCookies = false
        return conf
    }()
    
    init(version: HttpVersion, resultMgr: ResultMgr, vc: ViewController) {
        self.httpVersion = version
        self.vc = vc
        super.init(resultMgr: resultMgr)
    }
    
    func port() -> Int {
        return httpVersion == .ONE ? 8444 : 8443
    }
    
    func collectResult() -> [String: AnyObject] {
        let ses = NSURLSession(
            configuration: sessionConfig,
            delegate: self,
            delegateQueue: NSOperationQueue.mainQueue()//nil // create a bg-thread for this task
        )
        ses.resetWithCompletionHandler {
            //        https://localhost:\(port())/index.html
            //        https://localhost:8444/index.html
            //        https://http2.akamai.com/
            //        http://www.wired.com
            
            let testURL = NSURL(string: "http://www.wired.com")!
            self.vc.displayText("retrieving \(testURL)")
            ses.downloadTaskWithRequest(NSURLRequest(URL: testURL)).resume()
        }
        return [:]
    }
    /* Sent when a download task that has completed a download.  The delegate should
     * copy or move the file at the given location to a new location as it will be
     * removed when the delegate message returns. URLSession:task:didCompleteWithError:
     * will still be called.
     */
    func URLSession(
        session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL)
    {
        vc.displayText("finished downloading at \(now() % 10000000)")
    }
    
    /* Sent periodically to notify the delegate of download progress. */
    func URLSession(
        session:                    NSURLSession,
        downloadTask:               NSURLSessionDownloadTask,
        didWriteData bytesWritten:  Int64,
        totalBytesWritten:          Int64,
        totalBytesExpectedToWrite:  Int64)
    {
        print("didWriteData was called at \(now())")
    }
}
