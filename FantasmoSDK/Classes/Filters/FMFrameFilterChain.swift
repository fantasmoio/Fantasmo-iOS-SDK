//
//  FMFrameFilterChain.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

// MARK:-

/// Stateful filter for choosing the frames which are acceptable to localize against.
/// If it is necessary to process a new sequence of frames, then `startOrRestartFiltering()` must be invoked.
class FMFrameFilterChain {
    
    private var lastAcceptTime = clock()
    
    /// The number of seconds after which we forcibly accept a frame.
    private var acceptanceThreshold = 1.0
    
    /// Filter collection, in order of increasing computational cost
    private let filters: [FMFrameFilter] = [
        FMTrackingStateFilter(),
        FMCameraPitchFilter(),
        FMMovementFilter(),
        // FMBlurFilter(),
        FMImageQualityFilter()
    ]

    /// Start or restart filtering
    func restart() {
        lastAcceptTime = clock()
    }
    
    /// Accepted frames should be used for the localization.
    func evaluate(_ frame: FMFrame, state: FMLocationManager.State) -> FMFrameFilterResult {
        if shouldForceAccept() {
            lastAcceptTime = clock()
            return .accepted
        }
        
        for filter in filters {
            if (filter is FMBlurFilter || filter is FMImageQualityFilter), state != .localizing {
                continue
            }
            if case let .rejected(reason) = filter.accepts(frame) {
                return .rejected(reason: reason)
            }
        }
        
        lastAcceptTime = clock()
        return .accepted
    }

    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForceAccept() -> Bool {
        let elapsedTime = Double(clock() - lastAcceptTime) / Double(CLOCKS_PER_SEC)
        return (elapsedTime > acceptanceThreshold)
    }
}
