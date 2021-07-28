//
//  FrameStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 13.07.2021.
//

import ARKit

/// Accumulator of the statistics on frames by the quality of ARKit position tracking.
/// To get frame count for some tracking state retrieve correspondent value from `trackingStateFrameCounts` dictionary.
/// Example:
///     `let excessiveMotionFrameCount = trackingStateFrameCounts[.limited(.excessiveMotion)]`
public struct TrackingStateStatisticsAccumulator {
    
    public private(set) var totalCountOfFrames: Int = 0
    
    public private(set) var trackingStateFrameCounts = Dictionary<ARCamera.TrackingState, Int>(
        initialValueForAllCasesAndSubcases: 0
    )

    mutating func accumulate(nextTrackingState: ARCamera.TrackingState) {
        totalCountOfFrames += 1
        trackingStateFrameCounts[nextTrackingState] = (trackingStateFrameCounts[nextTrackingState] ?? 0) + 1
    }
    
    mutating func reset() {
        trackingStateFrameCounts = Dictionary<ARCamera.TrackingState, Int>(
            initialValueForAllCasesAndSubcases: 0
        )
        totalCountOfFrames = 0
    }
    
    /// Frames percentage for the given `trackingState`.
    /// For `limited` tracking state with some reason method returns the number of frames corresponding to that reason.
    /// Example:
    ///     `let excessiveMotionFrameCount = trackingStateFrameCounts[.limited(.excessiveMotion)]`
    public func framePercentage(forTrackingState trackingState: ARCamera.TrackingState) -> Float {
        let frameCount = trackingStateFrameCounts[trackingState] ?? 0
        return framePercentage(forFrameCount: frameCount)
    }
    
    /// Percentage of the frames for `ARFrame.camera.trackingState == .limited` without regard to reason.
    public var percentageForLimitedTrackingStateIrrelativeToReason: Float {
        var frameCount = trackingStateFrameCounts[.limited(.initializing)] ?? 0
        frameCount += trackingStateFrameCounts[.limited(.relocalizing)] ?? 0
        frameCount += trackingStateFrameCounts[.limited(.excessiveMotion)] ?? 0
        frameCount += trackingStateFrameCounts[.limited(.insufficientFeatures)] ?? 0
        return framePercentage(forFrameCount: frameCount)
    }
    
    private func framePercentage(forFrameCount count: Int) -> Float {
        if totalCountOfFrames != 0 {
            return 100 * Float(count) / Float(totalCountOfFrames)
        }
        else {
            return 0
        }
    }
}

private extension Dictionary where Key == ARCamera.TrackingState {
    init(initialValueForAllCasesAndSubcases value: Value) {
        self.init()
        self[.normal] = value
        self[.limited(.initializing)] = value
        self[.notAvailable] = value
    }
}
