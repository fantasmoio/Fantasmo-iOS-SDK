//
//  FrameFilterRejectionStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.07.2021.
//

import Foundation

/// Accumulator of the statistics on the number of the several types of frame filter rejections.
public class FrameFilterRejectionStatisticsAccumulator {
    
    public private(set) var counts =
        Dictionary<FMFilterRejectionReason, Int>(initialValueForAllCases: 0)
        
    var total: Int {
        counts.values.reduce(0, +)
    }

    func accumulate(filterRejectionReason: FMFilterRejectionReason) {
        counts[filterRejectionReason]! += 1
    }
    
    func reset() {
        counts = Dictionary<FMFilterRejectionReason, Int>(initialValueForAllCases: 0)
    }
    
}

