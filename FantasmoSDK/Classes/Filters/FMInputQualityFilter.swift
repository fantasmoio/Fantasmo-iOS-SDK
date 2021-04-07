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
    
    var delegate: FMLocationDelegate?
    
    var lastNotificationTime = clock()
    var throttleThreshold = 2.0
    var incidenceThreshold = 30
    
    // filter collection, in order of increasing computational cost
    let filters: [FMFrameFilter] = [
        FMAngleFilter(),
        FMMovementFilter(),
        FMBlurFilter(),
    ]
    
    var remedies: [FMRemedy: Int] = [:]
    
    func accepts(_ frame: ARFrame) -> Bool {
        
        // run frame through filters
        for filter in filters {
            if case let .rejected(remedy) = filter.accepts(frame) {
                _ = throughputAverager.addSample(value: 0.0)
                addRemedy(remedy)
                notifyIfNeeded(remedy)
                return false
            }
        }
        
        // success, the frame is acceptable
        _ = throughputAverager.addSample(value: 1.0)
        return true
    }
    
    func notifyIfNeeded(_ remedy: FMRemedy) {
        guard let count = remedies[remedy] else { return }
        
        let elapsed = Double(clock() - lastNotificationTime) / Double(CLOCKS_PER_SEC)
        if elapsed > throttleThreshold && count > incidenceThreshold {
            delegate?.locationManager(didRequestBehavior: FMBehaviorRequest(remedy))
            remedies.removeValue(forKey: remedy)
            lastNotificationTime = clock()
        }
    }
    
    func addRemedy(_ remedy: FMRemedy) {
        if var count = remedies[remedy] {
            count &+= 1
            remedies[remedy] = count
        } else {
            remedies[remedy] = 0
        }
    }
}
