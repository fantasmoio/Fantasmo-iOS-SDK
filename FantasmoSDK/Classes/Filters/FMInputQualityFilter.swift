//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

enum FMFilterRejectionReason {
    case pitchTooLow
    case pitchTooHigh
    case movingTooFast
    case movingTooLittle
}

enum FMFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFilterRejectionReason)
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
    
    var rejections: [FMFilterRejectionReason: Int] = [:]
    
    /// run ARFrame through quality filter collection
    func accepts(_ frame: ARFrame) -> Bool {
        
        // run frame through filters
        for filter in filters {
            if case let .rejected(rejection) = filter.accepts(frame) {
                _ = throughputAverager.addSample(value: 0.0)
                addRejection(rejection)
                notifyIfNeeded(rejection)
                return false
            }
        }
        
        // success, the frame is acceptable
        _ = throughputAverager.addSample(value: 1.0)
        return true
    }
    
    /// notify client when too many rejections occur
    func notifyIfNeeded(_ rejection: FMFilterRejectionReason) {
        guard let count = rejections[rejection] else { return }
        
        let elapsed = Double(clock() - lastNotificationTime) / Double(CLOCKS_PER_SEC)
        if elapsed > throttleThreshold && count > incidenceThreshold {
            delegate?.locationManager(didRequestBehavior: FMBehaviorRequest(rejection))
            rejections.removeAll(keepingCapacity: true)
            lastNotificationTime = clock()
        }
    }
    
    /// keep track of number of incidences of each filter rejection
    func addRejection(_ rejection: FMFilterRejectionReason) {
        if var count = rejections[rejection] {
            count &+= 1
            rejections[rejection] = count
        } else {
            rejections[rejection] = 0
        }
    }
}
