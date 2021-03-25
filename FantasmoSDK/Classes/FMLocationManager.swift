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
    
    public var isConnected = false
    public var logLevel = FMLog.LogLevel.warning {
        didSet {
            log.logLevel = logLevel
        }
    }

    /// When in simulation mode, mock data is used from the assets directory instead of the live camera feed.
    /// This mode is useful for implementation and debugging.
    public var isSimulation = false
    /// The zone that will be simulated.
    public var simulationZone = FMZone.ZoneType.parking

    
    // MARK: - Lifecycle
    
    private init() {}
    
    /// Connect to the location service.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    public func connect(accessToken: String,
                        delegate: FMLocationDelegate) {
        
        log.debug(parameters: ["delegate": delegate])

        self.delegate = delegate
        
        // set up FMApi
        FMApi.shared.delegate = self
        FMApi.shared.token = accessToken
    }

    
    // MARK: - Public instance methods
    
    /// Starts the generation of updates that report the user’s current location.
    public func startUpdatingLocation() {
        log.debug()
        self.isConnected = true
        self.state = .localizing
    }
    
    /// Stops the generation of location updates.
    public func stopUpdatingLocation() {
        log.debug()
        self.state = .stopped
    }
    
    /// Set an anchor point. All location updates will now report the
    /// location of the anchor instead of the camera.
    public func setAnchor() {
        log.debug()
        self.anchorFrame = ARSession.lastFrame
    }
    
    /// Unset the anchor point. All location updates will now report the
    /// location of the camera.
    public func unsetAnchor() {
        log.debug()
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
        log.debug()
        FMApi.shared.isZoneInRadius(zone, radius: radius, completion: completion) { error in
            // For now, clients only care if a zone was found, so an error condition can be treated as a `false` completion
            log.error(error)
            completion(false)
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
        
        log.debug(parameters: ["simulation": isSimulation])
        self.state = .uploading
        
        // set up completion closure
        let localizeCompletion: FMApi.LocalizationResult = { location, zones in
            log.debug(parameters: ["location": location, "zones": zones])
            self.delegate?.locationManager(didUpdateLocation: location, withZones: zones)
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        // set up error closure
        let localizeError: FMApi.ErrorResult = { error in
            log.error(error)
            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        // send request
        FMApi.shared.localize(frame: frame, completion: localizeCompletion, error: localizeError)
    }
}
