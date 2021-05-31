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
public protocol FMLocationDelegate: class {
    
    /// Tells the delegate that new location data is available.
    ///
    /// - Parameters:
    ///   - location: Location of the device (or anchor if set)
    ///   - zones: Semantic zone corresponding to the location
    func locationManager(didUpdateLocation location: CLLocation, withZones zones: [FMZone]?)
    
    /// Tells the delegate that an error has occurred.
    ///
    /// - Parameters:
    ///   - error: The error reported.
    ///   - metadata: Metadata related to the error.
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?)
    
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest)
}

/// Empty implementations of the protocol to allow optional
/// implementation for delegates.
public extension FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation, withZones zones: [FMZone]?) {}
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {}
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
    
    // Clients can use this to mock the localization call
    public var mockLocalize: ((ARFrame) -> Void)?
    
    /// A  boolean value that states whether location updates were started by invoking `startUpdatingLocation()`.
    public var isLocalizingInProgress: Bool {
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

    /// An estimate of the location. Coarse resolution is acceptable such as GPS or cellular tower proximity.
    /// Current implementation returns most recent location received from CoreLocation unless an override was set.
    var approximateCoordinate: CLLocationCoordinate2D {
        get {
            if let override = FMConfiguration.stringForInfoKey(.gpsLatLong) {
                log.warning("Using location override", parameters: ["override": override])
                let components = override.components(separatedBy:",")
                if let latitude = Double(components[0]), let longitude = Double(components[1]) {
                    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                } else {
                    return CLLocationCoordinate2D()
                }
            } else {
                return lastCLLocation?.coordinate ?? CLLocationCoordinate2D()
            }
        }
    }
    
    private var anchorFrame: ARFrame? {
        didSet {
            tester?.anchorFrame = anchorFrame
        }
    }
    
    // Variables set by delegate handling methods
    private var lastFrame: ARFrame?
    private var lastCLLocation: CLLocation?
    private weak var delegate: FMLocationDelegate?
    
    /// Used for testing private `FMLocationManager`'s API.
    private var tester: FMLocationManagerTester?
    
    /// States whether the client code using this manager set up connection with the manager.
    private var isClientOfManagerConnected = false
    
    // MARK: -
    
    /// This initializer must be used only for testing purposes. Otherwise use singleton object via `shared` static property.
    public init(tester: FMLocationManagerTester? = nil) {
        self.tester = tester
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
    
    /// Check to see if a given zone is in the provided radius
    ///
    /// - Parameter zone: zone to search for
    /// - Parameter radius: search radius in meters
    /// - Parameter completion: closure that consumes boolean server result
    public func isZoneInRadius(_ zone: FMZone.ZoneType, radius: Int, completion: @escaping (Bool)->Void) {
        log.debug()
        FMApi.shared.isZoneInRadius(
            zone, coordinate: approximateCoordinate, radius: radius, completion: completion
        ) { error in
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
        guard isLocalizingInProgress else { return }
        
        log.debug(parameters: ["simulation": isSimulation])
        state = .uploading
        
        // Run mock version of localization if one is set
        guard mockLocalize == nil else {
            mockLocalize?(frame)
            return
        }
        
        let openCVRelativeAnchorTransform = openCVPoseOfAnchorInVirtualDeviceCS(for: frame)
        let openCVRelativeAnchorPose = openCVRelativeAnchorTransform.map { FMPose($0) }

        // Set up completion closure
        let localizeCompletion: FMApi.LocalizationResult = { location, zones in
            log.debug(parameters: ["location": location, "zones": zones])
            self.delegate?.locationManager(didUpdateLocation: location, withZones: zones)
            if let tester = self.tester {
                let translation = openCVRelativeAnchorTransform?.inNonOpenCvCS.translation
                tester.locationManagerDidUpdateLocation(location, translationOfAnchorInVirtualDeviceCS: translation)
            }
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        // Set up error closure
        let localizeError: FMApi.ErrorResult = { error in
            log.error(error)
            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        FMApi.shared.localize(frame: frame,
                              relativeOpenCVAnchorPose: openCVRelativeAnchorPose,
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
    
    // MARK: - Helpers
    
    private func openCVPoseOfAnchorInVirtualDeviceCS(for frame: ARFrame) -> simd_float4x4? {
        if let anchorFrame = anchorFrame {
            let openCVVirtualDeviceTransform = frame.openCVTransformOfVirtualDeviceInWorldCS
            let openCVAnchorTransformInDeviceCS = openCVVirtualDeviceTransform.calculateRelativeTransformInTheCsOfSelf(
                of: anchorFrame.openCVTransformOfDeviceInWorldCS
            )
            return openCVAnchorTransformInDeviceCS
        } else {
            return nil
        }
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
        lastCLLocation = locations.last
    }
}
