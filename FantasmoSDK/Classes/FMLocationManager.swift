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

open class FMLocationManager: NSObject {
    
    public enum State {
        case stopped        // doing nothing
        case localizing     // localizing
        case uploading      // uploading image while localizing
    }
    
    // MARK: - Properties
    
    public static let shared = FMLocationManager()
    public private(set) var state = State.stopped
    
    // Clients can use this to mock the localization call
    public var mockLocalize: ((ARFrame) -> Void)?

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
            locationFuser.reset()
        }
    }
    
    private var qualityFrameFilter = FMCompoundFrameQualityFilter()
    
    /// Throttler allowing to notify delegate of "behaviour request" not too often when quality of captured frames is too low
    private lazy var frameFailureThrottler = FrameRejectionThrottler { [weak self] rejectionReason in
        let behaviorRequest = rejectionReason.mapToBehaviorRequest()
        self?.delegate?.locationManager(didRequestBehavior: behaviorRequest)
    }
    
    // Variables set by delegate handling methods
    private var lastFrame: ARFrame?
    private var lastCLLocation: CLLocation?
    private weak var delegate: FMLocationDelegate?

    // Fusion
    private var locationFuser = LocationFuser()

    /// Used for testing private `FMLocationManager`'s API.
    private var tester: FMLocationManagerTester?
    
    /// States whether the client code using this manager set up connection with the manager.
    private var isConnected = false

    // MARK: - Analytics Properties
    private var accumulatedARKitInfo = AccumulatedARKitInfo()
    private var frameEventAccumulator = FrameFilterRejectionStatisticsAccumulator()
    private var appSessionId: String? // provided by client
    private var localizationSessionId: String? // created by SDK

    // MARK: - Testing
    
    /// This initializer must be used only for testing purposes. Otherwise use singleton object via `shared` static property.
    public init(tester: FMLocationManagerTester? = nil) {
        self.tester = tester
        self.tester?.accumulatedARKitInfo = accumulatedARKitInfo
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

        isConnected = true
        self.delegate = delegate
        
        // set up FMApi
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
        
        isConnected = true
        connect(accessToken: accessToken, delegate: delegate)
        session?.delegate = self
        locationManager?.delegate = self
    }
    
    // MARK: - Public instance methods
    
    /// Starts the generation of updates that report the user’s current location.
    /// - Parameter sessionId: Identifier for a unique localization session for use by analytics and billing.
    ///                 The max length of the string is 64 characters.
    public func startUpdatingLocation(sessionId: String) {
        log.debug()

        appSessionId = String(sessionId.prefix(64))
        localizationSessionId = UUID().uuidString

        accumulatedARKitInfo.reset()
        frameEventAccumulator.reset()
        qualityFrameFilter.startOrRestartFiltering()
        frameFailureThrottler.restart()
        locationFuser.reset()

        state = .localizing
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
    /// - Parameter zone: Zone to search for
    /// - Parameter radius: Search radius in meters
    /// - Parameter completion: Closure that consumes boolean server result
    public func isZoneInRadius(_ zone: FMZone.ZoneType, radius: Int, completion: @escaping (Bool)->Void) {
        log.debug()
        FMApi.shared.sendZoneInRadiusRequest(
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
        guard isConnected else { return }

        log.debug(parameters: ["simulation": isSimulation])
        state = .uploading
        
        // Run mock version of localization if one is set
        guard mockLocalize == nil else {
            mockLocalize?(frame)
            return
        }
        
        let openCVRelativeAnchorTransform = openCVPoseOfAnchorInVirtualDeviceCS(for: frame)
        let openCVRelativeAnchorPose = openCVRelativeAnchorTransform.map { FMPose($0) }

        // Set up parameters

        let frameEvents = FMFrameEvents(
            excessiveTilt:
                (frameEventAccumulator.counts[.pitchTooHigh] ?? 0) +
                (frameEventAccumulator.counts[.pitchTooLow] ?? 0),
            excessiveBlur: frameEventAccumulator.counts[.imageTooBlurry] ?? 0,
            excessiveMotion: frameEventAccumulator.counts[.movingTooFast] ?? 0,
            insufficientFeatures: frameEventAccumulator.counts[.insufficientFeatures] ?? 0,
            lossOfTracking: 0, // FIXME
            total: frameEventAccumulator.total
        )

        let rotationSpread = FMRotationSpread(
            pitch: accumulatedARKitInfo.eulerAngleSpreadsAccumulator.pitch.spread,
            yaw: accumulatedARKitInfo.eulerAngleSpreadsAccumulator.yaw.spread,
            roll: accumulatedARKitInfo.eulerAngleSpreadsAccumulator.roll.spread
        )

        let localizationAnalytics =  FMLocalizationAnalytics(
            appSessionId: appSessionId,
            localizationSessionId: localizationSessionId,
            frameEvents: frameEvents,
            rotationSpread: rotationSpread,
            totalDistance: accumulatedARKitInfo.totalTranslation
        )

        let localizationRequest = FMLocalizationRequest(
            isSimulation: isSimulation,
            simulationZone: simulationZone,
            approximateCoordinate: approximateCoordinate,
            relativeOpenCVAnchorPose: openCVRelativeAnchorPose,
            analytics: localizationAnalytics
        )

        // Set up completion closure
        let localizeCompletion: FMApi.LocalizationResult = { location, zones in
            log.debug(parameters: ["location": location, "zones": zones])

            let result = self.locationFuser.locationFusedWithNew(location: location, zones: zones)
            self.delegate?.locationManager(didUpdateLocation: result)

            if let tester = self.tester {
                let translation = openCVRelativeAnchorTransform?.inNonOpenCvCS.translation
                tester.locationManager(didUpdateLocation: result, translationOfAnchorInVirtualDeviceCS: translation)
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
        
        FMApi.shared.sendLocalizationRequest(frame: frame,
                                             request: localizationRequest,
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
        
        if state == .localizing {
            let filterResult = qualityFrameFilter.accepts(frame)
            if case let .rejected(reason) = filterResult {
                frameEventAccumulator.accumulate(filterRejectionReason: reason)
            }
            frameFailureThrottler.onNext(frameFilterResult: filterResult)
            
            if case .accepted = filterResult {
                localize(frame: frame, from: session)
            }
        }
        
        if state != .stopped {
            accumulatedARKitInfo.update(with: frame)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension FMLocationManager : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastCLLocation = locations.last
    }
}
