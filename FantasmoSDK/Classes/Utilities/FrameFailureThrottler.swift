//
//  FrameValidationThrotler.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 15.04.2021.
//

import Foundation

/// Throttler for frame validation failure events each of which occurs when a frame turns out to be not acceptable for determining location.
/// Throttling technique corresponds to classic throttling on "leading" edge but very first triggering is omitted and triggering does not happen until
/// certain number of events have occurred since previous triggering event.
/// Example of throttling on "leading" edge can be found at https://bit.ly/3dl2RAz
class FrameFailureThrottler {
    
    /// Interval between two
    /// Minimum number of seconds that must elapse between trigering.
    private let throttleThreshold = 2.0
    
    /// The number of times a validation error of certain kind occurs before triggering.
    private let incidenceThreshold = 30
    
    /// The last time of triggering.
    private var lastErrorTime = clock()
    
    private var handler: ((FMFrameFilterFailure) -> Void)
    private var validationErrorToCountDict = [FMFrameFilterFailure: Int]()
    
    /// - Parameter handler: closure that is invoked in accordance with logic of throttling.
    init(handler: @escaping (FMFrameFilterFailure) -> Void) {
        self.handler = handler
    }
    
    /// Throttling technique corresponds to classic throttling on "leading" edge but very first triggering is omitted and triggering does not happen until
    /// certain number of events have occurred since previous triggering event.
    func onNext(failure: FMFrameFilterFailure) {
        let count = (validationErrorToCountDict[failure] ?? 0) &+ 1
        let elapsed = Double(clock() - lastErrorTime) / Double(CLOCKS_PER_SEC)
        
        if elapsed > throttleThreshold, count >= incidenceThreshold {
            handler(failure)
            startNewCycle()
        } else {
            validationErrorToCountDict[failure] = count
        }
    }
    
    func restart() {
        startNewCycle()
    }
    
    private func startNewCycle() {
        lastErrorTime = clock()
        validationErrorToCountDict.removeAll(keepingCapacity: true)
    }
    
}
