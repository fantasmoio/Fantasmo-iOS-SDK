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
    
    mutating func update(with eulerAngles: EulerAngles<Float>) {
        yaw.min = min(yaw.min, eulerAngles.yaw)
        yaw.max = max(yaw.max, eulerAngles.yaw)
        pitch.min = min(pitch.min, eulerAngles.pitch)
        pitch.max = max(pitch.max, eulerAngles.pitch)
        roll.min = min(roll.min, eulerAngles.roll)
        roll.max = max(roll.max, eulerAngles.roll)
    }
}
