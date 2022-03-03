//
//  FrameFilterRejectionStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.07.2021.
//

import Foundation

/// Accumulator of the statistics on the number of the several types of frame filter rejections.
class FrameFilterRejectionStatisticsAccumulator {
    
    public private(set) var counts =
        Dictionary<FMFrameFilterRejectionReason, Int>(initialValueForAllCases: 0)
        
    var total: Int {
        counts.values.reduce(0, +)
    }

    func accumulate(filterRejectionReason: FMFrameFilterRejectionReason) {
        counts[filterRejectionReason]! += 1
    }
    
    func reset() {
        counts = Dictionary<FMFrameFilterRejectionReason, Int>(initialValueForAllCases: 0)
    }
    
}

