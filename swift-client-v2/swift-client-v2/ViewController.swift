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

class ViewController: UIViewController {

    // MARK: Lifecycle
    // Do any additional setup after loading the view
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: UI Elements
    @IBOutlet weak var simpleRequestButton: UIButton!
    @IBOutlet weak var timeTcpButton: UIButton!
    
    // MARK: Attributes
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        return dateFormatter
    }()

    let conn = EventedConn()
    
    // MARK: Button Responses
    @IBAction func simpleRequestPressed(sender: UIButton) {
        sampleGET()
    }

    /** this just does ONE tcp connection */
    @IBAction func timeTcpPressed(sender: UIButton) {
        /* TODO collect the following DATA
            1. Begin
            2. Connected
            3. First byte
            4. Last byte
            5. Closed
        
            Then send it to the dataserver.rb
        */
//        conn.connect("localhost", port:12345, size: 5)
//        let result = conn.close()
        
        // Start 10 threads as "interactive" QoS that each run the given block.
        // NB: Entire Apply.bg {} function is SYNCHRONOUS. Otw wrap with Async.
        Apply.userInteractive(10) { i in
            let c = EventedConn()
            c.connect("localhost", port: 12345+i, size: 12)
            print("hello from interactive \(i)")
        }
        
        // looks like this doesn't execute until all Apply'd blocks finish
        print("returning")
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

