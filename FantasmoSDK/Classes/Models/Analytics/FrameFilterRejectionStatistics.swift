//
//  FrameFilterRejectionStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.07.2021.
//

import Foundation

/// Accumulator of the statistics on the number of the several types of frame filter rejections.
struct FrameFilterRejectionStatisticsAccumulator {
    
    private(set) var filterRejectionReasonCounts =
        Dictionary<FMFilterRejectionReason, Int>(initialValueForAllCases: 0)
    
    /// Convenience property for retrieving number of frames which where rejected because of a too high or a too low pitch.
    var excessiveTiltRelatedRejectionCount: Int {
        (filterRejectionReasonCounts[.cameraPitchTooHigh] ?? 0) + (filterRejectionReasonCounts[.cameraPitchTooLow] ?? 0)
    }

    mutating func accumulate(filterRejectionReason: FMFilterRejectionReason) {
        filterRejectionReasonCounts[filterRejectionReason]! += 1
    }
    
    mutating func reset() {
        filterRejectionReasonCounts = Dictionary<FMFilterRejectionReason, Int>(initialValueForAllCases: 0)
    }
    
}


