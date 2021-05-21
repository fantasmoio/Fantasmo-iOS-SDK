//
//  EulerAngles.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 29.04.2021.
//

import simd

/// Corresponds to yx'z'' intrinsic rotation.
public struct EulerAngles<Scalar>: CustomStringConvertible where Scalar: SIMDScalar&FloatingPoint&BinaryFloatingPoint {
    
    /// Corresponds to rotation about internal x'-axis. Given in radians.
    public let pitch: Scalar
    
    /// Corresponds to rotation about y-axis. Given in radians.
    public let yaw: Scalar
    
    /// Corresponding to rotation about internal z''-axis.  Given in radians.
    public let roll: Scalar
    
    public init(pitch: Scalar, yaw: Scalar, roll: Scalar) {
        self.pitch = pitch; self.yaw = yaw; self.roll = roll
    }
    
    /// - Parameter angles: given in radians.
    public init(_ angles: SIMD3<Scalar>) {
        pitch = angles.x; yaw = angles.y; roll = angles.z
    }
    
    public func description(format: String, units: UnitAngle = .radians) -> String {
        let _pitch = Measurement(value: Double(pitch), unit: UnitAngle.radians)
        let _yaw = Measurement(value: Double(yaw), unit: UnitAngle.radians)
        let _roll = Measurement(value: Double(roll), unit: UnitAngle.radians)
        let args: [CVarArg] =
            [_pitch.converted(to: units).value, _yaw.converted(to: units).value, _roll.converted(to: units).value]
        
        return String(format: format, arguments: args)
    }
    
    // MARK: - CustomStringConvertible
    public var description: String {
        return "\(EulerAngles.self): yaw: \(rad2deg(yaw))˚, pitch: \(rad2deg(pitch))˚, roll: \(rad2deg(roll))˚"
    }

}
