//
//  RotationSpread.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 18.07.2021.
//

import Foundation
import simd

/// Spread of Euler angles covered by device over a period of time.
public struct TotalRotationSpread {
    /// Spread for the yaw Euler angle
    public var yaw: (min: Float, max: Float) = (0, 0)
    
    /// Spread for the pitch Euler angle
    public var pitch: (min: Float, max: Float) = (0, 0)
    
    /// Spread for the roll Euler angle
    public var roll: (min: Float, max: Float) = (0, 0)
    
    mutating func update(with euglerAngles: EulerAngles<Float>) {
        yaw.min = min(yaw.min, euglerAngles.yaw)
        yaw.max = max(yaw.max, euglerAngles.yaw)
        pitch.min = min(pitch.min, euglerAngles.pitch)
        pitch.max = max(pitch.max, euglerAngles.pitch)
        roll.min = min(roll.min, euglerAngles.roll)
        roll.max = max(roll.max, euglerAngles.roll)
    }
}
