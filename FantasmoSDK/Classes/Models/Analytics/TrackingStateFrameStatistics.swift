//
//  FrameStatistics.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 13.07.2021.
//

import ARKit

/// Statistics on frames by the quality of ARKit position tracking.
public struct TrackingStateFrameStatistics {
    
    public private(set) var totalNumberOfFrames: Int = 0
    
    /// Number of frames captured at the moment when tracking state  was`ARFrame.camera.trackingState == .normal`
    public private(set) var framesWithNormalTrackingState: Int = 0
    
    public var framesWithLimitedTrackingState: Int = 0
    
    /// Number of frames captured at the moment when tracking state was `ARFrame.camera.trackingState == .notAvailable`
    public private(set) var framesWithNotAvailableTracking: Int = 0
    
    /// Number of frames captured at the moment when tracking state was `ARFrame.camera.trackingState == .limited`
    public private(set) var framesWithLimitedTrackingStateByReason: [ARCamera.TrackingState.Reason : Int] = [
        .initializing: 0,
        .relocalizing: 0,
        .excessiveMotion : 0,
        .insufficientFeatures : 0,
    ]
    
    mutating func update(with nextTrackingState: ARCamera.TrackingState) {
        totalNumberOfFrames += 1
        
        switch nextTrackingState {
        case .normal:
            framesWithNormalTrackingState += 1
        case .limited(let reason):
            framesWithLimitedTrackingStateByReason[reason] = (framesWithLimitedTrackingStateByReason[reason] ?? 0) + 1
            framesWithLimitedTrackingState += 1
        case .notAvailable:
            framesWithNotAvailableTracking += 1
        }
    }
    
    mutating func reset() {
        framesWithNotAvailableTracking = 0
        framesWithLimitedTrackingState = 0
        framesWithLimitedTrackingStateByReason.forEach { key, _ in
            framesWithLimitedTrackingStateByReason[key] = 0
        }
        framesWithNormalTrackingState = 0
        totalNumberOfFrames = 0
    }
}
