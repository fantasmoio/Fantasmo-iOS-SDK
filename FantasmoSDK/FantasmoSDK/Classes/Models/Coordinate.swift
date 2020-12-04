//
//  Coordinate.swift
//  FantasmoSDK
//

import Foundation
import CoreLocation

// MARK: - Coordinate
class Coordinate: Codable {
    let latitude, longitude: Double?
    
    func getLocation() -> CLLocation {
        guard let latitude = latitude, let longiutde = longitude else {
            return CLLocation()
        }
        return CLLocation(latitude: latitude, longitude: longiutde)
    }
}
