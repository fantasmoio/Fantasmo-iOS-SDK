//
//  TOSPose.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import ARKit

public struct TOSPose: Codable {
    
    let source = "device"
    var position:TOSPosition
    var orientation:TOSOrientation
    var confidence = ""
    
    init(fromTransform transform:simd_float4x4) {
        position = TOSPosition(fromTransform: transform)
        orientation = TOSOrientation(fromTransform: transform)
    }
    
    init(position: TOSPosition, orientation: TOSOrientation, confidence: String = "") {
        self.position = position
        self.orientation = orientation
        self.confidence = confidence
    }

    init() {
        self.position = TOSPosition(0.0, 0.0, 0.0)
        self.orientation = TOSOrientation(fromEuler: 0, y: 0, z: 0)
    }

    init(_ pose: TOSPose) {
        self.position = TOSPosition(pose.position)
        self.orientation = TOSOrientation(pose.orientation)
    }
    
    func toString() -> String {
        return "Position [\(position.toString())]   Orientation [\(orientation.toString())]   Confidence [\(confidence)]"
    }
    
    private func interpolated(distance: Float, startPose: TOSPose, differencePose: TOSPose) -> TOSPose {
        let resultPosition = self.position.interpolated(distance: distance, startPosition: startPose.position, differencePosition: differencePose.position)
        let resultOrientation = self.orientation.interpolated(distance: distance, startOrientation: startPose.orientation, differenceOrientation: differencePose.orientation)
        
        return TOSPose(position: resultPosition, orientation: resultOrientation)
    }
    
    func diffPose(toPose: TOSPose) -> TOSPose {
        let diffPosition = self.position - toPose.position
        let diffOrientation = self.orientation.difference(to: toPose.orientation)
        return TOSPose(position: diffPosition, orientation: diffOrientation)
    }
    
    mutating func applyTransform(pose: TOSPose) {
        self.position = self.position - pose.position
        self.orientation = self.orientation.rotate(pose.orientation)
    }
    
    static public func interpolatePoses(startingPose: TOSPose, endingPose: TOSPose, allPoses: [TOSPose]) -> [TOSPose] {
        
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
        
        var interpolatedPoses = [TOSPose]()
        for poseIndex in 0..<(allPoses.count) {
            let thisDistance = distances[poseIndex]/cumulativeSum
            let newPose = allPoses[poseIndex].interpolated(distance: thisDistance, startPose: S, differencePose: D)
            interpolatedPoses.append(newPose)
        }
        
        return interpolatedPoses
    }
}
