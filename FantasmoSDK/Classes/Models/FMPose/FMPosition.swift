//
//  FMPositionNew.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.04.2021.
//

import Foundation
import simd

public struct FMPosition: Codable, Equatable {
    
    var x, y, z: Float
    
    init(x: Float, y: Float, z: Float) {
        self.x = x; self.y = y; self.z = z
    }
    
    init(_ transform: simd_float4x4) {
        let translation = transform.columns.3
        x = translation.x; y = translation.y; z = translation.z
    }
    
    func distance(to position: FMPosition) -> Float {
        sqrtf(powf(self.x - position.x, 2.0) + powf(self.y - position.y, 2.0) + powf(self.z - position.z, 2.0))
    }
    
    // MARK: - Operators
    
    /// The meaning: difference of corresponding vectors
    static func -(left : FMPosition, right: FMPosition) -> FMPosition {
        FMPosition(x: left.x - right.x, y: left.y - right.y, z: left.z - right.z)
    }
    
    /// The meaning: sum of corresponding vectors
    static func +(left : FMPosition, right: FMPosition) -> FMPosition {
        FMPosition(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
    }
    
    /// The meaning: product of the corresponding vector by scalar.
    static func *(left: Float, right : FMPosition) -> FMPosition {
        return FMPosition(x: left * right.x, y: left * right.y, z: left * right.z)
    }

}
