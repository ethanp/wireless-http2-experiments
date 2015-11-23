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

class EventedConn: Benchmarker, NSStreamDelegate {

    var host:String?
    var port:Int?
    var bytesToDwnld:Int?
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    
    var bytesRcvd = 0
    

    /** This function opens TCP streams to the given address and returns.
        Asynchronously, this object receives bytes over those streams.
        Eventually it downloads `bytesToDwnld` bytes, and finishes adding
        entries into `collectedData: Results`.
     
        What it SHOULD be like is that `record(callback)` function that
        the other guy wrote.
    */
    func recordDataFor(host: String, onPort port: Int, bytesToDwnld: Int) {

        self.host = host
        self.port = port
        self.bytesToDwnld = bytesToDwnld

        print("connecting i = \(port)")
        // Note: typealias NSTimeInterval = Double
        timestampEvent(.START)
        
        // TODO: I'm having trouble figuring out what EXACTLY this does
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
    
    /** This `EventedConn` is meant to connect to the "j^th" TCP server */
    func j() -> Int { return port!-BASE_PORT }

    /** Reads incoming data off the inStream.
     
        Calls `resultMgr!.addResult(collectedData, forIndex: j())` once
        bytesToDwnld bytes have been downloaded.
    */
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {

        // triple-equals means *reference*-equality
        if aStream === inputStream {
            switch eventCode {

            case NSStreamEvent.ErrorOccurred:
                print("input j = \(j()): ErrorOccurred: \(aStream.streamError?.description)")

            case NSStreamEvent.OpenCompleted:
                print("input j = \(j()): OpenCompleted")

                // note stream is open
                timestampEvent(.OPEN)

            // TODO: this is buggy. 
            // If there are > 8 bytes available,
            // I don't read them!
            case NSStreamEvent.HasBytesAvailable:
                print("input: HasBytesAvailable")
                
                // forget about reading more bytes than we need
                if bytesRcvd < bytesToDwnld, let iss = inputStream {

                    // note first byte
                    if bytesRcvd == 0 {
                        timestampEvent(.FIRST_BYTE)
                    }

                    // read bytes available
                    // this len is used in the apple docs on "Reading from Input Streams"
                    let BUFF_LEN = 1024
                    var inbuf = [UInt8](count: BUFF_LEN, repeatedValue: 0)
                    while iss.hasBytesAvailable && bytesRcvd < bytesToDwnld {
                        
                        let bytesRemaining = bytesToDwnld! - bytesRcvd
                        let bytesToRead = min(BUFF_LEN, bytesRemaining)
                        /*
                            * ret > 0: the number of bytes read;
                            * ret = 0: the end of the buffer was reached;
                            * ret < 0: the operation failed.
                        */
                        let numBytesRcvd: Int = iss.read(&inbuf, maxLength: bytesToRead)
                        if numBytesRcvd == -1 {
                            fatalError("input stream was closed prematurely (presumably by the server)")
                        }
//                        print("rcvd \(numBytesRcvd) bytes, viz: \(inbuf.prefix(numBytesRcvd))")
                        print("rcvd \(numBytesRcvd) bytes")
                        bytesRcvd += numBytesRcvd
                    }

                    // note last byte
                    if bytesRcvd >= bytesToDwnld {
                        timestampEvent(.LAST_BYTE)

                        // This doesn't seem to actually 
                        // close the TCP connection
                        closeStreams()
                        timestampEvent(.CLOSED)
                        
                        resultMgr!.addResult(collectedData, forIndex: j())
                    }
                } else {
                    print("j=\(j()) ignoring bc \(bytesRcvd) ≥ \(bytesToDwnld!)")
                }

            default:
                break
            }
        }
    }
    
    func closeStreams() {
        inputStream?.close()
        outputStream?.close()
        inputStream?.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        // https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Streams/Articles/ReadingInputStreams.html
        outputStream?.removeFromRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
}
