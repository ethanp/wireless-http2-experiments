//
//  EventedConn.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/3/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//
//  mainly from
//  http://stackoverflow.com/questions/28655425

import Foundation

enum TcpLifecycleEvent {
    case START
    case OPEN
    case FIRST_BYTE
    case LAST_BYTE
    case CLOSED
}

protocol ResultMgr {
    func addResult(result: Results)
}
class EventedConn: NSObject, NSStreamDelegate {

    var host:String?
    var port:Int?
    var bytesToDwnld:Int?
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    var collectedData = [TcpLifecycleEvent: NSTimeInterval]()
    var resultMgr: ResultMgr?
    
    var bytesRcvd = 0
    
    init(resultMgr: ResultMgr) {
        self.resultMgr = resultMgr
    }

    func connect(host: String, port: Int, size bytesToDwnld: Int) {

        self.host = host
        self.port = port
        self.bytesToDwnld = bytesToDwnld

        // Note: typealias NSTimeInterval = Double
        collectedData[TcpLifecycleEvent.START] = timeAsInterval()
        NSStream.getStreamsToHostWithName(
            host,
            port: port,
            inputStream: &inputStream,
            outputStream: &outputStream
        )

        if let iss = inputStream, oss = outputStream {
            iss.delegate = self
            oss.delegate = self
            iss.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            oss.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            iss.open() // ASYNC: events come on the delegate
            oss.open()
        }
        else {
            print("ERROR: couldn't acquire stream!")
        }
    }

    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        if aStream === inputStream {
            switch eventCode {

            case NSStreamEvent.ErrorOccurred:
                print("input: ErrorOccurred: \(aStream.streamError?.description)")

            case NSStreamEvent.OpenCompleted:
                print("input: OpenCompleted")

                // note stream is open
                collectedData[TcpLifecycleEvent.OPEN] = timeAsInterval()

            case NSStreamEvent.HasBytesAvailable:
                print("input: HasBytesAvailable")

                // note first byte
                if bytesRcvd == 0 {
                    collectedData[TcpLifecycleEvent.FIRST_BYTE] = timeAsInterval()
                }

                // read bytes available
                var inbuf = [UInt8](count: 8, repeatedValue: 0)
                let numBytesRcvd: Int = inputStream!.read(&inbuf, maxLength: 8)
                if (numBytesRcvd == -1) {
                    fatalError("input stream was closed prematurely (presumably by the server)")
                }
                print("\(numBytesRcvd), \(inbuf.prefix(numBytesRcvd))")
                bytesRcvd += numBytesRcvd

                // note last byte
                if bytesRcvd >= bytesToDwnld {
                    collectedData[TcpLifecycleEvent.LAST_BYTE] = timeAsInterval()
                    resultMgr?.addResult(collectedData)
                }

            default:
                break
            }
        }
        else if aStream === outputStream {
            switch eventCode {

            case NSStreamEvent.ErrorOccurred:
                print("output: ErrorOccurred: \(aStream.streamError?.description)")

            case NSStreamEvent.OpenCompleted:
                print("output: OpenCompleted")

            case NSStreamEvent.HasSpaceAvailable:
                print("output: HasSpaceAvailable")

                // Here you can write() to `outputStream`

            default:
                break
            }
        }
    }

    func timeAsInterval() -> NSTimeInterval {
        return NSDate().timeIntervalSince1970
    }

func close() -> [TcpLifecycleEvent: NSTimeInterval] {
        inputStream?.close()
        outputStream?.close()
        return collectedData
    }
}
