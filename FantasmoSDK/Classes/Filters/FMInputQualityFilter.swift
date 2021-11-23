//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

// MARK:-

/// Stateful filter for choosing the frames which are acceptable to localize against.
/// If it is necessary to process a new sequence of frames, then `startOrRestartFiltering()` must be invoked.
class FMInputQualityFilter: FMFrameFilter {
    
    private var lastAcceptTime = clock()
    
    /// The number of seconds after which we forcibly accept a frame.
    private let acceptanceThreshold: Float
    
    /// Filter chain, in order of increasing computational cost
    private let filters: [FMFrameFilter]
    
    init() {
        let rc = RemoteConfig.config()
        acceptanceThreshold = rc.frameAcceptanceThresholdTimeout
        
        var enabledFilters: [FMFrameFilter] = []
        if rc.isTrackingStateFilterEnabled {
            enabledFilters.append(FMTrackingStateFilter())
        }
        
        if rc.isCameraPitchFilterEnabled {
            let cameraPitchFilter = FMCameraPitchFilter(
                maxUpwardTiltDegrees: rc.cameraPitchFilterMaxUpwardTilt,
                maxDownwardTiltDegrees: rc.cameraPitchFilterMaxDownwardTilt
            )
            enabledFilters.append(cameraPitchFilter)
        }
        
        if rc.isMovementFilterEnabled {
            let movementFilter = FMMovementFilter(
                threshold: rc.movementFilterThreshold
            )
            enabledFilters.append(movementFilter)
        }
        
        if rc.isBlurFilterEnabled {
            let blurFilter = FMBlurFilter(
                varianceThreshold: rc.blurFilterVarianceThreshold,
                suddenDropThreshold: rc.blurFilterSuddenDropThreshold,
                averageThroughputThreshold: rc.blurFilterAverageThroughputThreshold
            )
            enabledFilters.append(blurFilter)
        }
        
        filters = enabledFilters
    }

    /// Start or restart filtering
    func restart() {
        lastAcceptTime = clock()
    }
    
    /// Accepted frames should be used for the localization.
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult {
        if shouldForceAccept() {
            lastAcceptTime = clock()
            return .accepted
        }
        
        for filter in filters {
            if case let .rejected(reason) = filter.accepts(frame) {
                return .rejected(reason: reason)
            }
        }
        
        lastAcceptTime = clock()
        return .accepted
    }

    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForceAccept() -> Bool {
        let elapsedTime = Float(clock() - lastAcceptTime) / Float(CLOCKS_PER_SEC)
        return (elapsedTime > acceptanceThreshold)
    }
}

/// Used for internal testing of filters
class FMInputQualityFilterTestAdapter {
    let blurFilter = FMBlurFilter(varianceThreshold: 250.0, suddenDropThreshold: 0.4, averageThroughputThreshold: 0.25)
    public var blurVariance: Float {
        blurFilter.averageVariance
    }

    public init() {

    }

    public func blurAccepts(_ frame: FMFrame) -> Bool {
        return accepts(blurFilter, frame: frame)
    }

    func accepts(_ filter: FMFrameFilter, frame: FMFrame) -> Bool {
        if case .rejected = filter.accepts(frame) {
            return false
        } else {
            return true
        }
    }
}
