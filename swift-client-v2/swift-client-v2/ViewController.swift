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

class ViewController: UIViewController {

    // MARK: Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.progressBar.setProgress(0.0, animated: false)
    }

    // MARK: UI Elements
    @IBOutlet weak var fireRepeatedly: UIButton!
    @IBOutlet weak var fiveRepeatedly: UIButton!
    
    @IBOutlet weak var http1FlurryButton: UIButton!
    
    @IBOutlet weak var debugTextArea: UITextView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var webView: UIWebView!

    // MARK: Button Responses
    @IBAction func fireRepeatedly(sender: UIButton)     { exploreTheSpace(1) }
    @IBAction func fiveConnRepeatedly(sender: UIButton) { exploreTheSpace(5) }

    @IBAction func runHttpExperiment(sender: UIButton) {
        Async.userInitiated {
            HttpBenchmarker(vc: self, repsPerProtocol: 2).doIt()
        }
    }
    
    @IBAction func displayWebPage(sender: UIButton) {
        let h2Url = NSURL(string: "https://localhost:8443/index.html")!
        let h1Url = NSURL(string: "https://localhost:8444/index.html")!
        print("downloading \(h1Url)")
        secondTry(h1Url)
    }
    
    func secondTry(myUrl: NSURL) {
        let downloadDelegate = ArbitraryTruster(view: self)
        let ses = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate: downloadDelegate,
            delegateQueue: nil
        )
        ses.downloadTaskWithURL(myUrl).resume()
    }
    
    func completed(location: NSURL) {
        print("downloaded")
        var htmlString = "NON, MERCÍ"
        do {
            htmlString = try String.init(
                contentsOfURL: location,
                encoding: NSUTF8StringEncoding
            )
        } catch {
            print("ERRORED OUT")
            fatalError()
        }
        print("contents: \(htmlString)")
        self.webView.loadHTMLString(htmlString, baseURL: nil)
    }
    
    // could be inside func exploreTheSpace, but that would produce a compiler warning
    var currentBenchmarker: TcpBenchmarker?
    
    func exploreTheSpace(count: Int) {
        
        // amount of data downloaded grows EXPONENTIALLY
        // from 1 Byte to 4 MB
        let FOUR_MEGS = 22
        
        Async.userInitiated {
            for i in 1...FOUR_MEGS {
                let size = (1 << i)
                self.displayText("downloading \(size) total bytes over \(count) conns")
                Async.main {
                    self.progressBar.setProgress((Float(i-1))/Float(FOUR_MEGS), animated: true)
                }
                self.currentBenchmarker = TcpBenchmarker(
                    syncCount: count,
                    bytesToDwnld: size
                ).collectResults()
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
    
    // MARK: Utilities
    
    func displayText(text: AnyObject) {
        Async.main {
            print(text)
            self.debugTextArea.text = "\(text)"
        }
    }
    
    // developer.apple.com/library/ios/technotes/tn2232/_index.html
    class ArbitraryTruster : NSObject, NSURLSessionDelegate, NSURLSessionDownloadDelegate {
        var view: ViewController
        init(view: ViewController) {
            self.view = view
        }
        func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
            print("Invalidated: \(error)")
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
                    completionHandler(.UseCredential, theCredential)
                    return
                }
            }
            theSender.performDefaultHandlingForAuthenticationChallenge!(challenge)
            return
        }
        func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
            print("finished Background Session: \(session)")
        }
        func URLSession(
            session: NSURLSession,
            downloadTask: NSURLSessionDownloadTask,
            didFinishDownloadingToURL location: NSURL
        ) {
            self.view.completed(location)
        }
    }
}

