//
//  FrameValidationThrotler.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 15.04.2021.
//

import Foundation

/// Kind of throttler for frame validation failure events each of which occurs when a frame turns out to be not acceptable for determining location.
/// - Note: strictly speaking this class is not throttler because it doesn't guarantee that events  are reported at a regular time interval.
class FrameFailureThrottler {
    
    /// Minimum number of seconds that must elapse between invoking `handler`.
    private let throttleThreshold = 2.0
    
    /// The number of times a validation error of certain kind occurs before invoking `handler`.
    private let incidenceThreshold = 30
    
    /// The last time we invoked `handler`.
    private var lastErrorTime = clock()
    
    private var handler: ((FMFrameValidationError) -> Void)
    private var validationErrorToCountDict = [FMFrameValidationError: Int]()
    
    /// - Parameter handler: closure that is invoked in accordance with logic of throttling.
    init(handler: @escaping (FMFrameValidationError) -> Void) {
        self.handler = handler
    }
    
    /// Only after accumulating certain number of errors of specific kind `Throttler` invokes `handler` and interval between invocations is not
    /// less than `throttleThreshold`.
    func onNext(validationError: FMFrameValidationError) {
        let count = (validationErrorToCountDict[validationError] ?? 0) &+ 1
        let elapsed = Double(clock() - lastErrorTime) / Double(CLOCKS_PER_SEC)
        
        if elapsed >= throttleThreshold, count >= incidenceThreshold {
            handler(validationError)
            lastErrorTime = clock()
            validationErrorToCountDict.removeAll(keepingCapacity: true)
        } else {
            validationErrorToCountDict[validationError] = count
        }
    }
    
    func reset() {
        validationErrorToCountDict.removeAll(keepingCapacity: true)
    }
    
}
