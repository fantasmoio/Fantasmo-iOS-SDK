//
//  FMLocationManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import CoreLocation

/// The methods that you use to receive events from an associated
/// location manager object.
public protocol FMLocationDelegate : NSObjectProtocol {
    
    /// Tells the delegate that new location data is available.
    ///
    /// - Parameters:
    ///   - location: Location of the device (or anchor if set)
    ///   - zones: Semantic zone corresponding to the location
    func locationManager(didUpdateLocation location: CLLocation,
                         withZones zones: [FMZone]?)
    
    
    /// Tells the delegate that an error has occurred.
    ///
    /// - Parameters:
    ///   - error: The error reported.
    ///   - metadata: Metadata related to the error.
    func locationManager(didFailWithError error: Error,
                         errorMetadata metadata: Any?)
}

/// Empty implementations of the protocol to allow optional
/// implementation for delegates.
extension FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation,
                         withZones zones: [FMZone]?) {}
    
    func locationManager(didFailWithError error: Error,
                         errorMetadata metadata: Any?) {}
}


/// Start and stop the delivery of camera-based location events.
open class FMLocationManager: FMApiDelegate {
    
    public enum State {
        case stopped        // doing nothing
        case localizing     // localizing
        case uploading      // uploading image while localizing
    }
    
    
    // MARK: - Properties
    
    public static let shared = FMLocationManager()
    public private(set) var state = State.stopped
    
    internal var anchorFrame: ARFrame?

    private var delegate: FMLocationDelegate?
    internal var token: String?
    
    /// When in simulation mode, mock data is used from the assets directory instead of the live camera feed.
    /// This mode is useful for implementation and debugging.
    public var isSimulation = false
    /// The zone that will be simulated.
    public var simulationZone = FMZone.ZoneType.parking
    public var isConnected = false

    // MARK: - Lifecycle
    
    private init() {}
    
    /// Connect to the location service.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    public func connect(accessToken: String,
                        delegate: FMLocationDelegate) {
        
        debugPrint("FMLocationManager connected with delegate: \(delegate)")
        
        self.token = accessToken
        self.delegate = delegate
        
        FMApi.shared.delegate = self
    }
    
    
    // MARK: - Public instance methods
    
    /// Starts the generation of updates that report the user’s current location.
    public func startUpdatingLocation() {
        debugPrint("FMLocationManager:startUpdatingLocation")
        self.isConnected = true
        self.state = .localizing
    }
    
    /// Stops the generation of location updates.
    public func stopUpdatingLocation() {
        debugPrint("FMLocationManager:stopUpdatingLocation")
        self.state = .stopped
    }
    
    /// Set an anchor point. All location updates will now report the
    /// location of the anchor instead of the camera.
    public func setAnchor() {
        debugPrint("FMLocationManager:setAnchor")
        self.anchorFrame = ARSession.lastFrame
    }
    
    /// Unset the anchor point. All location updates will now report the
    /// location of the camera.
    public func unsetAnchor() {
        debugPrint("FMLocationManager:unsetAnchor")
        self.anchorFrame = nil
    }
    

    /// Calculate the FMPose difference of the anchor frame with respect to the given frame.
    /// This method is just here for SDK client debugging purposes.
    /// It is not part of the localization flow.
    /// - Parameter frame: the current ARFrame
    public func anchorDeltaPoseForFrame(_ frame: ARFrame) -> FMPose {
        if let anchorFrame = anchorFrame {
            return anchorFrame.poseWithRespectTo(frame)
        } else {
            return FMPose()
        }
    }
    
    /// Check to see if a given zone is in the provided radius
    ///
    /// - Parameter zone: zone to search for
    /// - Parameter radius: search radius in meters
    /// - Parameter completion: closure that consumes boolean server result
    public func isZoneInRadius(_ zone: FMZone.ZoneType, radius: Int, completion: @escaping (Bool)->Void) {
        FMApi.shared.isZoneInRadius(zone, radius: radius, completion: completion) { error in
            //TODO: handle errors
            print(error)
        }
    }
    
    
    // MARK: - Internal instance methods
    
    /// Localize the image frame. It triggers a network request that
    /// provides a response via the delegate.
    ///
    /// - Parameter frame: Frame to localize.
    internal func localize(frame: ARFrame) {
        if !isConnected {
            return
        }
        
        debugPrint("FMLocationManager:localize called with simulation: \(isSimulation)")
        self.state = .uploading
        
        // set up completion closure
        let localizeCompletion: FMApi.LocalizationResult = { location, zones in
            self.delegate?.locationManager(didUpdateLocation: location, withZones: zones)
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        // set up error closure
        let localizeError: FMApi.ErrorResult = { error in
//            let errorResponse = try decoder.decode(ErrorResponse.self, from: response)
//            debugPrint("FMLocationManager:uploadImage didFailWithError: \(errorResponse.message ?? "Unkown error")")
//            let error: Error = FMError.custom(errorDescription: errorResponse.message)
//            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        // send request
        FMApi.shared.localize(frame: frame, completion: localizeCompletion, error: localizeError)
    }
}
