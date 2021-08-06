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

    private func calculateConfidence(_ locations: [CLLocation]) -> FMResultConfidence {
        switch locations.count {
        case 1, 2:
            return .low
        case 3, 4:
            return .medium
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
        let confidence = calculateConfidence(locations)

        return FMLocationResult(location: median, confidence: confidence, zones: zones)
    }
}
