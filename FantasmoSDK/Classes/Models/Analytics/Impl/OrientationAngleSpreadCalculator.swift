//
//  AngleSpread.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 20.07.2021.
//

import ARKit

/// Calculates angle spread of orientation angle sequence (orientation angle belongs to [-pi, pi] or [0, 2pi]) provided via
/// `update(with:trackingQuality)` function.
/// Abrupt change from -pi radians to pi radians when angle reaches bound is taken into account.
/// Calculator suits for yaw and roll as they change in the range [-pi, pi].
/// For pitch in range [-pi/2, pi/2] the spread is calculated as `max_pitch - min_pitch` with such a pecularity that rotating device around X axis
/// by pi radians will be reported as having pi/2 spread because pitch changes from 0°->90° and then from 90°->0° again owing to the way of how
/// euler angles are calculated.
struct OrientationAngleSpreadCalculator {
    
    /// Value of spread for angle in radians and falling in [0, 2pi]
    var spread: Float {
        Swift.min(Swift.max(max - min, 0), 2 * .pi)
    }
    
    /// Min rotation angle in radians falling in the range [-∞, +∞].
    /// Before getting the first angle via `update(with:trackingQuality)`the  value is `.infinity`
    private(set) var min: Float = .infinity
    
    /// Max rotation angle in radians falling in the range [-∞, +∞].
    /// Before getting the first angle via `update(with:trackingQuality)` the value is `-.infinity`
    private(set) var max: Float = -.infinity
    
    private var previousNormalAngle: Float?
    
    private var rotationAngleCalculator = RotationAngleCalculator()

    /// - parameter nextOrientationAngle: next orientation angle of angle sequence in the interval [-pi, pi] or [0, 2pi]
    mutating func update(with nextOrientationAngle: Float, trackingState: ARCamera.TrackingState) {
        rotationAngleCalculator.update(with: nextOrientationAngle, trackingState: trackingState)
        
        min = Swift.min(rotationAngleCalculator.rotationAngle ?? .infinity, min)
        max = Swift.max(rotationAngleCalculator.rotationAngle ?? -.infinity, max)
    }
    
}

