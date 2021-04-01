//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

enum FMRemedy {
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
    
    var remedies: [FMRemedy: Int] = [:]
    var topRemedy: FMRemedy? {
        if let topRemedy = remedies.sorted(by: { $0.1 < $1.1 }).first?.key {
            remedies.removeValue(forKey: topRemedy)
            return topRemedy
        } else {
            return nil
        }
    }
    
    func accepts(_ frame: ARFrame) -> Bool {
        
        // run frame through filters
        for filter in filters {
            if case let .rejected(remedy) = filter.accepts(frame) {
                _ = throughputAverager.addSample(value: 0.0)
                addRemedy(remedy)
                return false
            }
        }
        
        // success, the frame is acceptable
        _ = throughputAverager.addSample(value: 1.0)
        return true
    }
    
    func addRemedy(_ remedy: FMRemedy) {
        if remedies.keys.contains(remedy) {
            remedies[remedy]! &+= 1
        } else {
            remedies[remedy] = 0
        }
    }
}
