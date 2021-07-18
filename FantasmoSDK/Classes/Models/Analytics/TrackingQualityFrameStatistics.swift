//
//  FrameStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 13.07.2021.
//

import ARKit

/// Statistics on frames by the quality of ARKit position tracking.
struct TrackingQualityFrameStatistics {
    
    /// Number of frames captured at the moment when tracking state was `ARFrame.camera.trackingState == .notAvailable`
    private(set) var framesWithNotAvailableTracking: Int = 0
    
    /// Number of frames captured at the moment when tracking state was `ARFrame.camera.trackingState == .limited`
    private(set) var framesWithLimitedTrackingStateByReason: [ARCamera.TrackingState.Reason : Int] = [
        .initializing: 0,
        .relocalizing: 0,
        .excessiveMotion : 0,
        .insufficientFeatures : 0,
    ]

    /// Number of frames captured at the moment when tracking state  was`ARFrame.camera.trackingState == .normal`
    private(set) var framesWithNormalTrackingState: Int = 0
    
    private(set) var totalNumberOfFrames: Int = 0
    
    mutating func update(withNextTrackingState trackingState: ARCamera.TrackingState) {
        totalNumberOfFrames += 1

        if case .limited(let reason) = trackingState {
            framesWithLimitedTrackingStateByReason[reason] = (framesWithLimitedTrackingStateByReason[reason] ?? 0) + 1
        }
    }
    
    mutating func reset() {
        framesWithNotAvailableTracking = 0
        framesWithLimitedTrackingStateByReason.forEach { key, _ in
            framesWithLimitedTrackingStateByReason[key] = 0
        }
        framesWithNormalTrackingState = 0
        totalNumberOfFrames = 0
    }
}
