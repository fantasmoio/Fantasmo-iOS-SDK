//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

protocol FMFrameFilter {
    func accepts(_ frame: ARFrame) -> Bool
}

public class FMInputQualityFilter: FMFrameFilter {
    
    private var throughputAverager = MovingAverage()
    public var quality: Double {
        throughputAverager.average
    }
    
    let filters: [FMFrameFilter] = [
        FMAngleFilter(),
        FMMovementFilter(),
    ]
    
    func accepts(_ frame: ARFrame) -> Bool {
        for filter in filters {
            if !filter.accepts(frame) {
                _ = throughputAverager.addSample(value: 0.0)
                return false
            }
        }
        _ = throughputAverager.addSample(value: 1.0)
        return true
    }
}
