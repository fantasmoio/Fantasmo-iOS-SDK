//
//  BehaviorRequester.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/16/21.
//

import Foundation

class BehaviorRequester {
    
    /// Minimum number of seconds that must elapse between trigering events.
    private let throttleThreshold = 2.0
    
    private let defaultBehavior = FMBehaviorRequest.pointAtBuildings
    private var didRequestInitialDefaultBehavior = false
    
    /// The number of times the rejection must occur before triggering.
    private let incidenceThreshold = 30

    private var lastTriggerTime = clock()
    private var lastTriggerBehavior: FMBehaviorRequest?
    
    private var rejectionCounts = [FMFrameFilterRejectionReason : Int]()

    private var requestHandler: ((FMBehaviorRequest) -> Void)

    init(handler: @escaping (FMBehaviorRequest) -> Void) {
        self.requestHandler = handler
    }

    func processFilterRejection(reason: FMFrameFilterRejectionReason) {
        var count = rejectionCounts[reason] == nil ? 0 : rejectionCounts[reason]!
        count += 1

        if count > incidenceThreshold {
            let elapsed = Double(clock() - lastTriggerTime) / Double(CLOCKS_PER_SEC)
            if elapsed > throttleThreshold {
                let newBehavior = reason.mapToBehaviorRequest()
                let behaviorRequest = (newBehavior != lastTriggerBehavior) ? newBehavior : defaultBehavior
                requestHandler(behaviorRequest)
                lastTriggerBehavior = behaviorRequest
                lastTriggerTime = clock()
                rejectionCounts.removeAll(keepingCapacity: true)
            }
        } else {
            rejectionCounts[reason] = count
        }
        
        if !didRequestInitialDefaultBehavior {
            didRequestInitialDefaultBehavior = true
            requestHandler(defaultBehavior)
        }
    }
    
    func restart() {
        lastTriggerTime = clock()
        rejectionCounts.removeAll(keepingCapacity: true)
        didRequestInitialDefaultBehavior = false
    }
}
