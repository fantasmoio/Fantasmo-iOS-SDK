//
//  TOSPosition.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import ARKit

public struct TOSPosition:Codable, Equatable {
    
    var x:Float
    var y:Float
    var z:Float
    
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
    
    func interpolated(distance: Float, startPosition: TOSPosition, differencePosition: TOSPosition) -> TOSPosition {
        let resultX = self.x + startPosition.x + distance*differencePosition.x
        let resultY = self.y + startPosition.y + distance*differencePosition.y
        let resultZ = self.z + startPosition.z + distance*differencePosition.z
        
        return TOSPosition(resultX, resultY, resultZ)
    }
    
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.x = Float(x)
        self.y = Float(y)
        self.z = Float(z)
    }
    
    init(_ pos: TOSPosition) {
        self.x = Float(pos.x)
        self.y = Float(pos.y)
        self.z = Float(pos.z)
    }
    
    func toString() -> String {
        return String(format: "x: %3.2f :: y: %3.2f :: z: %3.2f", x, y, z)
    }
    
    func distance(toPosition: TOSPosition) -> Float {
        return sqrtf(powf(self.x - toPosition.x, 2.0) + powf(self.y - toPosition.y, 2.0) + powf(self.z - toPosition.z, 2.0))
    }
    
    static func +(left : TOSPosition, right: TOSPosition) -> TOSPosition {
        let sx = left.x + right.x
        let sy = left.y + right.y
        let sz = left.z + right.z
        return TOSPosition(sx, sy, sz)
    }
    
    static func -(left : TOSPosition, right: TOSPosition) -> TOSPosition {
        let sx = left.x - right.x
        let sy = left.y - right.y
        let sz = left.z - right.z
        return TOSPosition(sx, sy, sz)
    }
    
    static func +=(left : inout TOSPosition, right: TOSPosition) {
        left.x += right.x
        left.y += right.y
        left.z += right.z
    }
    
    static func / (left: TOSPosition, right : Double) -> TOSPosition {
        let sx = left.x / Float(right)
        let sy = left.y / Float(right)
        let sz = left.z / Float(right)
        return TOSPosition(sx, sy, sz)
    }
    
    static func / (left: TOSPosition, right : Float) -> TOSPosition {
        let sx = left.x / Float(right)
        let sy = left.y / Float(right)
        let sz = left.z / Float(right)
        return TOSPosition(sx, sy, sz)
    }
    
    static func / (left: TOSPosition, right : Int) -> TOSPosition {
        let sx = left.x / Float(right)
        let sy = left.y / Float(right)
        let sz = left.z / Float(right)
        return TOSPosition(sx, sy, sz)
    }
    
    static func * (left: TOSPosition, right : Double) -> TOSPosition {
        let sx = left.x * Float(right)
        let sy = left.y * Float(right)
        let sz = left.z * Float(right)
        return TOSPosition(sx, sy, sz)
    }
    
    static func * (left: TOSPosition, right : Float) -> TOSPosition {
        let sx = left.x * Float(right)
        let sy = left.y * Float(right)
        let sz = left.z * Float(right)
        return TOSPosition(sx, sy, sz)
    }
    
    static func * (left: TOSPosition, right : Int) -> TOSPosition {
        let sx = left.x * Float(right)
        let sy = left.y * Float(right)
        let sz = left.z * Float(right)
        return TOSPosition(sx, sy, sz)
    }
    
    func norm() -> Double {
        return Double(x*x + y*y + z*z).squareRoot()
    }
    
    mutating func normalize() {
        self = self / self.norm()
    }
}
