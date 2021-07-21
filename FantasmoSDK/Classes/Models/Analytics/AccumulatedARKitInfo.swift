//
//  ARKitInfo.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 14.07.2021.
//

import ARKit

/// Data struct aggregating ARKit related data accumulated starting from some starting moment.
/// To reset accumulated data and start over you should invoke `reset()`
public class AccumulatedARKitInfo {
    
    public private(set) var trackingStateStatistics = TrackingStateFrameStatistics()

    /// Allows to receive the total translation (distance) that device has moded from the starting moment.
    public private(set) var translationAccumulator = TotalDeviceTranslationAccumulator(decimationFactor: 10)
    
    /// Spread of Eugler angles as min and max values for each compoent (that is for yaw, pitch and roll)
    public private(set) var rotationSpread = TotalRotationSpread()
    
    public init() {}
    
    func update(with nextFrame: ARFrame) {
        trackingStateStatistics.update(with: nextFrame.camera.trackingState)
        translationAccumulator.update(with: nextFrame)
        
        if case .normal = nextFrame.camera.trackingState {
            rotationSpread.update(with: EulerAngles(nextFrame.camera.eulerAngles))
        }
    }
    
    func reset() {
        trackingStateStatistics.reset()
        translationAccumulator.reset()
        rotationSpread = TotalRotationSpread()
    }
}
