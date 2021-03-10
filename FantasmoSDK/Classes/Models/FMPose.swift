//
//  FMPose.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import ARKit

// Device pose at the moment of image capture. The coordinate frame is
// right-handed, Y down (i.e., OpenCV convention). Y is gravity aligned. Rotation
// around Y axis is relative to true north.
public struct FMPose:Codable {
    
    var source = "device"
    var position:FMPosition
    var orientation:FMOrientation
    var confidence = ""
    
    // Extracts the position and orientation from an ARKit camera transform matrix and converts
    // from ARKit coordinates (right-handed, Y Up) to OpenCV coordinates (right-handed, Y Down)
    public init(fromTransform transform:simd_float4x4) {
        position = FMPosition(fromTransform: transform)
        orientation = FMOrientation(fromTransform: transform)
    }
    
    init(position: FMPosition, orientation: FMOrientation, confidence: String = "") {
        self.position = position
        self.orientation = orientation
        self.confidence = confidence
    }

    init() {
        self.position = FMPosition(0.0, 0.0, 0.0)
        self.orientation = FMOrientation(fromEuler: 0, y: 0, z: 0)
    }

    init(_ pose: FMPose) {
        self.position = FMPosition(pose.position)
        self.orientation = FMOrientation(pose.orientation)
    }
    
    public func toString() -> String {
        return "Position [\(position.toString())]   Orientation [\(orientation.toString())]   Confidence [\(confidence)]"
    }
    
    private func interpolated(distance: Float, startPose: FMPose, differencePose: FMPose) -> FMPose {
        let resultPosition = self.position.interpolated(distance: distance, startPosition: startPose.position, differencePosition: differencePose.position)
        let resultOrientation = self.orientation.interpolated(distance: distance, startOrientation: startPose.orientation, differenceOrientation: differencePose.orientation)
        
        return FMPose(position: resultPosition, orientation: resultOrientation)
    }
    
    // TODO is this even correct? see implementation below
    func diffPose(toPose: FMPose) -> FMPose {
        let diffPosition = self.position - toPose.position
        let diffOrientation = self.orientation.difference(to: toPose.orientation)
        return FMPose(position: diffPosition, orientation: diffOrientation)
    }
    
    static func diffPose(_ anchorTransform: simd_float4x4, withRespectTo cameraTransfrom: simd_float4x4) -> FMPose {
        // TODO rename and make generic
        // TODO DRY
        // TODO get rid of fromTransform constructor shenanigans
        let anchorPose = FMPose(fromTransform: anchorTransform)
        let cameraPose = FMPose(fromTransform: cameraTransfrom)
        
        var anchorTransformMatrix = simd_float4x4(anchorPose.orientation.toSimdQuaternion().normalized)
        var cameraTransformMatrix = simd_float4x4(cameraPose.orientation.toSimdQuaternion().normalized)
        
        anchorTransformMatrix.columns.3.x = anchorPose.position.x
        anchorTransformMatrix.columns.3.y = anchorPose.position.y
        anchorTransformMatrix.columns.3.z = anchorPose.position.z
        
        cameraTransformMatrix.columns.3.x = cameraPose.position.x
        cameraTransformMatrix.columns.3.y = cameraPose.position.y
        cameraTransformMatrix.columns.3.z = cameraPose.position.z
        
        let result = cameraTransformMatrix.inverse * anchorTransformMatrix
        
        // all this to skip the FMPose fromTransform constructor which expects ARKit coordinates
        let resultPoseQuaternion = simd_quatf(result)
        let resultPoseOrientation = FMOrientation(fromQuaternion: resultPoseQuaternion.real, x: resultPoseQuaternion.vector.x, y: resultPoseQuaternion.vector.y, z: resultPoseQuaternion.vector.z)
        let resultPosePosition = FMPosition(result.columns.3.x, result.columns.3.y, result.columns.3.z)
        
        return FMPose(position: resultPosePosition, orientation: resultPoseOrientation)
    }
    
    mutating func applyTransform(pose: FMPose) {
        self.position = self.position - pose.position
        self.orientation = self.orientation.rotate(pose.orientation)
    }
    
    static public func interpolatePoses(startingPose: FMPose, endingPose: FMPose, allPoses: [FMPose]) -> [FMPose] {
        
        if (allPoses.count <= 1) {
            return [endingPose]
        }
        
        // Get the starting difference
        let S = startingPose.diffPose(toPose: allPoses[0])  //Note: This should be 0, because the startingPose is by definition the first pose in the allPoses vector
        let E = endingPose.diffPose(toPose: allPoses.last!)
        let D = E.diffPose(toPose: S)
        
        var cumulativeSum: Float = 0.0
        var distances = [Float]()
        distances.append(0.0)
        
        for poseIndex in 1..<(allPoses.count) {
            let thisDistance = allPoses[poseIndex-1].position.distance(toPosition: allPoses[poseIndex].position)
            cumulativeSum += thisDistance
            distances.append(cumulativeSum)
        }
        
        if cumulativeSum == 0 {
            cumulativeSum = 1
        }
        
        var interpolatedPoses = [FMPose]()
        for poseIndex in 0..<(allPoses.count) {
            let thisDistance = distances[poseIndex]/cumulativeSum
            let newPose = allPoses[poseIndex].interpolated(distance: thisDistance, startPose: S, differencePose: D)
            interpolatedPoses.append(newPose)
        }
        
        return interpolatedPoses
    }
}
