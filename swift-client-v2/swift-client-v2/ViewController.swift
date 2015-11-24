//
//  ViewController.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/3/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import Async

typealias Results = [Lifecycle: Int]
let BASE_PORT = 12345

class ViewController: UIViewController, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionDownloadDelegate {

    // MARK: Lifecycle
    // Do any additional setup after loading the view
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    // MARK: UI Elements
    @IBOutlet weak var simpleRequestButton: UIButton!
    @IBOutlet weak var timeTcpButton: UIButton!
    @IBOutlet weak var fiveTcpsButton: UIButton!
    @IBOutlet weak var fireRepeatedly: UIButton!
    @IBOutlet weak var fiveRepeatedly: UIButton!
    
    @IBOutlet weak var http1FlurryButton: UIButton!
    @IBOutlet weak var http2FlurryButton: UIButton!
    
    @IBOutlet weak var debugTextArea: UITextView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var webView: UIWebView!
    
    // MARK: Attributes
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        return dateFormatter
    }()
    
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
    
    var buttons : [UIButton?] {
        get {
            return [
                simpleRequestButton,
                timeTcpButton,
                fiveTcpsButton,
                fireRepeatedly,
                fiveRepeatedly
            ]
        }
    }

    var singleTcpBenchmarker: TcpBenchmarker?
    var fiveTcpBenchmarker: TcpBenchmarker?

    // MARK: Button Responses
    @IBAction func simpleRequestPressed(sender: UIButton) {
        sampleGET()
    }

    /** this just does ONE tcp connection */
    @IBAction func timeTcpPressed(sender: UIButton) {
        singleTcpBenchmarker = TcpBenchmarker(syncCount: 1, bytesToDwnld: 6)
        singleTcpBenchmarker!.collectAndUploadResults()
    }

    @IBAction func time5TcpsPressed(sender: UIButton) {
        fiveTcpBenchmarker = TcpBenchmarker(syncCount: 5, bytesToDwnld: 6)
        fiveTcpBenchmarker!.collectAndUploadResults()
    }

    @IBAction func fireRepeatedly(sender: UIButton)     { exploreTheSpace(1) }
    @IBAction func fiveConnRepeatedly(sender: UIButton) { exploreTheSpace(5) }

    func setButtonsEnabled(bool: Bool) {
        for b in buttons {
            b?.enabled = bool
        }
    }
    
    override func viewDidLayoutSubviews() {
        self.progressBar.setProgress(0.0, animated: false)
    }
    
    // just used in exploreTheSpace, maybe could be moved into that method
    var currentBenchmarker: TcpBenchmarker?
    
    func exploreTheSpace(count: Int) {
        let sema = Semaphore()
        
        // amount of data downloaded grows EXPONENTIALLY
        // from 1 Byte to 4 MB
        let FOUR_MEGS = 22
        
        Async.userInitiated {
            for i in 1...FOUR_MEGS {
                let size = (1 << i)
                let debugText = "downloading \(size) total bytes over \(count) conns"
                self.displayText(debugText)
                Async.main {
                    self.progressBar.setProgress((Float(i-1))/Float(FOUR_MEGS), animated: true)
                }
                self.currentBenchmarker = TcpBenchmarker(
                    syncCount: count,
                    bytesToDwnld: size,
                    sema: sema
                )
                self.currentBenchmarker!.collectAndUploadResults()
                
                // wait for results to be uploaded by the TcpBenchmarker
                sema.wait()
            }
            self.displayText("done uploading data")
            Async.main {
                self.progressBar.setProgress(1.0, animated: true)
            }
            Async.main(after: 1) {
                self.progressBar.setProgress(0.0, animated: false)
            }
        }
    }


    // MARK: Example Implementations
    func sampleGET() {
        Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
            .responseJSON { res in
                print(res.request)  // original URL request
                print(res.response) // URL response
                print(res.data)     // server data
                print(res.result)   // result of response serialization

                if let json = res.result.value {
                    print("JSON: \(json)")
                }
        }
    }

    func jsonDictExample() -> [String:AnyObject] {
        let d2 = ["asdf": 1234, "bsdf": 2345]
        let d1 = ["title": "TCP Vary", "start": dateString(), "cons": d2]
        return d1 as! [String : AnyObject]
    }

    func uploadData(data: [String:AnyObject]) {
        //        let parameters = [
        //            "foo": [1,2,3],
        //            "bar": [
        //                "baz": "qux"
        //            ]
        //        ]

        print("uploading")

        Alamofire.request(
            .POST,
            "http://localhost:4567/data",
            //            parameters: parameters,
            parameters: data,
            encoding: .JSON
            ).responseJSON { response in
                debugPrint(response)
        }
        // HTTP body: {"foo": [1, 2, 3], "bar": {"baz": "qux"}}
    }


    // MARK: Utilities
    func dateString() -> String {
        return self.dateFormatter.stringFromDate(NSDate())
    }
    
    func displayText(text: String) {
        print(text)
        Async.main {
            self.debugTextArea.text = text
        }
    }
    
    //////////////////////////////////////////////////
    // THIS IS WHERE THE HTTP EXPERIMENT CODE LIVES //
    //////////////////////////////////////////////////
    
    @IBAction func http1FlurryPressed(sender: UIButton) {
//        HttpBenchmarker(version: .ONE, trials: 2)
//            .collectAndUploadResults()
        displayURL()
    }
    
    let theHttpB = HttpBenchmarker(version: .TWO, trials: 2)
    
    func displayURL() {
        // let myURL = NSURL(string: "https://localhost:8443/index.html")
        let testURL = NSURL(string: "https://http2.akamai.com/")!
        displayText("retrieving \(testURL)")
        
        let ses = NSURLSession(
            configuration: sessionConfig,
            delegate: self,
            delegateQueue: NSOperationQueue.mainQueue()//nil // create a bg-thread for this task
        )
        let urlReq = NSURLRequest(URL: testURL)
        let dataTask = ses.downloadTaskWithRequest(urlReq)
        dataTask.resume()
//        ses.dataTaskWithURL(testURL) {
//            (data, response, error) in
//            if let err = error {
//                self.displayText("today, the music died: \(err)")
//                fatalError()
//            }
//            
//            self.displayText("rendering received data for \(testURL)")
//            let htmlString = NSString(data: data!, encoding: NSUTF8StringEncoding)
//            
//            // this (rendering html to webView) is async (need callback or something)
//            self.webView.loadHTMLString(htmlString as! String, baseURL: testURL)
//        }.resume()
    }
    
    @IBAction func http2FlurryPressed(sender: UIButton) {
        HttpBenchmarker(version: .TWO, trials: 2)
            .collectAndUploadResults()
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
        session:                            NSURLSession,
        downloadTask:                       NSURLSessionDownloadTask,
        didFinishDownloadingToURL location: NSURL)
    {
        print("didFinishDownloading was called")
        
        self.webView.loadData(
            NSData(contentsOfURL: location)!,
            MIMEType: "text/html",
            textEncodingName: "UTF-8",
            baseURL: location
        )
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
    
    func URLSession(
        session: NSURLSession,
        dataTask: NSURLSessionDataTask,
        didReceiveResponse response: NSURLResponse,
        completionHandler: (NSURLSessionResponseDisposition) -> Void)
    {
        print("didReceiveResponse was called")
    }
}

