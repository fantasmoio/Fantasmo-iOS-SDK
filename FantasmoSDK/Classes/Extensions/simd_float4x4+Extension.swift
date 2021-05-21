//
//  simd_float4x4+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.04.2021.
//

import simd

extension simd_float4x4: CustomStringConvertible {
    
    /// OpenCV coordinate system is turned by 180˚ about X-axis relative to the original coordinate system.
    static let transformOfOpenCVCoordinateSystem = simd_float4x4( simd_quatf(angle: .pi, axis: SIMD3(x: 1, y: 0, z: 0)) )
    
    init(pose: FMPose) {
        self.init( simd_quatf(pose.orientation) )
        self.columns.3.x = pose.position.x
        self.columns.3.y = pose.position.y
        self.columns.3.z = pose.position.z
    }
    
    /// Calculates relative transform of the passed `transform` relative to `self` and in the coordinate system of `self`.
    /// Coordinate system of self is obtained by applying transform to the current coordinate system.
    /// Having such relative transform the absolute transform of `transform` can be found on formula:
    ///     `transform_inWorldCS = self_inWorldCS * transform_relativeToSelfInCsOfSelf`
    ///
    /// We could also come at calculating `transform_relativeToSelfInCsOfSelf` having calculated
    /// `transform_relativeToSelfInWorldCS` and then changing coordinate system from "world" to "self":
    ///
    ///     transform_inWorldCS = transformMatrix * transform_relativeToSelfInWorldCS * transformMatrix^(-1)
    ///
    ///     where
    ///         transformMatrix = self^(-1)  - is transform matrix from world CS to CS of self.
    ///         transform_relativeToSelfInWorldCS = transform * self^(-1)  - we just make transform back to the
    ///             axes of the world CS and then transform to coordinate system of `transform`.
    /// Final result after substitution:
    ///
    ///     transform_inWorldCS = self_inWorldCS^(-1) * transform
    ///
    public func calculateRelativeTransformInTheCsOfSelf(of transform: simd_float4x4) -> simd_float4x4 {
        self.inverse * transform
    }
    
    public var translation: simd_float3 {
        simd_make_float3(columns.3)
    }
    
    /// Transform in OpenCV coordinate system.
    /// Returns the transform which is obtained after transform from the current coordinate system to OpenCV coordinate system.
    /// OpenCV coordinate system is turned about X-axis of regular coordinate system by 180°.
    @inline(__always) var inOpenCvCS: simd_float4x4 {
        simd_float4x4.transformOfOpenCVCoordinateSystem * self
    }
    
    /// Transform in non-OpenCV coordinate system implying that `self` is given in OpenCV coordinate system.
    /// Returns the transform which is obtained after transform from the current OpenCV coordinate system to non-OpenCV coordinate system.
    /// OpenCV coordinate system is turned about X-axis of regular coordinate system by 180°.
    @inline(__always) var inNonOpenCvCS: simd_float4x4 {
        simd_float4x4.transformOfOpenCVCoordinateSystem * self
    }

    public var description: String {
        var str = ""
        for i in (0...3) {
            str += "\t"
            for j in (0...3) {
                str += String(format: "%10.3f", self[j][i])
            }
            str += "\n"
        }
        return str
    }
}
