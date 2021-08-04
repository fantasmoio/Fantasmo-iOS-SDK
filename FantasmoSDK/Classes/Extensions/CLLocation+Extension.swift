//
//  CLLocation+Extension.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/4/21.
//

import Foundation
import CoreLocation

extension CLLocation {
    static func geometricMean(_ locations: [CLLocation]) -> CLLocation {
        var x = 0.0
        var y = 0.0
        for location in locations {
            x += location.coordinate.latitude
            y += location.coordinate.longitude
        }
        x /= Double(locations.count)
        y /= Double(locations.count)
        return CLLocation(latitude: x, longitude: y)
    }

    static func geometricMedian(_ locations: [CLLocation]) -> CLLocation {
        for _ in locations {
            // FIXME calculate median
        }
        return CLLocation()
    }

    static func medianOfAbsoluteDistances(_ locations: [CLLocation], _ median: CLLocation) -> Double {
        var distances: [Double] = []

        for location in locations {
            let distance = abs(location.distance(from: median))
            distances.append(distance)
        }

        if let median = distances.median() {
            return median
        } else {
            return Double.nan
        }
    }

    static func classifyInliers(_ locations: [CLLocation]) -> [CLLocation] {
        let median = geometricMedian(locations)
        let mad = medianOfAbsoluteDistances(locations, median)

        var inliers: [CLLocation] = []
        for location in locations {
            let distance = abs(location.distance(from: median))
            if 0.6745 * distance / mad <= 3.5 {
                inliers.append(location)
            }
        }
        return inliers
    }
}
