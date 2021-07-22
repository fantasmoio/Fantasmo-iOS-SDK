//
//  RotationAngleCalculator.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 20.07.2021.
//

import ARKit

/// Calculates rotation angle in radians falling in the range [-∞, +∞] based on the sequence of orientation angles in the range [0, 2pi].
/// It is assumed that previous orientation angle is not far from the new one, which allows to track absolute rotation as an angle in [-∞, +∞].
struct RotationAngleCalculator {
    
    /// Rotation angle in the range [-∞, +∞]
    private(set) var rotationAngle: Float?
    
    /// Previous orientation angle with `trackingQuality = .normal`
    private var previousNormalOrientationAngle: Float?
    
    private var previousLimitedOrientationAngles = [Float]()
    
    mutating func update(with nextAngle: Float, trackingState: ARCamera.TrackingState) {
        if case .normal = trackingState {
            if previousNormalOrientationAngle == nil {
                previousNormalOrientationAngle = nextAngle
                rotationAngle = nextAngle
            }
            
            let diff = nextAngle - previousNormalOrientationAngle!
            let normalizedDiff = Float( Angle(radians: Double(diff)).normalizeBetweenMinusPiAndPi )
            
            if !previousLimitedOrientationAngles.isEmpty {
                let correctedDiff = calculateDiffBasedOnPreviousLimitedAngles(for: nextAngle)
                rotationAngle! += correctedDiff
                previousLimitedOrientationAngles.removeAll()
            }
            else {
                rotationAngle! += normalizedDiff
            }
            
            previousNormalOrientationAngle = nextAngle
            
        }
        else if case .limited = trackingState {
            previousLimitedOrientationAngles.append(nextAngle)
        }
        else if case .notAvailable = trackingState {
            // nothing
        }
    }
    
    private func calculateDiffBasedOnPreviousLimitedAngles(for nextNormalAngle: Float) -> Float {
        let diff = nextNormalAngle - previousNormalOrientationAngle!
        let probabilityOfPositiveDiff = probabilityOfPossitiveDiffDeducedFromPreviousLimitedAngles(for: nextNormalAngle)
        
        if probabilityOfPositiveDiff >= 0.5 {
            if diff < 0 {
                return diff + 2 * .pi // returns diff in [0, 2pi]
            }
            else {
                return diff
            }
        }
        else {
            if diff > 0 {
                return diff - 2 * .pi // returns diff in [-2pi, 0]
            }
            else {
                return diff
            }
        }
    }
    
    private func probabilityOfPossitiveDiffDeducedFromPreviousLimitedAngles(for nextOrientationAngle: Float) -> Float {
        var positiveCasesCount = 0
        previousLimitedOrientationAngles.forEach { limitedAngle in
            let diff = Double(nextOrientationAngle - limitedAngle)
            let normalizedDiff = Angle(radians: diff).normalizeBetweenMinusPiAndPi
            
            if normalizedDiff >= 0 {
                positiveCasesCount += 1
            }
            else {
                positiveCasesCount -= 1
            }
        }
        
        return Float(positiveCasesCount) / Float(previousLimitedOrientationAngles.count)
    }
}


