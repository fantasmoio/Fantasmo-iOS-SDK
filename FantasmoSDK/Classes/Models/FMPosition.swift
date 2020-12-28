//
//  FMPosition.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import ARKit

// Position of the device at the moment of image capture . Units are meters.
public struct FMPosition:Codable, Equatable {
    
    var x:Float
    var y:Float
    var z:Float
    
    // Extracts the position from an ARKit camera transform matrix and converts
    // from iOS coordinates (right-handed, Y Up) to OpenCV coordinates (right-handed, Y Down)
    init(fromTransform transform:simd_float4x4) {
        x = transform.columns.3.x
        y = -transform.columns.3.y
        z = -transform.columns.3.z
    }
    
    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    func interpolated(distance: Float, startPosition: FMPosition, differencePosition: FMPosition) -> FMPosition {
        let resultX = self.x + startPosition.x + distance*differencePosition.x
        let resultY = self.y + startPosition.y + distance*differencePosition.y
        let resultZ = self.z + startPosition.z + distance*differencePosition.z
        
        return FMPosition(resultX, resultY, resultZ)
    }
    
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = Float(x)
        self.y = Float(y)
        self.z = Float(z)
    }
    
    init(_ pos: FMPosition) {
        self.x = Float(pos.x)
        self.y = Float(pos.y)
        self.z = Float(pos.z)
    }
    
    func toString() -> String {
        return String(format: "x: %3.2f :: y: %3.2f :: z: %3.2f", x, y, z)
    }
    
    func distance(toPosition: FMPosition) -> Float {
        return sqrtf(powf(self.x - toPosition.x, 2.0) + powf(self.y - toPosition.y, 2.0) + powf(self.z - toPosition.z, 2.0))
    }
    
    static func +(left : FMPosition, right: FMPosition) -> FMPosition {
        let sx = left.x + right.x
        let sy = left.y + right.y
        let sz = left.z + right.z
        return FMPosition(sx, sy, sz)
    }
    
    static func -(left : FMPosition, right: FMPosition) -> FMPosition {
        let sx = left.x - right.x
        let sy = left.y - right.y
        let sz = left.z - right.z
        return FMPosition(sx, sy, sz)
    }
    
    static func +=(left : inout FMPosition, right: FMPosition) {
        left.x += right.x
        left.y += right.y
        left.z += right.z
    }
    
    static func / (left: FMPosition, right : Double) -> FMPosition {
        let sx = left.x / Float(right)
        let sy = left.y / Float(right)
        let sz = left.z / Float(right)
        return FMPosition(sx, sy, sz)
    }
    
    static func / (left: FMPosition, right : Float) -> FMPosition {
        let sx = left.x / Float(right)
        let sy = left.y / Float(right)
        let sz = left.z / Float(right)
        return FMPosition(sx, sy, sz)
    }
    
    static func / (left: FMPosition, right : Int) -> FMPosition {
        let sx = left.x / Float(right)
        let sy = left.y / Float(right)
        let sz = left.z / Float(right)
        return FMPosition(sx, sy, sz)
    }
    
    static func * (left: FMPosition, right : Double) -> FMPosition {
        let sx = left.x * Float(right)
        let sy = left.y * Float(right)
        let sz = left.z * Float(right)
        return FMPosition(sx, sy, sz)
    }
    
    static func * (left: FMPosition, right : Float) -> FMPosition {
        let sx = left.x * Float(right)
        let sy = left.y * Float(right)
        let sz = left.z * Float(right)
        return FMPosition(sx, sy, sz)
    }
    
    static func * (left: FMPosition, right : Int) -> FMPosition {
        let sx = left.x * Float(right)
        let sy = left.y * Float(right)
        let sz = left.z * Float(right)
        return FMPosition(sx, sy, sz)
    }
    
    func norm() -> Double {
        return Double(x*x + y*y + z*z).squareRoot()
    }
    
    mutating func normalize() {
        self = self / self.norm()
    }
}
