//
//  LocationFuser.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/3/21.
//

import Foundation
import CoreLocation

/// Fuses a series of locations using a geometric median calculation that ingores outliers
/// and provides a confidence value, which grows as more locations are provided.
struct LocationFuser {

    var locations: [CLLocation] = []

    mutating func reset() {
        locations = []
    }

    /// Derives a confidence based on the standard deviation of locations
    static func standardDeviationConfidence(_ locations: [CLLocation]) -> FMResultConfidence {
        if locations.count > 1, let variance = CLLocation.populationVariance(locations) {
            let stdDev = sqrt(variance)

            switch stdDev {
            case 0..<0.15:
                // within 15 cm
                return .high
            case 0.15..<0.5:
                // within 50 cm
                return .medium
            default:
                // more than 50 cm
                return .low
            }
        } else {
            return .low
        }
    }

    /// Calculates our confidence based on a series of location measurements.
    /// If the standard deviation of measurements is sufficiently low, confidence is high.
    /// Otherwise, confidence increases with the number of samples.
    static func confidence(_ locations: [CLLocation]) -> FMResultConfidence {
        let standardDeviationConfidence = Self.standardDeviationConfidence(locations)

        switch locations.count {
        case 1, 2:
            return max(standardDeviationConfidence, .low)
        case 3, 4:
            return max(standardDeviationConfidence, .medium)
        default:
            return .high
        }
    }

    /// Returns a new location based on a fusion of previously accumulated locations
    ///
    /// - Parameters:
    ///   - location: New location to be combined with previous observations
    ///   - zones: Zones at this location
    mutating func locationFusedWithNew(location: CLLocation, zones: [FMZone]?) -> FMLocationResult {
        locations.append(location)

        let inliers = CLLocation.classifyInliers(locations)
        let median = CLLocation.geometricMedian(inliers)
        let confidence = Self.confidence(locations)

        return FMLocationResult(location: median, confidence: confidence, zones: zones)
    }
}
