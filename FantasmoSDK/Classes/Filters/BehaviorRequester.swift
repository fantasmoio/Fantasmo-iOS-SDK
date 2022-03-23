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
    
    private let initialBehavior = FMBehaviorRequest.pointAtBuildings
    private var didRequestInitialBehavior = false
    
    /// The number of times the rejection must occur before triggering.
    private let incidenceThreshold = 30

    private var lastTriggerTime = clock()
    private var lastTriggerBehavior: FMBehaviorRequest?
    
    private var rejectionCounts = [FMFrameRejectionReason : Int]()

    private var requestHandler: ((FMBehaviorRequest) -> Void)

    init(handler: @escaping (FMBehaviorRequest) -> Void) {
        self.requestHandler = handler
    }
    
    func getBehaviorRequest(_ rejectionReason: FMFrameRejectionReason) -> FMBehaviorRequest {
        switch rejectionReason {
        case .pitchTooLow:
            return .tiltUp
        case .pitchTooHigh:
            return .tiltDown
        case .movingTooFast, .trackingStateExcessiveMotion:
            return .panSlowly
        default:
            return .panAround
        }
    }
    
    func processFilterRejection(reason: FMFrameRejectionReason) {
        var count = rejectionCounts[reason] == nil ? 0 : rejectionCounts[reason]!
        count += 1

        if count > incidenceThreshold {
            let elapsed = Double(clock() - lastTriggerTime) / Double(CLOCKS_PER_SEC)
            if elapsed > throttleThreshold {
                let newBehavior = getBehaviorRequest(reason)
                let behaviorRequest = (newBehavior != lastTriggerBehavior) ? newBehavior : initialBehavior
                requestHandler(behaviorRequest)
                lastTriggerBehavior = behaviorRequest
                lastTriggerTime = clock()
                rejectionCounts.removeAll(keepingCapacity: true)
            }
        } else {
            rejectionCounts[reason] = count
        }
        
        if !didRequestInitialBehavior {
            didRequestInitialBehavior = true
            requestHandler(initialBehavior)
        }
    }
    
    func restart() {
        lastTriggerTime = clock()
        rejectionCounts.removeAll(keepingCapacity: true)
        didRequestInitialBehavior = false
    }
}
