//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

// MARK:-

/// Stateful filter for choosing the frames which are acceptable to localize against.
/// Frames are expected to be passed sequentially to the `accepts(_:)` method in the proper order.
/// If it is necessary to process a new sequence of frames, then `startOrRestartFiltering()` must be invoked.
class FMCompoundFrameQualityFilter {
    
    /// We use `clock()` rathern than `Date()` as it is likely faster. Some hint at this can be found at https://bit.ly/3vExXcZ
    private var timestampOfLastAcceptedFrame: clock_t?
    
    /// The number of seconds after which we forcibly accept a frame.
    private var acceptanceThreshold = 6.0
    
    /// Filter collection, in order of increasing computational cost
    private let filters: [FMFrameFilter] = [
        FMCameraPitchFilter(),
        FMMovementFilter(),
        FMBlurFilter(),
    ]

    /// Invoke this method when it is needed to start validating a new sequence of frames.
    /// Impl details: Invoking this method will ensure that first frame on the new sequence will not be force approved without assessing for quality.
    func startOrRestartFiltering() {
        timestampOfLastAcceptedFrame = nil
    }
    
    /// Indicate whether passed `frame` should be used for the localization.
    /// Frame is assessed for quality by various aspects and is accepted without any assessment if the last successfully accepted
    /// frame was passed long ago.
    /// If it is needed to start working with new sequence of frames then invoke `startOrRestartFiltering()` or create new instance
    /// of this class.
    func accepts(_ frame: ARFrame) -> FMFrameFilterResult {
        if shouldForciblyAccept(frame) {
            timestampOfLastAcceptedFrame = clock()
            return .accepted
        }
        
        for filter in filters {
            if case let .rejected(reason) = filter.accepts(frame) {
                if timestampOfLastAcceptedFrame == nil {
                    timestampOfLastAcceptedFrame = clock()
                }
                return .rejected(reason: reason)
            }
        }
        
        timestampOfLastAcceptedFrame = clock()
        return .accepted
    }

    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForciblyAccept(_ frame: ARFrame) -> Bool {
        if let t = timestampOfLastAcceptedFrame {
            let elapsedTime = Double(clock() - t) / Double(CLOCKS_PER_SEC)
            return (elapsedTime > acceptanceThreshold)
        }
        else {
            return false
        }
    }
    
}

/// Used for internal testing of filters
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
        if case .rejected = filter.accepts(frame) {
            return false
        } else {
            return true
        }
    }
}
