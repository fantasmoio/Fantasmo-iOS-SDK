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
    private var requestHandler: ((FMBehaviorRequest) -> Void)
    private var rejectionCounts = [FMFilterRejectionReason : Int]()
    private var lastFrameFilterResult: FMFrameFilterResult?

    init(handler: @escaping (FMBehaviorRequest) -> Void) {
        self.requestHandler = handler
    }
    
    func processResult(_ frameFilterResult: FMFrameFilterResult) {
        switch frameFilterResult {
        case .accepted:
            rejectionCounts.removeAll(keepingCapacity: true)
        case .rejected(let rejectionReason):
            let count = (rejectionCounts[rejectionReason] ?? 0) &+ 1
            
            if count == 1, case .accepted = lastFrameFilterResult {
                lastTimeOfTriggering = clock()
                rejectionCounts[rejectionReason] = count
            }
            else {
                let elapsed = Double(clock() - lastTimeOfTriggering) / Double(CLOCKS_PER_SEC)
                
                if elapsed > throttleThreshold, count >= incidenceThreshold {
                    requestHandler(rejectionReason.mapToBehaviorRequest())
                    startNewCycle()
                }
                else {
                    rejectionCounts[rejectionReason] = count
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
        rejectionCounts.removeAll(keepingCapacity: true)
    }

}
