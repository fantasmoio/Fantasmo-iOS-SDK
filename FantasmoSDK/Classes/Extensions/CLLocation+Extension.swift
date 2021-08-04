//
//  CLLocation+Extension.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/4/21.
//

import Foundation
import CoreLocation

extension CLLocation {

    /// Calculate distance treating lat and long as unitless Cartesian coordinates
    func degreeDistance(from: CLLocation) -> Double {
        let dLat = coordinate.latitude - from.coordinate.latitude
        let dLon = coordinate.longitude - from.coordinate.longitude
        return sqrt(dLat * dLat + dLon * dLon)
    }

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

    static func geometricMedian(_ locations: [CLLocation], maxIterations: Int = 200) -> CLLocation {
        guard locations.count > 0 else {
            log.error("Empty list. Could not compute median!")
            return CLLocation(latitude: Double.nan, longitude: Double.nan)
        }

        guard locations.count != 1 else {
            return locations.first!
        }

        // initialize guess to the centroid
        var median = geometricMean(locations).coordinate

        // if the initial guess is one of the points, the math breaks, so move it
        while !locations.filter({
            $0.coordinate.longitude == median.longitude &&
            $0.coordinate.latitude == median.latitude
        }).isEmpty {
            median.latitude += 0.1
        }

        var converged = false
        var distances: [Double] = []
        var iteration = 0
        while !converged && iteration < maxIterations {
            var x = 0.0
            var y = 0.0
            var denum = 0.0
            var d = 0.0
            let medianLocation = CLLocation(latitude: median.latitude, longitude: median.longitude)
            for location in locations {
                let distance = location.degreeDistance(from: medianLocation)
                x += location.coordinate.latitude / distance
                y += location.coordinate.longitude / distance
                denum += 1.0 / distance
                d += distance * distance
            }
            distances.append(d)

            if denum == 0 {
                log.error("Could not compute median!")
                return CLLocation()
            }

            // update our guess for the median
            median.latitude = x / denum
            median.longitude = y / denum

            // test convergence
            if iteration > 3 {
                converged = abs(distances[iteration] - distances[iteration-2]) < 0.1
            }

            iteration += 1
        }

        if iteration == maxIterations {
            log.error("Median did not converge after \(maxIterations) iterations!")
        }

        return CLLocation(latitude: median.latitude, longitude: median.longitude)
    }

    static func medianOfAbsoluteDistances(_ locations: [CLLocation], _ median: CLLocation) -> Double {
        var distances: [Double] = []

        for location in locations {
            let distance = abs(location.degreeDistance(from: median))
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
            let distance = abs(location.degreeDistance(from: median))
            if 0.6745 * distance / mad <= 3.5 {
                inliers.append(location)
            }
        }
        return inliers
    }
}