//
//  ARKitInfo.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 14.07.2021.
//

import ARKit

/// Data struct aggregating ARKit related data accumulated starting from some starting moment.
/// To reset accumulated data and start over you should invoke `reset()`
class AccumulatedARKitInfo {
    
    public private(set) var trackingStateStatistics = TrackingStateFrameStatistics()
    public private(set) var elapsedFrames = 0
    
    var imageQualityFilterScores: [Float] = []
    var imageQualityFilterScoreThreshold: Float?
    var imageQualityFilterModelVersion: String?
    
    /// Current value of total translation in meters
    public var totalTranslation: Float {
        translationAccumulator.totalTranslation
    }

    /// Allows to receive the total translation (distance) that device has moded from the starting moment.
    public private(set) var translationAccumulator = TotalDeviceTranslationAccumulator(decimationFactor: 10)
    
    /// Spread of Eugler angles as min and max values for each compoent (that is for yaw, pitch and roll)
    public private(set) var eulerAngleSpreadsAccumulator = EulerAngleSpreadsAccumulator()
    
    public init() {}
    
    func update(with nextFrame: ARFrame) {
        elapsedFrames += 1
        trackingStateStatistics.accumulate(nextTrackingState: nextFrame.camera.trackingState)
        translationAccumulator.update(with: nextFrame)
        
        if case .normal = nextFrame.camera.trackingState {
            let eulerAngles = EulerAngles(nextFrame.camera.eulerAngles)
            eulerAngleSpreadsAccumulator.accumulate(nextEulerAngles: eulerAngles, trackingState: nextFrame.camera.trackingState)
        }
    }
    
    func reset() {
        elapsedFrames = 0
        trackingStateStatistics.reset()
        translationAccumulator.reset()
        eulerAngleSpreadsAccumulator = EulerAngleSpreadsAccumulator()
        imageQualityFilterScores.removeAll()
        imageQualityFilterScoreThreshold = nil
        imageQualityFilterModelVersion = nil
    }
}
