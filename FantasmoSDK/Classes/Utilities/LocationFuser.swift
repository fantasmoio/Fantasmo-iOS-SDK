//
//  LocationFuser.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/3/21.
//

import Foundation
import CoreLocation

struct LocationFuser {

    struct InterimResult {
        var location: CLLocation
        var zones: [FMZone]?
    }

    // TODO maybe just use [CLLocation] here, depending on how we intend to deal with zones
    var results: [InterimResult] = []

    mutating func reset() {
        results = []
    }

    private func geometricMedian(_ results: [InterimResult]) -> CLLocation {
        for _ in results {
            // FIXME calculate median
        }
        return CLLocation()
    }

    private func medianOfAbsoluteDistances(_ results: [InterimResult], _ median: CLLocation) -> Double {
        var distances: [Double] = []

        for result in results {
            let distance = abs(result.location.distance(from: median))
            distances.append(distance)
        }

        if let median = distances.median() {
            return median
        } else {
            return Double.nan
        }
    }

    private func classifyInliers(_ results: [InterimResult]) -> [InterimResult] {
        let median = geometricMedian(results)
        let mad = medianOfAbsoluteDistances(results, median)

        var inliers: [InterimResult] = []
        for result in results {
            let distance = abs(result.location.distance(from: median))
            if 0.6745 * distance / mad <= 3.5 {
                inliers.append(result)
            }
        }
        return inliers
    }

    private func calculateConfidence(_ results: [InterimResult]) -> FMResultConfidence {
        switch results.count {
        case 1, 2:
            return .low
        case 3, 4:
            return .medium
        default:
            return .high
        }
    }

    mutating func fusedResult(location: CLLocation, zones: [FMZone]?) -> FMLocationResult {
        results.append(InterimResult(location: location, zones: zones))

        let inliers = classifyInliers(results)
        let median = geometricMedian(inliers)
        let confidence = calculateConfidence(results)

        return FMLocationResult(location: median, confidence: confidence, zones: zones)
    }
}
