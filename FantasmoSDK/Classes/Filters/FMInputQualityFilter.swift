//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

enum FMRemedy: String {
    case tiltUp
    case tiltDown
    case slowDown
    case panAround
}

enum FMFilterResult: Equatable {
    case accepted
    case rejected(remedy: FMRemedy)
}

protocol FMFrameFilter {
    func accepts(_ frame: ARFrame) -> FMFilterResult
}

// MARK:-

public class FMInputQualityFilter {
    
    private var throughputAverager = MovingAverage()
    public var quality: Double {
        throughputAverager.average
    }
    
    let filters: [FMFrameFilter] = [
        FMAngleFilter(),
        FMMovementFilter(),
        FMBlurFilter(),
    ]
    
    func accepts(_ frame: ARFrame) -> Bool {
        
        // run frame through filters
        for filter in filters {
            if filter.accepts(frame) != .accepted {
                _ = throughputAverager.addSample(value: 0.0)
                return false
            }
        }
        
        // success, the frame is acceptable
        _ = throughputAverager.addSample(value: 1.0)
        return true
    }
}
