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
    func locationManager(didBeginUpload frame: FMFrame)
    func locationManager(didUpdateLocation result: FMLocationResult)
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?)
    func locationManager(didRequestBehavior behavior: FMBehaviorRequest)
    func locationManager(didChangeState state: FMLocationManager.State)
    func locationManager(didUpdateFrame frame: FMFrame, info: AccumulatedARKitInfo)
    func locationManager(didUpdateFrameEvaluationStatistics frameEvaluationStatistics: FMFrameEvaluationStatistics)
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

    /// This flag indicates that the frames being sent to localize are from a simulation.
    public var isSimulation = false
    
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
    public private(set) var activeUploads: [FMFrame] = []
    
    private weak var delegate: FMLocationManagerDelegate?

    // Fusion
    private var locationFuser = LocationFuser()
    
    // Tracks device motion
    private let motionManager = MotionManager()
    
    /// States whether the client code using this manager set up connection with the manager.
    private var isConnected = false

    // MARK: - Analytics Properties
    private var accumulatedARKitInfo = AccumulatedARKitInfo()
    private var frameEvaluationStatistics = FMFrameEvaluationStatistics(type: .imageQuality)
    private var appSessionId: String? // provided by client
    private var appSessionTags: [String]? // provided by client
    private var localizationSessionId: String? // created by SDK
    private var startTime = Date() // resets on `startUpdatingLocation`
    private var totalFramesUploaded: Int = 0 // total calls to `localize`
    private var locationResultCount: Int = 0 // total successful results from `localize`
    private var errorResultCount: Int = 0 // total error results from `localize`
        
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
        behaviorRequester?.restart()
        motionManager.restart()
        locationFuser.reset()
        
        startTime = Date()
        totalFramesUploaded = 0
        locationResultCount = 0
        errorResultCount = 0
        
        state = .localizing
        
        frameEvaluatorChain.delegate = self
        frameEvaluatorChain.resetWindow()
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
        
        let legacyFrameEvents = FMLegacyFrameEvents(
            excessiveTilt:
                (frameEvaluationStatistics.rejectionReasons[.pitchTooHigh] ?? 0) +
                (frameEvaluationStatistics.rejectionReasons[.pitchTooLow] ?? 0),
            excessiveBlur: 0, // blur filter no longer in use, server still requires this param
            excessiveMotion:
                (frameEvaluationStatistics.rejectionReasons[.movingTooFast] ?? 0) +
                (frameEvaluationStatistics.rejectionReasons[.trackingStateExcessiveMotion] ?? 0),
            insufficientFeatures:
                frameEvaluationStatistics.rejectionReasons[.trackingStateInsufficentFeatures] ?? 0,
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
            legacyFrameEvents: legacyFrameEvents,
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
            simulationZone: .parking,
            approximateLocation: approximateLocation,
            relativeOpenCVAnchorPose: openCVRelativeAnchorPose,
            analytics: localizationAnalytics
        )

        // Set up completion closure
        let localizeCompletion: FMApi.LocalizationResult = { location, zones in
            log.debug(parameters: ["location": location, "zones": zones])

            let result = self.locationFuser.locationFusedWithNew(location: location, zones: zones)
            self.lastResult = result
            self.activeUploads.removeAll { $0 === frame }
            self.locationResultCount += 1
            self.delegate?.locationManager(didUpdateLocation: result)
        }
        
        // Set up error closure
        let localizeError: FMApi.ErrorResult = { error in
            log.error(error)
            
            self.errors.append(error)
            self.activeUploads.removeAll { $0 === frame }
            self.errorResultCount += 1
            self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
        }
        
        activeUploads.append(frame)
        totalFramesUploaded += 1
        delegate?.locationManager(didBeginUpload: frame)
        
        FMApi.shared.sendLocalizationRequest(frame: frame,
                                             request: localizationRequest,
                                             completion: localizeCompletion,
                                             error: localizeError)
    }
    
    public func sendSessionAnalytics() {
        var imageQualityUserInfo: FMImageQualityUserInfo? = nil
        if #available(iOS 13.0, *), let imageQualityEvaluator = (frameEvaluatorChain.frameEvaluator as? FMImageQualityEvaluatorCoreML) {
            imageQualityUserInfo = FMImageQualityUserInfo(modelVersion: imageQualityEvaluator.modelVersion)
        }
        let frameEvaluations = FMSessionFrameEvaluations(
            count: frameEvaluationStatistics.totalEvaluations,
            type: frameEvaluationStatistics.type,
            highestScore: frameEvaluationStatistics.highestScore ?? 0,
            lowestScore: frameEvaluationStatistics.lowestScore ?? 0,
            averageScore: frameEvaluationStatistics.averageEvaluationScore,
            averageTime: frameEvaluationStatistics.averageEvaluationTime,
            imageQualityUserInfo: imageQualityUserInfo
        )
        let frameRejections = FMSessionFrameRejections(
            count: frameEvaluationStatistics.totalRejections,
            rejectionReasons: frameEvaluationStatistics.rejectionReasons.compactMapValues { $0 > 0 ? $0 : nil }
        )
        let sessionAnalytics = FMSessionAnalytics(
            localizationSessionId: localizationSessionId ?? "",
            appSessionId: appSessionId ?? "",
            appSessionTags: appSessionTags ?? [],
            totalFrames: accumulatedARKitInfo.elapsedFrames,
            totalFramesUploaded: totalFramesUploaded,
            frameEvaluations: frameEvaluations,
            frameRejections: frameRejections,
            locationResultCount: locationResultCount,
            errorResultCount: errorResultCount,
            totalTranslation: accumulatedARKitInfo.totalTranslation,
            rotationSpread: FMRotationSpread(
                pitch: accumulatedARKitInfo.eulerAngleSpreadsAccumulator.pitch.spread,
                yaw: accumulatedARKitInfo.eulerAngleSpreadsAccumulator.yaw.spread,
                roll: accumulatedARKitInfo.eulerAngleSpreadsAccumulator.roll.spread
            ),
            timestamp: Date().timeIntervalSince1970,
            totalDuration: Date().timeIntervalSince(startTime),
            location: approximateLocation,
            remoteConfigId: RemoteConfig.config().remoteConfigId,
            udid: UIDevice.current.identifierForVendor?.uuidString ?? "",
            deviceModel: UIDevice.current.identifier,
            deviceOs: UIDevice.current.correctedSystemName,
            deviceOsVersion: UIDevice.current.correctedSystemName,
            sdkVersion: FMSDKInfo.fullVersion,
            hostAppBundleIdentifier: FMSDKInfo.hostAppBundleIdentifier,
            hostAppMarketingVersion: FMSDKInfo.hostAppMarketingVersion,
            hostAppBuild: FMSDKInfo.hostAppBuild
        )
                
        FMApi.shared.sendSessionAnalytics(sessionAnalytics) { error in
            if let error = error {
                log.error(error)
            } else {
                log.info("successfully sent session analytics")
            }
        }
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

extension FMLocationManager : FMSceneViewDelegate {

    public func sceneView(_ sceneView: FMSceneView, didUpdate frame: FMFrame) {
        
        lastFrame = frame
        
        guard state != .stopped else {
            return
        }
        
        frameEvaluatorChain.evaluateAsync(frame: frame)
        
        if let frameToLocalize = frameEvaluatorChain.dequeueBestFrame() {
            localize(frame: frameToLocalize)
        }
        
        accumulatedARKitInfo.update(with: frame)
        delegate?.locationManager(didUpdateFrame: frame, info: accumulatedARKitInfo)
    }
    
    func sceneView(_ sceneView: FMSceneView, didFailWithError error: Error) {
    }
}

// MARK: - FMFrameEvaluationChainDelegate

extension FMLocationManager : FMFrameEvaluatorChainDelegate {

    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didStartWindow startDate: Date) {
        // start a new evaluation window, update session analytics
        frameEvaluationStatistics.startWindow(at: startDate)
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didFinishEvaluatingFrame frame: FMFrame) {
        // finished evaluating a frame, update session analytics
        frameEvaluationStatistics.addEvaluation(frame: frame)
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didEvaluateNewBestFrame newBestFrame: FMFrame) {
        // new best frame was found, update session analytics
        frameEvaluationStatistics.setCurrentBest(frame: newBestFrame)
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, withFilter filter: FMFrameFilter, reason: FMFrameRejectionReason) {
        // frame was rejected by a filter, update session analytics
        frameEvaluationStatistics.addRejection(reason, filter: filter)
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
        
        // send it to the behavior requester to suggest a remedy to the user
        behaviorRequester?.processFilterRejection(reason: reason)
    }
    
    func frameEvaluatorChain(_ frameEvaluatorChain: FMFrameEvaluatorChain, didRejectFrame frame: FMFrame, reason: FMFrameRejectionReason) {
        // frame was rejected, update session analytics
        frameEvaluationStatistics.addRejection(reason)
        delegate?.locationManager(didUpdateFrameEvaluationStatistics: frameEvaluationStatistics)
    }
}

// MARK: - CLLocationManagerDelegate

extension FMLocationManager : CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastCLLocation = locations.last
    }
}
