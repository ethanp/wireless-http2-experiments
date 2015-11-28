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
            HttpBenchmarker(vc: self, repsPerProtocol: 20).doIt()
        }
    }

    // this could be inside func exploreTheSpace, but that
    // would produce a compiler warning
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
}
