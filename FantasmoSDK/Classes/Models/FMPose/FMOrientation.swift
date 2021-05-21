//
//  FMOrientationNew.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.04.2021.
//

import Foundation
import simd

// Orientation represented as a quaternion.
public struct FMOrientation: Codable {
    
    var x, y, z, w: Float
    
    init(x: Float, y: Float, z: Float, w: Float) {
        self.x = x; self.y = y; self.z = z; self.w = w
    }
    
    init(_ transform: simd_float4x4) {
        let rotation = simd_quaternion(transform)
        x = rotation.imag.x; y = rotation.imag.y; z = rotation.imag.z; w = rotation.real
    }
    
    init(_ quaternion: simd_quatf) {
        let q = quaternion
        x = q.imag.x; y = q.imag.y; z = q.imag.z; w = q.real
    }
    
    // MARK: - Operators
    
    /// The meaning of the residual (difference): if we apply `right` quaternion and then apply "difference" then we will get result identical to apply
    /// only `left` quaternion.
    static func -(left : FMOrientation, right: FMOrientation) -> FMOrientation {
        return FMOrientation( (simd_quatf(left) * (simd_quatf(right).inverse)) )
    }
    
    /// The meaning of the sum: result is equal to applying `left` as quaternion and then applying `right` as quaternion.
    static func +(left : FMOrientation, right: FMOrientation) -> FMOrientation {
        return FMOrientation( (simd_quatf(right) * simd_quatf(left)) )
    }
    
    /// The meaning of the product by scalar: the same rotation of the corresponding quaternion but by the angle equal to product of origin angle by
    /// scalar value.
    static func *(left : Float, right: FMOrientation) -> FMOrientation {
        let quaternion = simd_quatf(right)
        return FMOrientation( simd_quatf(angle: left * quaternion.angle, axis: quaternion.axis) )
    }

}
