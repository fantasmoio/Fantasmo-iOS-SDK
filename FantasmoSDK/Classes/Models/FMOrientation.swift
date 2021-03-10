//
//  FMOrientation.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import ARKit

// Orientation of the device at moment of image capture.
public struct FMOrientation:Codable {
    
    var x:Float
    var y:Float
    var z:Float
    var w:Float
    
    // Extracts the orientation from an ARKit camera transform matrix and converts
    // from ARKit coordinates (right-handed, Y Up) to OpenCV coordinates (right-handed, Y Down)
    init(fromTransform transform:simd_float4x4) {
        var rotationMatrix = simd_float3x3(simd_make_float3(transform.columns.1),
                                           simd_make_float3(transform.columns.0),
                                           simd_make_float3(-transform.columns.2))
        
        rotationMatrix = rotationMatrix.transpose
        rotationMatrix.columns.1 = -rotationMatrix.columns.1
        rotationMatrix.columns.2 = -rotationMatrix.columns.2
        rotationMatrix = rotationMatrix.transpose
        
        let rotation = simd_quaternion(rotationMatrix)
        x = rotation.imag.x
        y = rotation.imag.y
        z = rotation.imag.z
        w = rotation.real
    }
    
    init(fromEuler x: Double, y: Double, z: Double) {
        let xaxis = simd_double3(x: 1, y: 0, z: 0)
        let yaxis = simd_double3(x: 0, y: 1, z: 0)
        let zaxis = simd_double3(x: 0, y: 0, z: 1)
        
        let qx = simd_quatd(angle: x, axis: xaxis)
        let qy = simd_quatd(angle: y, axis: yaxis)
        let qz = simd_quatd(angle: z, axis: zaxis)
        
        self.x = 0
        self.y = 0
        self.z = 0
        self.w = 1
        
        self = hamiltonProduct( quaternionRotation: qx)
        self = hamiltonProduct( quaternionRotation: qy)
        self = hamiltonProduct( quaternionRotation: qz)
    }
    
    // Initializes the orientation with a (OpenCV coordinate system) quaternion
    init(fromQuaternion w:Float, x:Float, y:Float, z:Float) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    init(_ rotation: simd_quatd) {
        self.x = Float(rotation.imag.x)
        self.y = Float(rotation.imag.y)
        self.z = Float(rotation.imag.z)
        self.w = Float(rotation.real)
    }
    
    init(_ rotation: simd_quatf) {
        self.x = Float(rotation.imag.x)
        self.y = Float(rotation.imag.y)
        self.z = Float(rotation.imag.z)
        self.w = Float(rotation.real)
    }
    
    init(_ or: FMOrientation) {
        self.x = Float(or.x)
        self.y = Float(or.y)
        self.z = Float(or.z)
        self.w = Float(or.w)
    }
    
    public func toSimdQuaternion() -> simd_quatf {
        return simd_quatf(ix: self.x, iy: self.y, iz: self.z, r: self.w)
    }
    
    public func getRotationTo(orientation:FMOrientation) -> simd_quatf {
        return (self.toSimdQuaternion().inverse)*orientation.toSimdQuaternion()
    }
    
    public func difference(to orientation:FMOrientation) -> FMOrientation {
        let thisDifference = (self.toSimdQuaternion()*(orientation.toSimdQuaternion().inverse)).normalized
        return FMOrientation(fromQuaternion: thisDifference.real, x: thisDifference.imag[0], y: thisDifference.imag[1], z: thisDifference.imag[2])
    }
    
    // Rotate myself by quaternionRotation
    public func hamiltonProduct(quaternionRotation: simd_quatf) -> FMOrientation {
        let a1 = quaternionRotation.real
        let b1 = quaternionRotation.imag[0]
        let c1 = quaternionRotation.imag[1]
        let d1 = quaternionRotation.imag[2]
        
        let a2 = self.w
        let b2 = self.x
        let c2 = self.y
        let d2 = self.z
        
        let hamiltonW = a1*a2 - b1*b2 - c1*c2 - d1*d2
        let hamiltonX = a1*b2 + b1*a2 + c1*d2 - d1*c2
        let hamiltonY = a1*c2 - b1*d2 + c1*a2 + d1*b2
        let hamiltonZ = a1*d2 + b1*c2 - c1*b2 + d1*a2
        
        return FMOrientation(fromQuaternion: hamiltonW, x: hamiltonX, y: hamiltonY, z: hamiltonZ)
    }
    
    public func hamiltonProduct(quaternionRotation: simd_quatd) -> FMOrientation {
        let a1 = Float(quaternionRotation.real)
        let b1 = Float(quaternionRotation.imag[0])
        let c1 = Float(quaternionRotation.imag[1])
        let d1 = Float(quaternionRotation.imag[2])
        
        let a2 = self.w
        let b2 = self.x
        let c2 = self.y
        let d2 = self.z
        
        let hamiltonW = a1*a2 - b1*b2 - c1*c2 - d1*d2
        let hamiltonX = a1*b2 + b1*a2 + c1*d2 - d1*c2
        let hamiltonY = a1*c2 - b1*d2 + c1*a2 + d1*b2
        let hamiltonZ = a1*d2 + b1*c2 - c1*b2 + d1*a2
        
        return FMOrientation(fromQuaternion: hamiltonW, x: hamiltonX, y: hamiltonY, z: hamiltonZ)
    }
    
    public func hamiltonProduct(_ quaternionRotation: FMOrientation) -> FMOrientation {
        let a1 = quaternionRotation.w
        let b1 = quaternionRotation.x
        let c1 = quaternionRotation.y
        let d1 = quaternionRotation.z
        
        let a2 = self.w
        let b2 = self.x
        let c2 = self.y
        let d2 = self.z
        
        let hamiltonW = a1*a2 - b1*b2 - c1*c2 - d1*d2
        let hamiltonX = a1*b2 + b1*a2 + c1*d2 - d1*c2
        let hamiltonY = a1*c2 - b1*d2 + c1*a2 + d1*b2
        let hamiltonZ = a1*d2 + b1*c2 - c1*b2 + d1*a2
        
        return FMOrientation(fromQuaternion: hamiltonW, x: hamiltonX, y: hamiltonY, z: hamiltonZ)
    }
    
    func interpolated(distance: Float, startOrientation: FMOrientation, differenceOrientation: FMOrientation) -> FMOrientation {
        let differenceQuaternion = differenceOrientation.toSimdQuaternion()
        
        let ang = distance*differenceQuaternion.angle
        var iq : simd_quatf
        if abs(ang) > 0.000001 {
            let ax = differenceQuaternion.axis
            iq = simd_quatf(angle: ang, axis: ax)
        } else {
            iq = simd_quatf(ix: 0.0, iy: 0.0, iz: 0.0, r: 1.0)
        }
        
        let resultOrientation = iq*startOrientation.toSimdQuaternion()*self.toSimdQuaternion()
        
        return FMOrientation(fromQuaternion: resultOrientation.real, x: resultOrientation.imag[0], y: resultOrientation.imag[1], z: resultOrientation.imag[2])
    }
    
    func toString() -> String {
        return String(format: "x: %2.3f :: y: %2.3f :: z: %2.3f :: w: %2.3f", x, y, z, w)
    }
    
    func ToQuaternion() -> simd_quatd {
        return simd_quatd(ix: Double(x), iy: Double(y), iz: Double(z), r: Double(w))
    }
    
    func rotate(_ rot : FMOrientation) -> FMOrientation {
        return hamiltonProduct(rot)
    }
    
    func rotate(_ pos : FMPosition) -> FMPosition {
        let q = self.ToQuaternion()
        let p = simd_double3(x: Double(pos.x), y: Double(pos.y), z: Double(pos.z))
        let pRot = q.act(p)
        return FMPosition(Float(pRot.x), Float(pRot.y), Float(pRot.z))
    }
    
    func inverse() -> FMOrientation {
        let q = ToQuaternion()
        return FMOrientation(q.inverse)
    }
    
    func angularDistance(_ other : FMOrientation) -> Double {
        let qd = getRotationTo(orientation: other)
        return Double(qd.angle) * .pi / 180.0
    }
    
    mutating func flipSign() {
        self.w = -self.w
        self.x = -self.x
        self.y = -self.y
        self.z = -self.z
    }
    
    mutating func normalize() {
        let lengthD: Float = 1.0 / (w*w + x*x + y*y + z*z);
        w *= lengthD;
        x *= lengthD;
        y *= lengthD;
        z *= lengthD;
    }
    
    func quaternionDot(other: FMOrientation) -> Float {
        return (w * other.w + x * other.x + y * other.y + z * other.z)
    }
    
    static func getAverageQuaternion(quaternions: [FMOrientation]) -> FMOrientation? {
        
        if(quaternions.count == 0) {
            return nil
        } else {
            var firstQuaternion = quaternions[0]
            
            var numberOfQuaternionsSummedUp: Float = 1.0
            for i in 1 ..< quaternions.count {
                var quaternion = quaternions[i]
                if (quaternion.quaternionDot(other: firstQuaternion) < 0) {
                    quaternion.flipSign()
                }
                
                if(firstQuaternion.angularDistance(quaternion) < 10) {
                    debugPrint("Valid quaternion for averaging")
                    numberOfQuaternionsSummedUp += 1.0
                    firstQuaternion.w += quaternion.w
                    firstQuaternion.x += quaternion.x
                    firstQuaternion.y += quaternion.y
                    firstQuaternion.z += quaternion.z
                } else {
                    debugPrint("Invalid quaternion for averaging")
                }
            }
            
            firstQuaternion.w /= numberOfQuaternionsSummedUp
            firstQuaternion.x /= numberOfQuaternionsSummedUp
            firstQuaternion.y /= numberOfQuaternionsSummedUp
            firstQuaternion.z /= numberOfQuaternionsSummedUp
            
            firstQuaternion.normalize()
            return firstQuaternion
        }
    }
}
