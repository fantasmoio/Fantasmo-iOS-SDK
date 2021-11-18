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

protocol FMLocationManagerDelegate: AnyObject {
    func locationManager(didUpdateLocation result: FMLocationResult)
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?)
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest)
    func locationManager(didChangeState state: FMLocationManager.State)
    func locationManager(didUpdateFrame frame: ARFrame, info: AccumulatedARKitInfo, rejections: FrameFilterRejectionStatisticsAccumulator)
}

class FMLocationManager: NSObject {
    
    enum State: String {
        case stopped        // doing nothing
        case localizing     // localizing
        case uploading      // uploading image while localizing
        case paused         // paused
   }
    
    // MARK: - Properties
    
    public private(set) var state: State = .stopped {
        didSet {
            if state != oldValue {
                delegate?.locationManager(didChangeState: state)
            }
        }
    }
    
    // Clients can use this to mock the localization call
    public var mockLocalize: ((ARFrame) -> Void)?

    public var logLevel = FMLog.LogLevel.warning {
        didSet {
            log.logLevel = logLevel
        }
    }

    public var logIntercept: ((String) -> Void)? = nil {
        didSet {
            log.intercept = logIntercept
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
                return lastCLLocation?.coordinate ?? kCLLocationCoordinate2DInvalid
            }
        }
    }
    
    private var anchorFrame: ARFrame? {
        didSet {
            locationFuser.reset()
        }
    }
    
    private var frameFilterChain = FMFrameFilterChain()
    
    private lazy var behaviorRequester = BehaviorRequester { [weak self] behaviorRequest in
        // in testing mode, request behaviors even when stopped
        if self?.state != .stopped {
            self?.delegate?.locationManager(didRequestBehavior: behaviorRequest)
        }
    }
        
    /// Read-only vars, used to populate the statistics view
    public private(set) var lastFrame: ARFrame?
    public private(set) var lastCLLocation: CLLocation?
    public private(set) var lastResult: FMLocationResult?
    public private(set) var errors: [FMError] = []
    
    private weak var delegate: FMLocationManagerDelegate?

    // Fusion
    private var locationFuser = LocationFuser()
    
    /// States whether the client code using this manager set up connection with the manager.
    private var isConnected = false

    // MARK: - Analytics Properties
    private var accumulatedARKitInfo = AccumulatedARKitInfo()
    private var frameEventAccumulator = FrameFilterRejectionStatisticsAccumulator()
    private var appSessionId: String? // provided by client
    private var localizationSessionId: String? // created by SDK
    private let motionManager = MotionManager()
    
    // MARK: - Lifecycle
        
    /// Connect to the location service.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    public func connect(accessToken: String, delegate: FMLocationManagerDelegate) {
        log.debug(parameters: ["delegate": delegate])

        isConnected = true
        self.delegate = delegate
        
        // set up FMApi
        FMApi.shared.token = accessToken
    }

    /// Connect to the location service.
    /// Use this method if your app does not need to receive `ARSession` or `CLLocationManager` delegate calls
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    ///   - session: ARSession to subscribe to as a delegate
    ///   - locationManger: CLLocationManager to subscribe to as a delegate
    public func connect(accessToken: String,
                        delegate: FMLocationManagerDelegate,
                        session: ARSession? = nil,
                        locationManager: CLLocationManager? = nil) {
        log.debug(parameters: [
                    "delegate": delegate,
                    "session": session,
                    "locationManager": locationManager])
        
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
        frameFilterChain.restart()
        behaviorRequester.restart()
        motionManager.restart()
        locationFuser.reset()

        state = .localizing
    }
    
    /// Stops the generation of location updates.
    public func stopUpdatingLocation() {
        log.debug()

        motionManager.stop()

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
        
    /// Update the user's location, use instead of CLLocationManagerDelegate
    ///
    /// - Parameter location: current user location
    
    public func updateLocation(_ location: CLLocation) {
        lastCLLocation = location
    }
    
    /// Localize the image frame. It triggers a network request that
    /// provides a response via the delegate.
    ///
    /// - Parameter frame: Frame to localize.
    public func localize(frame: ARFrame, from session: ARSession) {
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
            lossOfTracking:
                accumulatedARKitInfo.trackingStateStatistics.framesWithNotAvailableTracking +
                accumulatedARKitInfo.trackingStateStatistics.framesWithLimitedTrackingState,
            total: accumulatedARKitInfo.elapsedFrames
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
            totalDistance: accumulatedARKitInfo.totalTranslation,
            magneticField: motionManager.magneticField
        )
        
        // If no valid approximate coordinate is found, throw an error and stop updating location for 1 second
        guard CLLocationCoordinate2DIsValid(approximateCoordinate) else {
            let error = FMError(FMLocationError.invalidCoordinate)
            self.errors.append(error)
            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
            self.state = .paused
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.state = .localizing
            }
            return
        }
        
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
            self.lastResult = result
            
            if self.state != .stopped {
                self.state = .localizing
            }
        }
        
        // Set up error closure
        let localizeError: FMApi.ErrorResult = { error in
            log.error(error)
            self.errors.append(error)
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
        
        guard state != .stopped else {
            return
        }
        
        // run the frame through the configured filters
        let filterResult = frameFilterChain.evaluate(frame, state: state)
        behaviorRequester.processResult(filterResult)
        accumulatedARKitInfo.update(with: frame)
        
        if case let .rejected(reason) = filterResult {
            frameEventAccumulator.accumulate(filterRejectionReason: reason)
        } else {
            if state == .localizing {
                localize(frame: frame, from: session)
            }
        }
        
        delegate?.locationManager(didUpdateFrame: frame, info: accumulatedARKitInfo, rejections: frameEventAccumulator)
    }
}

// MARK: - CLLocationManagerDelegate

extension FMLocationManager : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastCLLocation = locations.last
    }
}
