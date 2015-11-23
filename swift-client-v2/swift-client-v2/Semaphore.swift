//
//  Semaphore.swift
//  swift-client-v2
//
//  Created by Ethan Petuchowski on 11/23/15.
//  Copyright © 2015 Ethanp. All rights reserved.
//

import Foundation

// https://gist.github.com/JadenGeller/c0a97893d4a35a960289
struct Semaphore {
    
    let semaphore: dispatch_semaphore_t
    
    init(value: Int = 0) {
        semaphore = dispatch_semaphore_create(value)
    }
    
    // Blocks the thread until the semaphore is free and returns true
    // or until the timeout passes and returns false
    func wait(nanosecondTimeout: Int64) -> Bool {
        return dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, nanosecondTimeout)) != 0
    }
    
    // Blocks the thread until the semaphore is free
    func wait() {
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
    }
    
    // Alerts the semaphore that it is no longer being held by the current thread
    // and returns a boolean indicating whether another thread was woken
    func signal() -> Bool {
        return dispatch_semaphore_signal(semaphore) != 0
    }
}