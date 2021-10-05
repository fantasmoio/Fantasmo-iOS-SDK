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

public enum FMBehaviorRequest: String {
    case tiltUp = "Tilt your device up"
    case tiltDown = "Tilt your device down"
    case panAround = "Pan around the scene"
    case panSlowly = "Pan more slowly"
}
