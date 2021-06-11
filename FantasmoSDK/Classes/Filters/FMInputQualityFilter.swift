//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

public enum FMFilterRejectionReason {
    case pitchTooLow
    case pitchTooHigh
    case movingTooFast
    case movingTooLittle
}

public enum FMFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFilterRejectionReason)
}

protocol FMFrameFilter {
    func accepts(_ frame: ARFrame) -> FMFilterResult
}

// MARK:-

public class FMInputQualityFilter {
    
    var delegate: FMLocationDelegate?
    
    /// the last time a frame was accepted
    var lastAcceptTime = clock()
    /// number of seconds after which we force acceptance
    var acceptanceThreshold = 6.0
    
    /// the last time we issued a behavior request
    var lastRequestTime = clock()
    /// minimum number of seconds that must elapse between behavior requests
    var throttleThreshold = 2.0
    /// the number of times a rejection occurs that should prompt a behavior request
    var incidenceThreshold = 30
    
    /// filter collection, in order of increasing computational cost
    let filters: [FMFrameFilter] = [
        FMAngleFilter(),
        FMMovementFilter(),
        FMBlurFilter(),
    ]
    
    var rejections: [FMFilterRejectionReason: Int] = [:]

    func startFiltering() {
        resetAcceptanceClock()
        resetRejectionCount()
    }

    private func resetAcceptanceClock() {
        lastAcceptTime = clock()
    }

    private func resetRejectionCount() {
        rejections.removeAll(keepingCapacity: true)
    }
    
    /// run ARFrame through quality filter collection
    func accepts(_ frame: ARFrame) -> Bool {

        if !shouldForceAccept() {
            // run frame through filters
            for filter in filters {
                if case let .rejected(rejection) = filter.accepts(frame) {
                    addRejection(rejection)
                    notifyIfNeeded(rejection)
                    return false
                }
            }
        }

        // success, the frame is acceptable
        resetAcceptanceClock()
        return true
    }

    /// if there are a lot of continuous rejections, we force an acceptance
    func shouldForceAccept() -> Bool {
        let elapsed = Double(clock() - lastAcceptTime) / Double(CLOCKS_PER_SEC)
        return elapsed > acceptanceThreshold
    }

    /// notify client when too many rejections occur
    func notifyIfNeeded(_ rejection: FMFilterRejectionReason) {
        guard let count = rejections[rejection] else { return }
        
        let elapsed = Double(clock() - lastRequestTime) / Double(CLOCKS_PER_SEC)
        if elapsed > throttleThreshold && count > incidenceThreshold {
            delegate?.locationManager(didRequestBehavior: FMBehaviorRequest(rejection))
            resetRejectionCount()
            lastRequestTime = clock()
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

/// Use for internal testing of filters
public class FMInputQualityFilterTestAdapter {
    let blurFilter = FMBlurFilter()
    public var blurVariance: Float {
        blurFilter.averageVariance
    }

    public init() {

    }

    public func blurAccepts(_ frame: ARFrame) -> Bool {
        return accepts(blurFilter, frame: frame)
    }

    func accepts(_ filter: FMFrameFilter, frame: ARFrame) -> Bool {
        if case .rejected(_) = filter.accepts(frame) {
            return false
        } else {
            return true
        }
    }
}
