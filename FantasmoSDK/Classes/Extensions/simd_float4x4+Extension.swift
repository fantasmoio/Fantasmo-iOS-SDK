//
//  simd_float4x4+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.04.2021.
//

import simd

extension simd_float4x4 {
    
    /// Calculates relative transform of the passed `transform` relative to `self` and in the coordinate system of `self`.
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
    func calculateRelativeTransformInTheCsOfSelf(of transform: simd_float4x4) -> simd_float4x4 {
        return self.inverse * transform
    }
    
    init(pose: FMPose) {
        self.init( simd_quatf(pose.orientation) )
        self.columns.3.x = pose.position.x
        self.columns.3.y = pose.position.y
        self.columns.3.z = pose.position.z
    }
    
    public var description: String {
        var str = ""
        for i in (0...3) {
            str += "\t"
            for j in (0...3) {
                str += "\(self[j][i]) "
            }
            str += "\n"
        }
        return str
    }
    
}
