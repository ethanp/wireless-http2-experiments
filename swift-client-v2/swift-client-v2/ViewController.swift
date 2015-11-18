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

    // MARK: Attributes
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        return dateFormatter
    }()

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

    func exploreTheSpace(count: Int) {
        let sema = Semaphore()

        // I want the amount of data downloaded to grow EXPONENTIALLY
        // from 1 Byte to 250 MBytes
//        let THIRTY_TWO_BYTES = 5
        let FOUR_MEGS = 22
//        let TWO_FIFTY_MEGS = 28
        Async.userInitiated {
            for i in 1...FOUR_MEGS {
                let size = (1 << i)
                let per = max(size / count, 1)
                debugPrint("downloading \(size) total bytes over \(count) conns")
                // TODO we need to wait until the results are actually uploaded
                self.currentBenchmarker = TcpBenchmarker(
                    syncCount: count,
                    bytesToDwnld: per,
                    sema: sema
                )
                self.currentBenchmarker!.collectAndUploadResults()
                sema.wait()
            }
        }
    }

    var currentBenchmarker: TcpBenchmarker?

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

    // TODO as it is this thing takes a dict and converts it to json under the
    // hood there may be something else I need to do if I want to pass a JSON
    // obj directly to this method
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
}

