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

// TODO - replaced with debug stats delegate
protocol FMLocationManagerDelegate: AnyObject {
    func locationManager(didUpdateLocation result: FMLocationResult)
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?)
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest)
    func locationManager(didChangeState state: FMLocationManager.State)
    func locationManager(didChangeNumberOfActiveUploads numberOfActiveUploads: Int)
    func locationManager(didUpdateFrame frame: FMFrame, info: AccumulatedARKitInfo)
    func locationManager(didUpdateFrameEvaluationStatistics frameEvaluationStatistics: FMFrameEvaluationStatistics)
    func locationManager(didUpdateFrameRejectionStatistics frameRejectionStatistics: FMFrameRejectionStatistics)
}

class FMLocationManager: NSObject {
    
    enum State: String {
        case stopped
        case localizing
    }
        
    // MARK: - Properties
    
    public private(set) var state: State = .stopped {
        didSet {
            if state != oldValue {
                delegate?.locationManager(didChangeState: state)
            }
        }
    }
    
    public private(set) var numberOfActiveUploads: Int = 0 {
        didSet {
            if numberOfActiveUploads != oldValue {
                delegate?.locationManager(didChangeNumberOfActiveUploads: numberOfActiveUploads)
            }
        }
    }
    
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
    var approximateLocation: CLLocation {
        get {
            if let override = FMConfiguration.stringForInfoKey(.gpsLatLong) {
                log.warning("Using location override", parameters: ["override": override])
                let components = override.components(separatedBy:",")
                if let latitude = Double(components[0]), let longitude = Double(components[1]) {
                    return CLLocation(latitude: latitude, longitude: longitude)
                } else {
                    return CLLocation.invalid
                }
            } else {
                return lastCLLocation ?? CLLocation.invalid
            }
        }
    }
    
    private var anchorFrame: FMFrame? {
        didSet {
            locationFuser.reset()
        }
    }
    
    private var frameEvaluatorChain = FMFrameEvaluatorChain(config: RemoteConfig.config())
        
    private var behaviorRequester: BehaviorRequester?
    
    /// Read-only vars, used to populate the statistics view
    public private(set) var lastFrame: FMFrame?
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
    private var frameEvaluationStatistics = FMFrameEvaluationStatistics(type: .imageQuality)
    private var frameRejectionStatistics = FMFrameRejectionStatistics()
    private var appSessionId: String? // provided by client
    private var appSessionTags: [String]? // provided by client
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
        
        // configure behavior requester
        let rc = RemoteConfig.config()
        if rc.isBehaviorRequesterEnabled {
            behaviorRequester = BehaviorRequester { [weak self] behaviorRequest in
                if self?.state != .stopped {
                    self?.delegate?.locationManager(didRequestBehavior: behaviorRequest)
                }
            }
        } else {
            behaviorRequester = nil
        }
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
    /// The max length of the string is 64 characters.
    /// - Parameter sessionTags: Optional, freeform list of tags to associate with the session for use by analytics.
    public func startUpdatingLocation(sessionId: String, sessionTags: [String]?) {
        log.debug()

        appSessionId = String(sessionId.prefix(64))
        appSessionTags = sessionTags
        localizationSessionId = UUID().uuidString

        accumulatedARKitInfo.reset()
        frameEvaluationStatistics.reset()
        frameRejectionStatistics.reset()
        frameEvaluatorChain.reset()
        behaviorRequester?.restart()
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
    public func localize(frame: FMFrame) {
        guard isConnected else { return }
        
        log.debug(parameters: ["simulation": isSimulation])
        
        let openCVRelativeAnchorTransform = openCVPoseOfAnchorInVirtualDeviceCS(for: frame)
        let openCVRelativeAnchorPose = openCVRelativeAnchorTransform.map { FMPose($0) }

        // Set up parameters

        let frameEvents = FMFrameEvents(
            excessiveTilt:
                (frameRejectionStatistics.filterRejections[.pitchTooHigh] ?? 0) +
                (frameRejectionStatistics.filterRejections[.pitchTooLow] ?? 0),
            excessiveBlur: 0, // blur filter no longer in use, server still requires this param
            excessiveMotion: frameRejectionStatistics.filterRejections[.movingTooFast] ?? 0,
            insufficientFeatures: frameRejectionStatistics.filterRejections[.insufficientFeatures] ?? 0,
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
        
        var imageEnhancementInfo: FMImageEnhancementInfo?
        if frame.enhancedImage != nil, let gamma = frame.enhancedImageGamma {
            imageEnhancementInfo = FMImageEnhancementInfo(
                gamma: gamma
            )
        }
        
        let localizationAnalytics =  FMLocalizationAnalytics(
            appSessionId: appSessionId,
            appSessionTags: appSessionTags,
            localizationSessionId: localizationSessionId,
            frameEvents: frameEvents,
            rotationSpread: rotationSpread,
            totalDistance: accumulatedARKitInfo.totalTranslation,
            magneticField: motionManager.magneticField,
            imageEnhancementInfo: imageEnhancementInfo,
            remoteConfigId: RemoteConfig.config().remoteConfigId
        )
        
        // If no valid approximate coordinate is found, throw an error
        guard CLLocationCoordinate2DIsValid(approximateLocation.coordinate) else {
            let error = FMError(FMLocationError.invalidCoordinate)
            self.errors.append(error)
            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
            return
        }
        
        let localizationRequest = FMLocalizationRequest(
            isSimulation: isSimulation,
            simulationZone: simulationZone,
            approximateLocation: approximateLocation,
            relativeOpenCVAnchorPose: openCVRelativeAnchorPose,
            analytics: localizationAnalytics
        )

        // Set up completion closure
        let localizeCompletion: FMApi.LocalizationResult = { location, zones in
            log.debug(parameters: ["location": location, "zones": zones])

            let result = self.locationFuser.locationFusedWithNew(location: location, zones: zones)
            self.delegate?.locationManager(didUpdateLocation: result)
            self.lastResult = result
            self.numberOfActiveUploads -= 1
        }
        
        // Set up error closure
        let localizeError: FMApi.ErrorResult = { error in
            log.error(error)
            self.errors.append(error)
            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
            self.numberOfActiveUploads -= 1
        }
        
        numberOfActiveUploads += 1
        
        FMApi.shared.sendLocalizationRequest(frame: frame,
                                             request: localizationRequest,
                                             completion: localizeCompletion,
                                             error: localizeError)
    }
            
    // MARK: - Helpers
    
    private func openCVPoseOfAnchorInVirtualDeviceCS(for frame: FMFrame) -> simd_float4x4? {
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
        
        let fmFrame = FMFrame(arFrame: frame)
        lastFrame = fmFrame
        
        guard state != .stopped else {
            return
        }
        
        frameEvaluatorChain.evaluateAsync(frame: fmFrame)
        
        if let frameToLocalize = frameEvaluatorChain.dequeueBestFrame() {
            localize(frame: frameToLocalize)
        }
        
        accumulatedARKitInfo.update(with: fmFrame)
        delegate?.locationManager(didUpdateFrame: fmFrame, info: accumulatedARKitInfo)
    }
}

// MARK: - FMFrameEvaluationChainDelegate

extension FMLocationManager : FMFrameEvaluatorChainDelegate {

    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFinishEvaluatingFrame frame: FMFrame) {
        // finished evaluating a frame, update analytics
        frameEvaluationStatistics.update(withFrame: frame)
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateNewBestFrame newBestFrame: FMFrame) {
        // new best frame was found, update analytics
        frameEvaluationStatistics.newBestFrame += 1
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame, belowCurrentBestScore currentBestScore: Float) {
        // new frame was evaluated but its score was below the current best score, update analytics
        frameEvaluationStatistics.belowCurrentBestScore += 1
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateFrame frame: FMFrame, belowMinScoreThreshold minScoreThreshold: Float) {
        // new frame was evaluated but its score was below the min score threshold, update analytics
        frameEvaluationStatistics.belowMinScoreThreshold += 1
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, whileEvaluatingOtherFrame otherFrame: FMFrame) {
        // frame was rejected because the frame evaluator was busy evaluating another frame, update analytics
        frameRejectionStatistics.evaluatingOtherFrame += 1
        delegate?.locationManager(didUpdateFrameRejectionStatistics: frameRejectionStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameFilterRejectionReason) {
        // frame was rejected by a frame filter, update analytics
        frameRejectionStatistics.addFilterRejection(reason)
        delegate?.locationManager(didUpdateFrameRejectionStatistics: frameRejectionStatistics)
        // send it to the behavior requester to suggest a remedy to the user
        behaviorRequester?.processFilterRejection(reason: reason)
    }
}

// MARK: - CLLocationManagerDelegate

extension FMLocationManager : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastCLLocation = locations.last
    }
}
