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
    
    /// Angles that were received starting from the previous angle with `trackingState = .normal`.
    /// Used for estimating which way angle was changed from the previous "normal" angle to the next "normal" angle.
    /// For additional details see comment to `calculateDiffBasedOnPreviousLimitedAngles(for:)`
    private var previousLimitedOrientationAngles = [Float]()
    
    mutating func update(with nextAngle: Float, trackingState: ARCamera.TrackingState) {
        if case .normal = trackingState {
            if previousNormalOrientationAngle == nil {
                previousNormalOrientationAngle = nextAngle
                rotationAngle = nextAngle
            }
            
            let diff = nextAngle - previousNormalOrientationAngle!
            let normalizedDiff = Float( Angle(radians: Double(diff)).normalizedBetweenMinusPiAndPi )
            
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
    
    /// Change in 'orientation' angle from one value to another can be achied in many ways differing between each other by 2pi. We assume that
    /// change (diff) always falls into the interval (-pi, pi] and always convert the diff value to this interval, which allows us to understand in which direction
    /// there was rotation and properly calculate 'rotation' angle. But in case when between some two "normal" orientation angles (that is angles received
    /// from frames with `.normal` tracking state) there is some number of  "limited" orientation angles, it is possible that change between "normal"
    /// angles was performed along longer arc. We try to estimate probability  of this by calculating relative number of "limited" angles in adjacent
    /// semicircles. Semicircles are assumed to have boundary in the current "normal" orientation angle.
    private func calculateDiffBasedOnPreviousLimitedAngles(for nextNormalAngle: Float) -> Float {
        let diff = nextNormalAngle - previousNormalOrientationAngle!
        let probabilityOfPositiveDiff = estimateProbabilityOfPositiveAngleChangeForRecentPoorTracking(
            for: nextNormalAngle
        )
        
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
    
    /// This func calculates the percentage of the "limited" angles that were received in the time gap between two "normal" angles in the semicircle
    /// corresponding to the positive diff.
    /// For more details see comment to the `calculateDiffBasedOnPreviousLimitedAngles(for:)`
    private func estimateProbabilityOfPositiveAngleChangeForRecentPoorTracking(
        for nextOrientationAngle: Float
    ) -> Float {
        var positiveCasesCount = 0
        
        previousLimitedOrientationAngles.forEach { limitedAngle in
            let diff = Double(nextOrientationAngle - limitedAngle)
            let normalizedDiff = Angle(radians: diff).normalizedBetweenMinusPiAndPi
            
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


