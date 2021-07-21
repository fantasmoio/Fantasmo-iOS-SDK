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
public struct EulerAngleSpreads {
    
    /// minRotationAngle ∈ [-∞, +∞],  maxRotationAngle ∈ [-∞, +∞], spread ∈ [0, pi]
    public var pitch: (minRotationAngle: Float, maxRotationAngle: Float, spread: Float) {
        (pitchSpreadCalculator.min, pitchSpreadCalculator.max, pitchSpreadCalculator.spread)
    }
    
    /// minRotationAngle ∈ [-∞, +∞],  maxRotationAngle ∈ [-∞, +∞], spread ∈ [0, 2pi]
    public var yaw: (minRotationAngle: Float, maxRotationAngle: Float, spread: Float) {
        (yawSpreadCalculator.min, yawSpreadCalculator.max, yawSpreadCalculator.spread)
    }
    
    /// minRotationAngle ∈ [-∞, +∞],  maxRotationAngle ∈ [-∞, +∞], spread ∈ [0, 2pi]
    public var roll: (minRotationAngle: Float, maxRotationAngle: Float, spread: Float) {
        (rollSpreadCalculator.min, rollSpreadCalculator.max, rollSpreadCalculator.spread)
    }

    private var pitchSpreadCalculator = OrientationAngleSpreadCalculator()
    private var yawSpreadCalculator = OrientationAngleSpreadCalculator()
    private var rollSpreadCalculator = OrientationAngleSpreadCalculator()
    
    mutating func update(with nextEulerAngles: EulerAngles<Float>, trackingState: ARCamera.TrackingState) {
        pitchSpreadCalculator.update(with: nextEulerAngles.pitch, trackingState: trackingState)
        yawSpreadCalculator.update(with: nextEulerAngles.yaw, trackingState: trackingState)
        rollSpreadCalculator.update(with: nextEulerAngles.roll, trackingState: trackingState)
    }
}





