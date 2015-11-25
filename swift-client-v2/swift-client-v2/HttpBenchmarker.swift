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
import Async

enum HttpVersion: Int {
    case ONE = 1
    case TWO = 2
    static let allValues = [ONE, TWO]
}

class HttpBenchmarker: ResultMgr {
    let vc: ViewController!
    let repsPerProtocol: Int!
    init(vc: ViewController, repsPerProtocol: Int) {
        self.vc = vc
        self.repsPerProtocol = repsPerProtocol
        super.init(numResults: repsPerProtocol * HttpVersion.allValues.count)
    }
    
    /** this _blocks_ and therefore MUST NOT be executed on the `Main` thread */
    // TODO This doesn't actually work as intended.
    //      It doesn't seem to ever actually download the data.
    func doIt() {
        let sema = Semaphore(value: 1)
        for vrsn in HttpVersion.allValues {
            print("collecting data for http \(vrsn.rawValue)")
            for i in 1...repsPerProtocol {
                sema.wait()
                collectResult(vrsn, forIndex: i+vrsn.rawValue*i)
                sema.signal()
            }
        }
        uploadResults(results)
    }
    
    func collectResult(vrsn: HttpVersion, forIndex i: Int)  {
        EventedHttp(version: vrsn, vc: vc, resultMgr: self).collectResult(forIndex: i)
    }
    
    func uploadResults(results: [Results?]) {
        DataUploader.uploadResults([
            "results": resultsConv(),
            "test": "http"
        ])
    }
}

class EventedHttp: Benchmarker, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {
    
    var httpVersion: HttpVersion
    var vc: ViewController
    
    let ipAddr = "localhost"
    let page = "index.html"
    
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
    
    init(version: HttpVersion, vc: ViewController, resultMgr: ResultMgr) {
        self.httpVersion = version
        self.vc = vc
        super.init(resultMgr: resultMgr)
    }
    
    func port() -> Int {
        return httpVersion == .ONE ? 8444 : 8443
    }
    
    let sema = Semaphore()
    func collectResult(forIndex i: Int) {
        let ses = NSURLSession(
            configuration: sessionConfig,
            delegate: self,
            delegateQueue: nil // create a bg-thread for this task
//            delegateQueue: NSOperationQueue.mainQueue() // maybe better? dunno
        )
        
        // To make absolutely sure there is NO CACHING going on,
        // we configure the session to not *do* caching, then we
        // clear any caches before initiating the download task.
        ses.resetWithCompletionHandler {
            self.timestampEvent(.START)

            //        https://localhost:\(port())/index.html
            //        https://localhost:8444/index.html
            //        https://http2.akamai.com/
            //        http://www.wired.com
            
            let testURL = NSURL(string: "http://www.wired.com")!
            self.vc.displayText("retrieving \(testURL)")
            ses.downloadTaskWithRequest(NSURLRequest(URL: testURL)).resume()
            self.sema.wait()
        }
        resultMgr!.addResult(collectedData, forIndex: i)
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
        self.timestampEvent(.CLOSED)
        self.sema.signal()
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
