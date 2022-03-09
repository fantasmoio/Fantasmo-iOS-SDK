//
//  FMFrameRejectionStatistics.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 09.03.22.
//

import Foundation

/// Accumulator of statistics about frame rejections that occurred in a session
class FMFrameRejectionStatistics {
    
    /// Dictionary containing total frames rejected by frame filteres
    public private(set) var filterRejections: [FMFrameFilterRejectionReason: Int] = [
        .pitchTooLow: 0,
        .pitchTooHigh: 0,
        .movingTooFast: 0,
        .movingTooLittle: 0,
        .insufficientFeatures: 0
    ]
    
    /// Last, most recent filter rejection that occurred in the session.
    public private(set) var lastFilterRejection: FMFrameFilterRejectionReason?
    
    /// Total of all frames rejected in the session.
    public var filterRejectionsCount: Int { return filterRejections.values.reduce(0, +) }
    
    /// Total frames rejected because the frame evaluator was busy evaluating another frame.
    public var evaluatingOtherFrame: Int = 0
    
    /// Increment the count for a specific filter rejection.
    public func addFilterRejection(_ reason: FMFrameFilterRejectionReason) {
        filterRejections[reason]! += 1
        lastFilterRejection = reason
    }
    
    /// Reset all statistics, used when starting a new session.
    public func reset() {
        lastFilterRejection = nil
        filterRejections.forEach { k, v in
            filterRejections[k] = 0
        }
        evaluatingOtherFrame = 0
    }
}
