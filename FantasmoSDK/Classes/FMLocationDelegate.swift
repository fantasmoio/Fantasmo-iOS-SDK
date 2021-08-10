//
//  FMLocationDelegate.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/3/21.
//

import Foundation
import CoreLocation

public enum FMResultConfidence: Comparable {
    case low
    case medium
    case high

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

/// The methods that you use to receive events from an associated
/// location manager object.
public protocol FMLocationDelegate: AnyObject {

    /// Tells the delegate that new location data is available.
    ///
    /// - Parameters:
    ///   - location: Location of the device (or anchor if set)
    ///   - zones: Semantic zone corresponding to the location
    /// Default implementation provided.
    func locationManager(didUpdateLocation result: FMLocationResult)

    /// Tells the delegate that an error has occurred.
    ///
    /// - Parameters:
    ///   - error: The error reported.
    ///   - metadata: Metadata related to the error.
    /// Default implementation provided.
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?)

    /// Notifies delegate of the needed user action to enable localization.
    /// For example user may holds the device tilted too much, which makes localization impossible. In this case manager will request corresponding
    /// remedial action (tilt up or down)
    /// Default implementation provided.
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest)
}

/// Empty implementations of the protocol to allow optional
/// implementation for delegates.
public extension FMLocationDelegate {
    func locationManager(didUpdateLocation result: FMLocationResult) {}
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {}
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest) {}
}
