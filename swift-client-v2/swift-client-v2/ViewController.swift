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

typealias Results = [TcpLifecycleEvent: Int]
let BASE_PORT = 12345

class ViewController: UIViewController {

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
    
    // MARK: Attributes
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        return dateFormatter
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
                debugPrint(debugText)
                Async.main {
                    self.debugTextArea.text = debugText
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
            Async.main {
                self.debugTextArea.text = "done uploading data"
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

    // TODO
    func instrumentedGET(url: String, port: Int) {

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
    
    //////////////////////////////////////////////////
    // THIS IS WHERE THE HTTP EXPERIMENT CODE LIVES //
    //////////////////////////////////////////////////
    
    @IBAction func http1FlurryPressed(sender: UIButton) {
        let httpBenchmarker = HttpBenchmarker(version: 2, trials: 2)
        httpBenchmarker.collectAndUploadResults()
    }
    
    @IBAction func http2FlurryPressed(sender: UIButton) {
        
    }
    
}

