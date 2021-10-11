//
//  FMLocationDelegate.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/3/21.
//

import Foundation
import CoreLocation

public enum FMResultConfidence: Comparable, CustomStringConvertible {
    case low
    case medium
    case high
    
    public var description: String {
        switch self {
        case .low:
            return "Low"
        case .medium:
            return "Medium"
        case .high:
            return "High"
        }
    }
    
    public func abbreviation() -> String {
        switch self {
        case .low:
            return "L"
        case .medium:
            return "M"
        case .high:
            return "H"
        }
    }
}

public struct FMLocationResult {
    public var location: CLLocation
    public var confidence: FMResultConfidence
    public var zones: [FMZone]?
}

public enum FMBehaviorRequest {
    case pointAtBuildings
    case tiltUp
    case tiltDown
    case panAround
    case panSlowly
}

extension FMBehaviorRequest: CustomStringConvertible {
    public var description: String {
        switch self {
        case .pointAtBuildings:
            return "Point at stores, signs and buildings around you to get a precise location"
        case .tiltUp:
            return "Tilt your device up"
        case .tiltDown:
            return "Tilt your device down"
        case .panAround:
            return "Pan around the scene"
        case .panSlowly:
            return "Pan more slowly"
        }
    }
}
