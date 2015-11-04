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

class EventedConn: NSObject, NSStreamDelegate {
    
    var host:String?
    var port:Int?
    var bytesToDwnld:Int?
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    var collectedData = [TcpLifecycleEvent: NSTimeInterval]()
    
    enum TcpLifecycleEvent {
        case START
        case OPEN
        case FIRST_BYTE
        case LAST_BYTE
        case CLOSED
    }
    
    var bytesRcvd = 0

    func connect(host: String, port: Int, bytesToDwnld: Int) {
        
        self.host = host
        self.port = port
        self.bytesToDwnld = bytesToDwnld
        
        // Note: typealias NSTimeInterval = Double
        collectedData[TcpLifecycleEvent.START] = NSDate().timeIntervalSince1970
        NSStream.getStreamsToHostWithName(
            host,
            port: port,
            inputStream: &inputStream,
            outputStream: &outputStream
        )
        
        if inputStream != nil && outputStream != nil {
            
            // Set delegate
            inputStream!.delegate = self
            outputStream!.delegate = self
            
            
            // Schedule
            inputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            outputStream!.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
            
            print("Start open()")
            
            // Open! This is ASYNC, you have to wait for callbacks
            //       on the delegate.
            inputStream!.open()
            outputStream!.open()
            print("now this is what I'm talking about \(collectedData[TcpLifecycleEvent.START])")
        }
        else {
            print("ERROR: couldn't acquire a stream!")
        }
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        if aStream === inputStream {
            switch eventCode {
            case NSStreamEvent.ErrorOccurred:
                print("input: ErrorOccurred: \(aStream.streamError?.description)")
            case NSStreamEvent.OpenCompleted:
                print("input: OpenCompleted")
                collectedData[TcpLifecycleEvent.OPEN] = NSDate().timeIntervalSince1970
            case NSStreamEvent.HasBytesAvailable:
                print("input: HasBytesAvailable")
                if bytesRcvd == 0 {
                    collectedData[TcpLifecycleEvent.FIRST_BYTE] = NSDate().timeIntervalSince1970
                }
                var inbuf = [UInt8](count: 8, repeatedValue: 0)
                let numBytesRcvd: Int = inputStream!.read(&inbuf, maxLength: 8)
                print("\(numBytesRcvd), \(inbuf.prefix(numBytesRcvd))")
                bytesRcvd += numBytesRcvd
                if bytesRcvd >= bytesToDwnld {
                    collectedData[TcpLifecycleEvent.LAST_BYTE] = NSDate().timeIntervalSince1970
                    print(collectedData)
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
    
    func close() {
        inputStream?.close()
        outputStream?.close()
    }
}