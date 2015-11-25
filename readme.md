# Experiments
* In general, it can be noted that experiments evaluating HTTP/2 either focus
  on performance for desktop browser experiences over WiFi (e.g. HSIS),
  simulate cellular environments (via NS3), or run 3G using a USB-3G-card in a
  laptop.
* This makes sense for having a more precisely controlled environment to
  evaluate whether HTTP/2 _should_ provide PLT improvements for cellular
  devices _in theory_.
* In this paper, we are interested in uncovering the performance differences
  that can be seen between the two major HTTP versions _in practice_.

## k-TCP
### Overview
* H2 makes a big point to use a _single_ (_persistent_) TCP connection [WHY?].
* This has been shown to be problematic over cellular connections [WHERE?].
* We shall vary the number of TCP connections
* We don't use anything over the raw TCP sockets

#### Server
* We used raw Oracle Java SE 8 to implement a k-threaded server.
* This server listens on k adjacent ports, and upon connection, sends a
  configured number of random bytes to the connected client.
* We configure port forwarding on the router to avoid NAT issues to enable our
  server to listen for requests from outside the local area network.

#### Client
* We implemented an iOS 9.0 application in Swift to run on an iPhone 6s
  cellular device.
* Our application opens _k_ simultaneous TCP connections to the Java server
  described above, and receives the configured number of bytes.
* The app records how long this all takes on a _per connection_ basis, and also
  from start-to-finish for all _k_ simultaneous connections.

### The Datas
* The client shall store the nano-time at which
    * the whole thing is initiated
    * and the number of nanoseconds between initiation and when each TCP
      connection
        * is _established_
        * data starts being received
        * data is done being received
* The exact format for the raw JSON data is in the `data_analysis` directory at
  the top of one of the python files

## H1 vs H2
### Overview
* Until recently, testing the performance impact of H2 has been largely
  speculative because there were very few existing reliable implementations of
  the protocol for both server side and for client side.
* This is starting to change, as evidenced here [link to implementations wiki].
* However, there is still not good performance data as it relates to _mobile
  phones_, which were indeed a major motivation for creating HTTP/2 in the
  first place.

#### Server
* We wanted to make sure the same framework would be used for both our H1 and
  H2 experimental trials.
* For this reason, the open-source Jetty framework (in Java) was most suitable.

#### Client
* Apple's iOS 9 contains a (private) implementation of HTTP/2 which is used
  automatically [via _ALPN_] when the server says it's
  available.
* I found [some code](github.com/FGoessler/iOS-HTTP2-Test) that allows one to
  selectively choose which H-vrsn to use based on whether you use
  `NSURLConnection` (no H2) or `NSURLSession` (H2 in > iOS 9)
* However that code is kind of overly-complicated, and I want to use
  `Alamofire` and `SwiftyJSON` instead.
* So I'm going to start a new project, and leave it up to the _server_ to
  decide which protocol I should use, based on the port that the request comes
  in on.
* So I need a wrapper method `instrumentedGET(urlAndPort)``

##### Try again
* The new plan is to use the following code
  ```swift
  @IBOutlet var myWebView: UIWebView!
  func displayURL() {
    // let myURL = NSURL(string: "https://localhost:8443/index.html")
    let myURL = NSURL(string: "http://www.wired.com")
    let myURLTask = NSURLSession.sharedSession().dataTaskWithURL(myURL!) {
      (data, response, error) in
      if error == nil {
        var htmlString = NSString(data: data, encoding: NSUTF8StringEncoding)
        self.myWebView.loadHTMLString(myHtmlString as! String, baseURL: nil)
      }
    }
  }
  ```
* __But what does it all even mean??__

###### [NSURLSession](https://developer.apple.com/library/ios/documentation/Foundation/Reference/NSURLSession_class/)

* Provides an API for downloading content
* Supports authentication and background downloads while app is suspended
* Supports `http` and `https` among others
* The place to start is apparently [here][url-loading]
* There is a lot there
* It seems like I need to implement `NSURLSessionDataDelegate` and plug into
  the `URLSession(_:dataTask:willCacheResponse:completionHandler:)` as well as
  the `URLSession(_:dataTask:didReceiveData:)`.
* Or _probably_, it should be `NSURLSessionDownloadDelegate`, for which I plug into `
  URLSession(_:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedTo
  Write:)` and `URLSession(_:downloadTask:didFinishDownloadingToURL:)`


[url-loading]: https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/URLLoadingSystem/URLLoadingSystem.html#//apple_ref/doc/uid/10000165i

##### Caching
* This is one of those things that could easily get pretty frustrating to deal
  with
* Check out what's going they're doing in the [relevant Alamofire unit
  tests][cachetests]

[cachetests]: https://github.com/Alamofire/Alamofire/blob/c634f6067f0b5a59992a10bbd848203aa1231ff6/Tests/CacheTests.swift

### The actual experimental condition
* We can't ask questions about server push, because according to the Tweeters,
  it is disabled in `NSURLSession` anyways.
    * This is a _real_ frickin bummer.
* In any case, we should keep in mind that the HSIS people found that the case
  in which H2 _worse than_ H1 was under conditions of __transmitting large
  objects over a high-loss connection__.
* So how about we have two `html` files, one has many _small_ resources, and
  one has many _large_ resources.
    * We expect that due to the multiplexability of H2, the small resources
      should perform better in that scenario.
    * As a way to try to replicate the effects seen in HSIS, we expect the
      large resources' condition to give the edge to H1.

## Data Collection
### DataServer
* `DataServer` is a little Sinatra HTTP (/1.1!) microservice
* It sits there, expecting data to come in as a UTF-8 JSON String through a
  server socket.
* It dumps incoming json strings into a file prefixed with the date and hour.

# Pseudocode

## Tcp Experiment

```swift
button.fire {
    bg.thread {
    for size in sizes {
        TcpBenchmarker(sema).go()
    }
    displayText("done")
}

TcpBenchmarker: ResultMgr
    let sema
    func go {
        for i in 1...numConcurrentConns {
            eventedConns[i].recordEventsOnPort(i)
        }
    }
    var results = Results[numConcurrentConns]
    var numFull = 0
    func addResult(notes, forIndex: i) {
        results[i] = notes
        if ++numFull == numConcurrentConns {
            upload(results)
            sema.up()
        }
    }
}

EventedConns: Benchmarker, StreamDelegate {
    func recordEventsOnPort(i) {
        note(Start)
        openConn(i)
    }
    Stream.handle {
        case Opened:
            note(Open)
        case Data:
            case FirstByte
                note(FirstByte)
            case LastByte:
                note(LastByte)
                resultMgr.addResult(notes, i)
    }
}
```

## HttpExperiment

```
button.fire {
    bg.thread {
        HttpBenchmarker.go()
    }
}

HttpBenchmarker {
    let sema
    func go() {
        for vrsn in [1, 2] {
            for rep in 1...numReps {
                EventedHttp(
                    httpVrsn,
                    index: i,
                    iphoneDisplay: screenRef,
                    resultMgr: self
                ).go()
            }
        }
    }
}

EventedHttp: Benchmarker, NSURLSessionDownloadDelegate {
    func collectResult(forIndex i: Int) {
        let session = NSURLSession(config: myConfig, delegate: self)
        session.resetThen {
            session.downloadTask(url).resume()
        }

    }
}
```
