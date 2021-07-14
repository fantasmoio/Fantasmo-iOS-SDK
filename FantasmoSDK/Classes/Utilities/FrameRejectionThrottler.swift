//
//  FrameValidationThrotler.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 15.04.2021.
//

import Foundation

/// Throttler for "frame rejection" events each of which occurs when a frame turns out to be not acceptable for a localization.
/// Throttling technique corresponds to classic throttling on "leading" edge but very first triggering is omitted and triggering does not happen until
/// certain number of events have occurred since previous triggering event.
/// Example of throttling on "leading" edge can be found at https://bit.ly/3dl2RAz
/// When starting to capture a new frame sequence it is needed to invoke `restart()`
class FrameRejectionThrottler {
    
    /// Minimum number of seconds that must elapse between trigering events.
    private let throttleThreshold = 2.0
    
    /// The number of times the rejection must occurs before triggering.
    private let incidenceThreshold = 30
    
    /// We use `clock()` rathern than `Date()` as it is likely faster. Some hint at this can be found at https://bit.ly/3vExXcZ
    private var lastTimeOfTriggering = clock()
    
    private var handler: ((FMFilterRejectionReason) -> Void)
    private var rejectionToCountDict = [FMFilterRejectionReason : Int]()
    private var lastFrameFilterResult: FMFrameFilterResult?
    
    /// - Parameter handler: closure that is invoked in accordance with logic of throttling. See the comment to the class for more details.
    init(handler: @escaping (FMFilterRejectionReason) -> Void) {
        self.handler = handler
    }
    
    /// Throttling technique corresponds to classic throttling on "leading" edge but very first triggering is omitted and triggering does not happen until
    /// certain number of events have occurred since previous triggering event.
    /// Filter is restart at every `frameFilterResult == .accepted`
    func onNext(frameFilterResult: FMFrameFilterResult) {
        switch frameFilterResult {
        case .accepted:
            rejectionToCountDict.removeAll(keepingCapacity: true)
        case .rejected(let rejectionReason):
            let count = (rejectionToCountDict[rejectionReason] ?? 0) &+ 1
            
            if count == 1, case .accepted = lastFrameFilterResult {
                lastTimeOfTriggering = clock()
                rejectionToCountDict[rejectionReason] = count
            }
            else {
                let elapsed = Double(clock() - lastTimeOfTriggering) / Double(CLOCKS_PER_SEC)
                
                if elapsed > throttleThreshold, count >= incidenceThreshold {
                    handler(rejectionReason)
                    startNewCycle()
                }
                else {
                    rejectionToCountDict[rejectionReason] = count
                }
            }
        }
        lastFrameFilterResult = frameFilterResult
    }
    
    func restart() {
        startNewCycle()
    }
    
    private func startNewCycle() {
        lastTimeOfTriggering = clock()
        rejectionToCountDict.removeAll(keepingCapacity: true)
    }

}
