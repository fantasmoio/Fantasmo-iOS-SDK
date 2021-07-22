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

/// Helper methods for getting percentage
extension TrackingStateFrameStatistics {
    
    /// Percentage of the frames for `ARFrame.camera.trackingState == .normal`
    public var percentageForNormalTrackingState: Float {
        framesPercentage(for: framesWithNormalTrackingState)
    }
    
    /// Percentage of the frames for `ARFrame.camera.trackingState == .limited`
    public var percentageForLimitedTrackingState: Float {
        framesPercentage(for: framesWithLimitedTrackingState)
    }
    
    /// Percentage of the frames for `ARFrame.camera.trackingState == .notAvailable`
    public var percentageForNotAvailabeTrackingState: Float {
        framesPercentage(for: framesWithNotAvailableTracking)
    }
    
    /// Percentage of the frames among the `totalNumberOfFrames` for `ARFrame.camera.trackingState == .limited` having
    /// the passed `reason` as a cause of limited position-tracking quality
    public func percentageForLimitedTrackingState(with reason: ARCamera.TrackingState.Reason) -> Float {
        framesPercentage(for:  framesWithLimitedTrackingStateByReason[reason] ?? 0 )
    }
    
    private func framesPercentage(for frameCount: Int) -> Float {
        if totalNumberOfFrames != 0 {
            return 100 * Float(frameCount) / Float(totalNumberOfFrames)
        }
        else {
            return 0
        }
    }
    
}
