//
//  RotationSpread.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 18.07.2021.
//

import Foundation
import simd
import ARKit

/// Spread of Euler angles covered by device over a period of time.
public final class EulerAngleSpreadsAccumulator {
    
    public var spreads: EulerAngleSpreads {
        EulerAngleSpreads(pitchSpread: pitchSpreadCalculator.spread,
                          yawSpread: yawSpreadCalculator.spread,
                          rollSpread: rollSpreadCalculator.spread)
    }
    
    /// minRotationAngle ∈ [-∞, +∞],  maxRotationAngle ∈ [-∞, +∞]
    public var pitch: (minRotationAngle: Float, maxRotationAngle: Float) {
        (pitchSpreadCalculator.min, pitchSpreadCalculator.max)
    }
    
    /// minRotationAngle ∈ [-∞, +∞],  maxRotationAngle ∈ [-∞, +∞]
    public var yaw: (minRotationAngle: Float, maxRotationAngle: Float) {
        (yawSpreadCalculator.min, yawSpreadCalculator.max)
    }
    
    /// minRotationAngle ∈ [-∞, +∞],  maxRotationAngle ∈ [-∞, +∞]
    public var roll: (minRotationAngle: Float, maxRotationAngle: Float) {
        (rollSpreadCalculator.min, rollSpreadCalculator.max)
    }

    private var pitchSpreadCalculator = OrientationAngleSpreadCalculator()
    private var yawSpreadCalculator = OrientationAngleSpreadCalculator()
    private var rollSpreadCalculator = OrientationAngleSpreadCalculator()
    
    func accumulate(nextEulerAngles: EulerAngles<Float>, trackingState: ARCamera.TrackingState) {
        pitchSpreadCalculator.update(with: nextEulerAngles.pitch, trackingState: trackingState)
        yawSpreadCalculator.update(with: nextEulerAngles.yaw, trackingState: trackingState)
        rollSpreadCalculator.update(with: nextEulerAngles.roll, trackingState: trackingState)
    }
}





