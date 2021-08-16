//
//  BehaviorRequester.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 15.04.2021.
//

import Foundation

class BehaviorRequester {
    
    /// Minimum number of seconds that must elapse between trigering events.
    private let throttleThreshold = 2.0
    
    /// The number of times the rejection must occur before triggering.
    private let incidenceThreshold = 30

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
    func processResult(_ frameFilterResult: FMFrameFilterResult) {
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
