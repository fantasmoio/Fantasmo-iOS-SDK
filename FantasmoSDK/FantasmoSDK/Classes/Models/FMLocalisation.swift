//
//  FMCoordinates.swift
//  FantasmoSDK
//
//

import Foundation
import CoreLocation

// MARK: - LocalizeResponse
class LocalizeResponse: Codable {
    let geofences: [Geofence]?
    let location: Location?
    let pose: Pose?
    let uuid: String?
}

// MARK: - ErrorResponse
class ErrorResponse: Codable {
    let code: Int
    let message: String?
}

// MARK: - Geofence
class Geofence: Codable {
    let elementID: Int
    let elementType: String
}

// MARK: - Location
class Location: Codable {
    let coordinate: Coordinate?
}

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

// MARK: - Pose
class Pose: Codable {
//    let confidence: String
    let orientation, position: Aspect
}

// MARK: - Aspect
class Aspect: Codable {
    let w: Double?
    let x, y, z: Double
}
