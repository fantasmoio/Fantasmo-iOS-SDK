//
//  simd_quatf.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.04.2021.
//

import simd

extension simd_quatf {
    
    init(_ orientation: FMOrientation) {
        self.init(ix: orientation.x, iy: orientation.y, iz: orientation.z, r: orientation.w)
    }
    
    /// Retrieve euler angles from a quaternion matrix.
    /// Yaw, pitch and roll corresponds to yx'z'' intrinsic rotations in iOS adopted coordinate system for camera with Y-axis pointed upward.
    /// Ranges:
    ///     yaw: [−π, π];  pitch: [−π/2, π/2];   roll: [−π, π]
    var eulerAngles: EulerAngles<Float> {
        get {
            // First we transfer from iOS adopted coordinate system with Y-axis pointed upwards to the usual coordinate
            // system, which has Z-axis pointed upwards and then find yaw, pitch and roll, which are the same for both
            // coordinate systems, only correspond to the rotating about different axes.
            let (qx, qy, qz, qw) = (imag.z, imag.x, imag.y, real)

            //then we deduce euler angles with some cosines
            //see https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
            // roll (z-axis rotation)
            let sinr = +2.0 * (qw * qx + qy * qz)
            let cosr = +1.0 - 2.0 * (qx * qx + qy * qy)
            let roll = atan2(sinr, cosr)

            // pitch (x-axis rotation)
            let sinp = +2.0 * (qw * qy - qz * qx)
            var pitch: Float
            if abs(sinp) >= 1 {
                 pitch = copysign(Float.pi / 2, sinp)
            } else {
                pitch = asin(sinp)
            }

            // yaw (y-axis rotation)
            let siny = +2.0 * (qw * qz + qx * qy)
            let cosy = +1.0 - 2.0 * (qy * qy + qz * qz)
            let yaw = atan2(siny, cosy)

            return EulerAngles(pitch: pitch, yaw: yaw, roll: roll)
        }
    }
    
}
