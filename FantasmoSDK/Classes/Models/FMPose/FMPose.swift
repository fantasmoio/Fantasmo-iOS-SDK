//
//  FMPoseNew.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 26.04.2021.
//

import Foundation
import simd

public struct FMPose: Codable {
    public var position: FMPosition
    public var orientation: FMOrientation
    
    init(position: FMPosition, orientation: FMOrientation) {
        self.position = position;
        self.orientation = orientation
    }
    
    init(_ transform: simd_float4x4) {
        position = FMPosition(transform);
        orientation = FMOrientation(transform)
    }
    
    /// - WARNING: implementation is totally wrong. Translation of two successive "poses" is not equal to the sum of their position. So current
    ///         implementation of operators on FMPose are senseless and calculation of interpolated poses is incorrect.
    // TODO: add comment and rename method to make its intent more clear.
    static public func interpolatePoses(startingPose: FMPose, endingPose: FMPose, allPoses: [FMPose]) -> [FMPose] {
        if (allPoses.count <= 1) {
            return [endingPose]
        }
        
        // Get the starting difference
        let S = startingPose - allPoses.first!
        let E = endingPose - allPoses.last!
        let D = E - S
        
        var cumulativeSum: Float = 0.0
        var distances = [Float]()
        distances.append(0.0)
        
        for poseIndex in 1..<(allPoses.count) {
            let currentPose = allPoses[poseIndex-1]
            let thisDistance = currentPose.position.distance(to: allPoses[poseIndex].position)
            cumulativeSum += thisDistance
            distances.append(cumulativeSum)
        }
        
        if cumulativeSum == 0 {
            cumulativeSum = 1
        }
        
        var interpolatedPoses = [FMPose]()
        for poseIndex in 0..<(allPoses.count) {
            let relativeDistance = distances[poseIndex] / cumulativeSum
            // Note: pay attention that for `FMPose` operators "+" and "*" has very specific meaning.
            let newPose = allPoses[poseIndex] + S + relativeDistance * D
            interpolatedPoses.append(newPose)
        }
        
        return interpolatedPoses
    }
}

    
// MARK: - Operators:

// All operators are intended for simplifying calculation of interpolated points.
extension FMPose {
    
    /// The meaning of the residual (difference): position and orientation equal to difference of positions and difference of orientations respectively.
    /// - Note: difference of orientations has specific meaning. See comment to `FMOrientation.-()` operator for more details.
    /// - WARNING: Do not use this operator for calculating "relative pose". Relative pose has other meaning. See comment to
    /// `FMPose.calculateRelativePose(of:)` for more details.
    static func -(left : FMPose, right: FMPose) -> FMPose {
        return FMPose(position: left.position - right.position, orientation: left.orientation - right.orientation)
    }
    
    /// The meaning of the sum: position and orientation equal to sum of positions and sum of orientations respectively.
    /// - Note: sum of orientations has specific meaning. See comment to `FMOrientation.+()` operator for more details.
    static func +(left : FMPose, right: FMPose) -> FMPose {
        return FMPose(position: left.position + right.position, orientation: left.orientation + right.orientation)
    }
    
    /// The meaning of  product by scalar: position and orientation equal to product of position by scalar and product of orientation by scalar respectively.
    static func *(left : Float, right: FMPose) -> FMPose {
        return FMPose(position: left * right.position, orientation: left * right.orientation)
    }
    
}
