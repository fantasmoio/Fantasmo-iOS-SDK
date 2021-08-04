//
//  LocationFuser.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/3/21.
//

import Foundation
import CoreLocation

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

    mutating func fusedResult(location: CLLocation, zones: [FMZone]?) -> FMLocationResult {
        locations.append(location)

        let inliers = CLLocation.classifyInliers(locations)
        let median = CLLocation.geometricMedian(inliers)
        let confidence = calculateConfidence(locations)

        return FMLocationResult(location: median, confidence: confidence, zones: zones)
    }
}
