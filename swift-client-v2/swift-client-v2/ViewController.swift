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

class ViewController: UIViewController {

    // Do any additional setup after loading the view
    override func viewDidLoad() {
        super.viewDidLoad()
        let d2 = ["asdf": 1234, "bsdf": 2345]
        let d1 = ["title": "TCP Vary", "start": dateString(), "cons": d2]
        let json = JSON(d1)
        print(json)
    }
    
    @IBOutlet weak var simpleRequestButton: UIButton!
    
    @IBAction func simpleRequestPressed(sender: UIButton) {
        Alamofire.request(.GET, "http://httpbin.org/get", parameters: ["foo": "bar"])
            .responseJSON { response in
                print(response.request)  // original URL request
                print(response.response) // URL response
                print(response.data)     // server data
                print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                }
        }
    }
    
    // `lazy var` so that we can configure it on initialization ?
    lazy var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss:SSS"
        return dateFormatter
    }(/*Swift syntax!*/)
    
    func dateString() -> String {
        return self.dateFormatter.stringFromDate(NSDate())
    }

    func instrumentedGET(url: String, port: Int) {
        
    }
    
    func uploadData(data: JSON) {
        
    }
}

