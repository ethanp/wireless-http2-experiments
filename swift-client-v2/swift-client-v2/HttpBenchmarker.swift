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
class HttpBenchmarker: Benchmarker, ResultMgr, NSURLSessionDataDelegate {
    
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
    
    // I don't think I'll be using this
    // I'm going to use the raw NSURLSession stuff instead
    func alamoVersion() {
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

    /* Sent periodically to notify the delegate of download progress. */
    func URLSession(
        session:                    NSURLSession,
        downloadTask:               NSURLSessionDownloadTask,
        didWriteData bytesWritten:  Int64,
        totalBytesWritten:          Int64,
        totalBytesExpectedToWrite:  Int64)
    {
        print("didWriteData was called")
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
        print("didFinishDownloading was called")
    }
    
    /* Sent when data is available for the delegate to consume.  It is
    * assumed that the delegate will retain and not copy the data.  As
    * the data may be discontiguous, you should use
    * [NSData enumerateByteRangesUsingBlock:] to access it.
    */
    func URLSession(
        session: NSURLSession,
        dataTask: NSURLSessionDataTask,
        didReceiveData data: NSData)
    {
        print("didReceiveData was called")
    }

}
