//
//  ARKitInfo.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 14.07.2021.
//

import ARKit

/// Data struct aggregating ARKit related data accumulated starting from some starting moment.
/// To reset accumulated data and start over you should invoke `reset()`
struct AccumulatedARKitRelatedInfo {
    
    private(set) var trackingQualityFrameStatistics = TrackingQualityFrameStatistics()

    /// Allows to receive the total translation (distance) that device has moded from the starting moment.
    private(set) var translationAccumulator = TotalDeviceTranslationAccumulator(decimationFactor: 10)
    
    /// Spread of Eugler angles as `max - min` value for each compoent (that is for yaw, pitch and roll)
    private(set) var rotationSpread = RotationSpread()
    
    mutating func update(with nextFrame: ARFrame) {
        trackingQualityFrameStatistics.update(withNextTrackingState: nextFrame.camera.trackingState)
        translationAccumulator.update(forNextFrame: nextFrame)
        
        if case .normal = nextFrame.camera.trackingState {
            rotationSpread.update(with: EulerAngles(nextFrame.camera.eulerAngles))
        }
    }
    
    mutating func reset() {
        trackingQualityFrameStatistics.reset()
        translationAccumulator.reset()
        rotationSpread = RotationSpread()
    }
}
