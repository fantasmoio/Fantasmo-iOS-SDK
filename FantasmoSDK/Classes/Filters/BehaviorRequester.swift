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
    
    /// The number of times the rejection must occur before triggering.
    private let incidenceThreshold = 30

    private var lastTriggerTime = clock()
    private var rejectionCounts = [FMFilterRejectionReason : Int]()

    private var requestHandler: ((FMBehaviorRequest) -> Void)

    init(handler: @escaping (FMBehaviorRequest) -> Void) {
        self.requestHandler = handler
    }

    func processResult(_ frameFilterResult: FMFrameFilterResult) {
        switch frameFilterResult {
        case .accepted:
            break
        case .rejected(let rejectionReason):
            var count = rejectionCounts[rejectionReason] == nil ? 0 : rejectionCounts[rejectionReason]!
            count += 1

            if count > incidenceThreshold {
                let elapsed = Double(clock() - lastTriggerTime) / Double(CLOCKS_PER_SEC)
                if elapsed > throttleThreshold {
                    requestHandler(rejectionReason.mapToBehaviorRequest())
                    restart()
                }
            } else {
                rejectionCounts[rejectionReason] = count
            }
        }
    }
    
    func restart() {
        lastTriggerTime = clock()
        rejectionCounts.removeAll(keepingCapacity: true)
    }
}
