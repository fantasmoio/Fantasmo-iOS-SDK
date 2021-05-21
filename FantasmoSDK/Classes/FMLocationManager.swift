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
    
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest)
}

/// Empty implementations of the protocol to allow optional
/// implementation for delegates.
public extension FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation,
                         withZones zones: [FMZone]?) {}
    
    func locationManager(didFailWithError error: Error,
                         errorMetadata metadata: Any?) {}
    
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest) {}
}


/// Start and stop the delivery of camera-based location events.
open class FMLocationManager: NSObject, FMApiDelegate {
    
    public enum State {
        case stopped        // doing nothing
        case localizing     // localizing
        case uploading      // uploading image while localizing
    }
    
    
    // MARK: - Properties
    
    public static let shared = FMLocationManager()
    public private(set) var state = State.stopped
    public var qualityFilter = FMInputQualityFilter()
    
    // clients can use this to mock the localization call
    public var mockLocalize: ((ARFrame) -> Void)?
    
    internal var anchorFrame: ARFrame?
    
    // Variables set by delegate handling methods
    private var lastFrame: ARFrame?
    private var lastLocation: CLLocation?
    
    private weak var delegate: FMLocationDelegate?
    
    /// States whether the client code using this manager set up connection with the manager.
    private var isClientOfManagerConnected = false
    
    /// A  boolean value that states whether location updates were started by invoking `startUpdatingLocation()`.
    public var isLocationUpdateInProgress: Bool {
        state != .stopped
    }
    
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

    /// Returns most recent location unless an override was set
    var currentLocation: CLLocation {
        get {
            if let override = FMConfiguration.stringForInfoKey(.gpsLatLong) {
                log.warning("Using location override", parameters: ["override": override])
                let components = override.components(separatedBy:",")
                if let latitude = Double(components[0]), let longitude = Double(components[1]) {
                    return CLLocation(latitude: latitude, longitude: longitude)
                } else {
                    return CLLocation()
                }
            } else {
                return lastLocation ?? CLLocation()
            }
        }
    }
    
    // MARK: - Lifecycle
        
    /// Set up the connection of the client code with `FMLocationManager`.
    /// Use this method if your app does not need to receive `ARSession` or `CLLocationManager` delegate calls.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    public func connect(accessToken: String, delegate: FMLocationDelegate) {
        log.debug(parameters: ["delegate": delegate])

        isClientOfManagerConnected = true
        self.delegate = delegate
        qualityFilter.delegate = delegate
        
        // set up FMApi
        FMApi.shared.delegate = self
        FMApi.shared.token = accessToken
    }

    /// Set up the connection of the client code with `FMLocationManager`.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    ///   - session: ARSession to subscribe to as a delegate
    ///   - locationManger: CLLocationManager to subscribe to as a delegate
    public func connect(accessToken: String,
                        delegate: FMLocationDelegate,
                        session: ARSession? = nil,
                        locationManager: CLLocationManager? = nil) {
        log.debug(parameters: [
                    "delegate": delegate,
                    "session": session,
                    "locationManager": locationManager])
        
        isClientOfManagerConnected = true
        connect(accessToken: accessToken, delegate: delegate)
        session?.delegate = self
        locationManager?.delegate = self
    }
    
    // MARK: - Public instance methods
    
    /// Starts the generation of updates that report the user’s current location.
    public func startUpdatingLocation() {
        precondition(isClientOfManagerConnected, "Connection to the manager was not set up!")
        log.debug()
        state = .localizing
        qualityFilter.startFiltering()
    }
    
    /// Stops the generation of location updates.
    public func stopUpdatingLocation() {
        log.debug()
        state = .stopped
    }
    
    /// Set an anchor point. All location updates will now report the
    /// location of the anchor instead of the camera.
    public func setAnchor() {
        log.debug()
        anchorFrame = lastFrame
    }
    
    /// Unset the anchor point. All location updates will now report the
    /// location of the camera.
    public func unsetAnchor() {
        log.debug()
        anchorFrame = nil
    }
    

    /// Calculates transform of anchor relative to device and in the coordinate system of device (https://apple.co/2R37LJW).
    /// This method is just here for SDK client debugging purposes.
    /// It is not part of the localization flow.
    /// - Parameter frame: the current ARFrame
    public func transformOfAnchorRelativeToDeviceInCsOfDevice(_ frame: ARFrame) -> simd_float4x4? {
        if let anchorFrame = anchorFrame {
            let transform = frame.transformOfDeviceInWorldCS.calculateRelativeTransformInTheCsOfSelf(
                of: anchorFrame.transformOfDeviceInWorldCS
            )

            return transform
        } else {
            return nil
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
    internal func localize(frame: ARFrame, from session: ARSession) {
        guard isLocationUpdateInProgress else { return }
        
        log.debug(parameters: ["simulation": isSimulation])
        state = .uploading
        
        let deviceOrientation = frame.deviceOrientation(session: session)
        
        // run mock version of localization if one is set
        guard mockLocalize == nil else {
            mockLocalize?(frame)
            return
        }
        
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
        FMApi.shared.localize(frame: frame,
                              with: deviceOrientation,
                              completion: localizeCompletion,
                              error: localizeError)
    }
    
    private func localizeDone() {
        if state != .stopped {
           state = .localizing
        }
    }
    
    public func mockLocalizeDone() {
        localizeDone()
    }
}

// MARK: - ARSessionDelegate

extension FMLocationManager : ARSessionDelegate {
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        lastFrame = frame
        
        guard state == .localizing && qualityFilter.accepts(frame) else {
            return
        }
        localize(frame: frame, from: session)
    }
}

// MARK: - CLLocationManagerDelegate

extension FMLocationManager : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }
}
