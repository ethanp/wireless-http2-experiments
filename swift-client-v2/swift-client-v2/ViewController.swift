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

typealias Results = [TcpLifecycleEvent: NSTimeInterval]

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
    
    // MARK: Attributes
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        return dateFormatter
    }()
    
    let singleTcpBenchmarker = TcpBenchmarker(syncCount: 1)
    let fiveTcpBenchmarker = TcpBenchmarker(syncCount: 5)
    
    // MARK: Button Responses
    @IBAction func simpleRequestPressed(sender: UIButton) {
        sampleGET()
    }
    
    /** this just does ONE tcp connection */
    @IBAction func timeTcpPressed(sender: UIButton) {
        singleTcpBenchmarker.dododoYourThangHoney()
    }
    
    @IBAction func time5TcpsPressed(sender: UIButton) {
        fiveTcpBenchmarker.dododoYourThangHoney()
    }
    
    class TcpBenchmarker: ResultMgr {

        var conns = [EventedConn]()
        var results = [Results]()
        var syncCount: Int?
        var done = 0
        
        init(syncCount: Int) {
            self.syncCount = syncCount
            self.results = Array<Results>(count: syncCount, repeatedValue: [:])
            for _ in 1...syncCount {
                self.conns.append(EventedConn(resultMgr: self))
            }
        }
        
        func dododoYourThangHoney() {
            for i in 0...syncCount!-1 {
                print("getting index \(i)")
                self.conns[i].connect("localhost", port:12345+i, size: 5)
            }
        }
        
        // TODO if the server has too much data, this doesn't happen at the right time
        // I should just make it read until it can't read no more
        func addResult(result: Results, forIndex i: Int) {
            results[i] = result
            print("added result \(result) to \(i)")
            done++
            if done == syncCount {
                print("got a bunch of results for ya, see: \(results)")
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

