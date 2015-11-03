//
//  ViewController.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/3/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController {

    // Do any additional setup after loading the view
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    @IBOutlet weak var simpleRequestButton: UIButton!
    
    @IBAction func simpleRequestPressed(sender: UIButton) {
    }

    func instrumentedGET(url: String, port: Int) {
        
    }
}

