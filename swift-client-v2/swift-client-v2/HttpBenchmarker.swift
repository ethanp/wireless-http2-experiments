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
        super.init(numResults:
            repsPerProtocol * HttpVersion.allValues.count)
    }
    
    /** this _blocks_ and therefore MUST NOT be executed on the `Main` thread */
    // TODO This doesn't actually work as intended.
    //      It doesn't seem to ever actually download the data.
    func doIt() {
        for vrsn in HttpVersion.allValues {
            print("collecting data for http \(vrsn.rawValue)")
            for i in 0..<repsPerProtocol {
                EventedHttp(
                    version: vrsn,
                    resultIndex:
                        i+(vrsn.rawValue-1)*repsPerProtocol,
                    vc: vc,
                    resultMgr: self
                ).go()
                sema.wait()
            }
        }
    }
    
    /** Don't call this. It is called by ResultMgr.addResult */
    override func uploadResults() {
        DataUploader.uploadResults([
            "exper": "http",
            "results": resultsConv(),
            "onWifi": getOnWifi()
        ])
    }
}

class EventedHttp: Benchmarker, NSURLSessionDownloadDelegate {
    
    var httpVersion: HttpVersion
    var vc: ViewController
    var index: Int
    
    let ipAddr = "localhost"
    let page = "index.html"
    
    lazy var sessionConfig: NSURLSessionConfiguration = {
        let conf = NSURLSessionConfiguration
            .defaultSessionConfiguration()
        
        // TODO this could be nice to fiddle with...
        //  though I guess it depends how Jetty deals with that
        //  wait, which ports DO sites connect to when they
        //  open parallel connections?
        conf.HTTPMaximumConnectionsPerHost = 5
        
        // my server's not gonna support pipelining anyway
        conf.HTTPShouldUsePipelining = false
        // no caching is to be performed
        conf.URLCache = nil
        // no credential storage is to be used
        conf.URLCredentialStorage = nil
        // no cookies should be handled
        conf.HTTPCookieStorage = nil
        conf.allowsCellularAccess = true
        conf.requestCachePolicy = .ReloadIgnoringLocalCacheData
        conf.HTTPShouldSetCookies = false
        return conf
    }()
    
    init(
        version: HttpVersion,
        resultIndex: Int,
        vc: ViewController,
        resultMgr: ResultMgr
    ) {
        self.httpVersion = version
        self.vc = vc
        self.index = resultIndex
        super.init(resultMgr: resultMgr)
    }
    
    func port() -> Int {
        return httpVersion == .ONE ? 8444 : 8443
    }
    
    func go() {
        let ses = NSURLSession(
            configuration: sessionConfig,
            delegate: self,
            // create a bg-thread for this task
            delegateQueue: nil
            // maybe better? dunno
//            delegateQueue: NSOperationQueue.mainQueue()
        )
        // To make absolutely sure there is NO CACHING going on,
        // we configure the session to not *do* caching, then we
        // clear any caches before initiating the download task.
        ses.resetWithCompletionHandler {
            self.timestampEvent(.START)

            // https://localhost:\(port())/index.html
            // https://localhost:8444/index.html
            // https://http2.akamai.com/
            // http://www.wired.com
            let testURL = NSURL(string: "https://localhost:8443/index.html")!
//            let testURL = NSURL(string: "http://www.wired.com")!
            self.vc.displayText("retrieving \(testURL)")
            ses.downloadTaskWithRequest(
                NSURLRequest(URL: testURL)
            ).resume()
        }
    }
    
    /* Sent when a download task that has completed a download. */
    func URLSession(
        session: NSURLSession,
        downloadTask: NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL)
    {
        vc.displayText(
            "finished downloading at \(now() % 10_000_000)")
        timestampEvent(.CLOSED)
        resultMgr!.addResult(
            collectedData,
            forIndex: index,
            semaUp: true
        )
    }
    
    /* Sent periodically to notify the delegate of download progress. */
    func URLSession(
        session:                    NSURLSession,
        downloadTask:               NSURLSessionDownloadTask,
        didWriteData bytesWritten:  Int64,
        totalBytesWritten:          Int64,
        totalBytesExpectedToWrite:  Int64)
    {
        print("didWrite \(bytesWritten) bytes at: \(now())")
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        print("did Become Invalid With Error: \(error)")
    }
    func URLSession(
        session: NSURLSession,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?)
        -> Void) {
            print("received challenge")
            let protectionSpace = challenge.protectionSpace
            let theSender = challenge.sender!
            if protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
                if let theTrust = protectionSpace.serverTrust{
                    let theCredential = NSURLCredential(trust: theTrust)
                    theSender.useCredential(theCredential, forAuthenticationChallenge: challenge)
                    return
                }
            }
            theSender.performDefaultHandlingForAuthenticationChallenge!(challenge)
            return
    }
    func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        print("finished Background Session: \(session)")
    }

}
