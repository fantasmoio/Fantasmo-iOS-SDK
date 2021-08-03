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

    var results: [InterimResult] = []

    mutating func reset() {
        results = []
    }

    func fusedResult(location: CLLocation, zones: [FMZone]?) -> FMLocationResult {
        // TODO some actual fusion
        return FMLocationResult(location: location, confidence: .high, zones: zones)
    }
}
