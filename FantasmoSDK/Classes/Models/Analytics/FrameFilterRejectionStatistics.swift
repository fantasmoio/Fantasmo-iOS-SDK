//
//  FrameFilterRejectionStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.07.2021.
//

import Foundation

/// Accumulator of the statistics on the number of the several types of frame filter rejections.
struct FrameFilterRejectionStatisticsAccumulator {
    
    private(set) var filterRejectionReasonToCountDict =
        Dictionary<FMFilterRejectionReason, Int>(initialValueForAllCases: 0)
        

    mutating func accumulate(filterRejectionReason: FMFilterRejectionReason) {
        filterRejectionReasonToCountDict[filterRejectionReason]! += 1
    }
    
    mutating func reset() {
        filterRejectionReasonToCountDict = Dictionary<FMFilterRejectionReason, Int>(initialValueForAllCases: 0)
    }
    
}

