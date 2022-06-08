//
//  FMParkingViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit
import ARKit
import SceneKit

public final class FMParkingViewController: UIViewController {
        
    /// Check if there's an available parking space near a supplied CLLocation and that Fantasmo is supported on the device.
    ///
    /// - Parameter location: the CLLocation to check
    /// - Parameter completion: block with a boolean result
    ///
    /// This method is used to decide whether or not you can park and localize with Fantasmo. The `completion` block is called
    /// with the answer. If `true` it means there is a parking space near the supplied location and that the device supports
    /// `ARKit`, which is required by Fantasmo. You should now construct a `FMParkingViewController` and present it modally.
    /// If the value is `false` then you should _not_ attempt to localize and instead resort to other options.
    public static func isParkingAvailable(near location: CLLocation, completion: @escaping (Bool) -> Void) {
        log.debug()
        #if !targetEnvironment(simulator)
        guard ARWorldTrackingConfiguration.isSupported else {
            log.error(FMError(FMDeviceError.notSupported))
            completion(false)
            return
        }
        #endif
        guard CLLocationCoordinate2DIsValid(location.coordinate) else {
            log.error(FMError(FMLocationError.invalidCoordinate))
            completion(false)
            return
        }
        FMApi.shared.token = FMConfiguration.accessToken()
        FMApi.shared.sendInitializationRequest(location: location, completion: completion) { error in
            // For now, clients only care if a zone was found, so an error condition can be treated as a `false` completion
            log.error(error)
            completion(false)
        }
    }
    
    public enum State {
        case idle
        case qrScanning
        case localizing
    }
    
    public private(set) var state: State = .idle
        
    public weak var delegate: FMParkingViewControllerDelegate?
    
    // MARK: -
    // MARK: Initialization
    
    public let sessionId: String
    
    public let sessionTags: [String]?
    
    public let accessToken: String
    
    /// Designated initializer.
    ///
    /// - Parameter sessionId: This parameter allows you to associate localization results with your own session identifier.
    /// Typically this would be a UUID string, but it can also follow your own format. For example, a scooter parking session
    /// might involve multiple localization attempts. For analytics and billing purposes this identifier allows you to link a
    /// set of attempts with a single parking session.
    ///
    /// - Parameter sessionTags: An optional list of tags for the parking session. This parameter can be used to label and group
    /// parking sessions that have something in common. For example parking sessions that take place in the same city might have
    /// the city's name as a tag. These are used for analytics purposes only and will be included in usage reports. Each tag must
    /// be a string and there is no limit to the number of tags a session can have.
    public init(sessionId: String, sessionTags: [String]? = nil) {
        self.sessionId = sessionId
        self.sessionTags = sessionTags
        self.accessToken = FMConfiguration.accessToken()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    // MARK: QR Codes
    
    public var qrCodeDetector: FMQRCodeDetector = QRCodeDetector()
    
    private var qrCodeAwaitingContinue: Bool = false
    
    private var qrScanningViewControllerType: FMQRScanningViewControllerProtocol.Type = FMQRScanningViewController.self
    
    private var qrScanningViewController: FMQRScanningViewControllerProtocol? { self.children.first as? FMQRScanningViewControllerProtocol }
    
    /// Registers a custom view controller class to present and use when scanning QR codes.
    ///
    /// - Parameter classType: Any class type conforming to FMQRScanningViewControllerProtocol.
    public func registerQRScanningViewController(_ classType: FMQRScanningViewControllerProtocol.Type) {
        qrScanningViewControllerType = classType
    }
    
    /// Presents the default or custom registered QR scanning view controller and starts observing QR codes in the ARSession.
    ///
    /// This method is only intended to be called while idle.
    private func startQRScanning() {
        if state != .idle {
            return
        }
        
        state = .qrScanning
        showChildViewController(qrScanningViewControllerType.init(), animated: false)
        
        qrScanningViewController?.didStartQRScanning()
        delegate?.parkingViewControllerDidStartQRScanning(self)
    }
    
    /// Provide a manually-entered QR code string and proceed to localization.
    ///
    /// If validation of the entered string is needed, it should be done in `parkingViewController(_:didEnterQRCodeString:continueBlock:)`
    /// of your `FMParkingViewControllerDelegate`. This method does nothing if the QR-code scanner is inactive, or if another code is being
    /// validated.
    public func enterQRCode(string: String) {
        if state != .qrScanning {
            return
        }
        guard qrCodeAwaitingContinue == false, qrCodeDetector.detectedQRCode == nil else {
            return  // Another code is being validated
        }
        // Set an AR anchor to use when localizing
        fmLocationManager.setAnchor()
        guard let delegate = delegate else {
            // No delegate set, continue immediately to localization
            startLocalizing()
            return
        }
        // Pass the entered code to the delegate along with a continueBlock
        qrCodeAwaitingContinue = true
        delegate.parkingViewController(self, didEnterQRCodeString: string) { [weak self] shouldContinue in
            guard Thread.isMainThread else {
                fatalError("continueBlock must be invoked on main thread")
            }
            guard let state = self?.state, state == .qrScanning else {
                return
            }
            if shouldContinue {
                self?.startLocalizing()
            } else {
                self?.qrCodeAwaitingContinue = false
                self?.fmLocationManager.unsetAnchor()
            }
        }
    }
    
    // MARK: -
    // MARK: Localization
    
    private let fmLocationManager: FMLocationManager = FMLocationManager()
    
    private var localizingViewControllerType: FMLocalizingViewControllerProtocol.Type = FMLocalizingViewController.self
    
    private var localizingViewController: FMLocalizingViewControllerProtocol? { self.children.first as? FMLocalizingViewControllerProtocol }

    /// Registers a custom view controller type to present and use when localizing.
    ///
    /// - Parameter classType: Any class type conforming to FMLocalizingViewControllerProtocol.
    public func registerLocalizingViewController(_ classType: FMLocalizingViewControllerProtocol.Type) {
        localizingViewControllerType = classType
    }
    
    /// Presents the default or custom registered localizing view controller and starts the localization process.
    ///
    /// This method is only intended to be called while QR scanning, it performs an animated transition to the localization view.
    private func startLocalizing() {
        if state != .qrScanning {
            return
        }
        
        qrScanningViewController?.didStopQRScanning()
        delegate?.parkingViewControllerDidStopQRScanning(self)
        
        state = .localizing
        showChildViewController(localizingViewControllerType.init(), animated: true)
        
        if usesInternalLocationManager {
            sceneView.startUpdatingLocation()
        }
        
        fmLocationManager.connect(accessToken: accessToken, delegate: self)
        fmLocationManager.startUpdatingLocation(sessionId: sessionId, sessionTags: sessionTags)
        
        localizingViewController?.didStartLocalizing()
        delegate?.parkingViewControllerDidStartLocalizing(self)
    }
    
    /// Controls whether this class uses its own internal `CLLocationManager` to automatically receive location updates. Default is `true`.
    ///
    /// When set to `false` it is expected that location updates will be manually provided via the `updateLocation(_:)` method.
    public var usesInternalLocationManager: Bool = true {
        didSet {
            guard usesInternalLocationManager != oldValue, state == .localizing else {
                return
            }
            if usesInternalLocationManager {
                sceneView.startUpdatingLocation()
            } else {
                sceneView.stopUpdatingLocation()
            }
        }
    }
    
    /// Allows host apps to manually provide a location update when `usesInternalLocationManager` is set to `false`.
    ///
    /// - Parameter location: the device's current location.
    ///
    /// This method has no effect when `usesInternalLocationManager` is set to `true`.
    public func updateLocation(_ location: CLLocation) {
        guard !usesInternalLocationManager else {
            log.warning("`updateLocation:` has no effect when `usesInternalLocationManager` is set to `true`.")
            return
        }
        guard state == .localizing else {
            return
        }
        fmLocationManager.updateLocation(location)
        statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
    }
    
    // MARK: -
    // MARK: Debug
   
    
    /// A recorded parking simulation to run. If set, the recorded video and sensor data will be used instead of the real thing.
    public var simulation: FMSimulation? {
        didSet {
            fmLocationManager.isSimulation = simulation != nil
        }
    }

    @available(*, deprecated, message: "Use the `simulation` property instead.")
    public var isSimulation: Bool {
        set {
        }
        get {
            return simulation != nil
        }
    }

    public var logLevel: FMLog.LogLevel {
        set {
            fmLocationManager.logLevel = newValue
        }
        get {
            return fmLocationManager.logLevel
        }
    }
    
    public var logIntercept: ((String) -> Void)? {
        set {
            fmLocationManager.logIntercept = newValue
        }
        get {
            return fmLocationManager.logIntercept
        }
    }
        
    // MARK: -
    // MARK: UI
    
    private var sceneView: FMSceneView!
    
    private var containerView: UIView!
    
    private var statisticsView: FMSessionStatisticsView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
     
        if let simulation = simulation {
            sceneView = FMSimulationView(asset: simulation.asset)
        } else {
            sceneView = FMARSceneView()
        }
        sceneView.delegate = self
        self.view.addSubview(sceneView)
        
        containerView = UIView()
        self.view.addSubview(containerView)
        
        if let statisticsView = statisticsView {
            self.view.addSubview(statisticsView)
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if targetEnvironment(simulator)
        guard simulation != nil else {
            fatalError("You must set a `simulation` to run in Simulator.")
        }
        #endif
        
        sceneView.run()
                
        if state == .idle {
            startQRScanning()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        sceneView.pause()
        
        if isBeingDismissed || isMovingFromParent {
            fmLocationManager.unsetAnchor()
            fmLocationManager.stopUpdatingLocation()
            fmLocationManager.sendSessionAnalytics()
        }
    }
                
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        sceneView.frame = bounds
        containerView.frame = bounds
        statisticsView?.frame = bounds
        self.children.forEach { $0.view?.frame = containerView.bounds }
    }
    
    private func showChildViewController(_ childViewController: UIViewController?, animated: Bool) {
        let fromViewController = self.children.first
        fromViewController?.presentedViewController?.dismiss(animated: animated, completion: nil)
        fromViewController?.willMove(toParent: nil)
        fromViewController?.removeFromParent()
                
        if let toViewController = childViewController {
            self.addChild(toViewController)
            containerView.addSubview(toViewController.view)
            toViewController.view.layoutIfNeeded()
        }
        
        guard animated else {
            childViewController?.didMove(toParent: self)
            fromViewController?.view.removeFromSuperview()
            return
        }
        
        childViewController?.view.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut, animations: {
            childViewController?.view.alpha = 1
            fromViewController?.view.alpha = 0
        }, completion: { _ in
            childViewController?.didMove(toParent: self)
            fromViewController?.view.removeFromSuperview()
        })
    }
    
    public var showsStatistics: Bool = false {
        didSet {
            if showsStatistics, statisticsView == nil {
                let nibName = String(describing: FMSessionStatisticsView.self)
                statisticsView = Bundle(for: self.classForCoder).loadNibNamed(nibName, owner: self, options: nil)?.first as? FMSessionStatisticsView
                statisticsView?.update(state: fmLocationManager.state)
                statisticsView?.update(activeUploads: fmLocationManager.activeUploads)
                statisticsView?.update(lastResult: fmLocationManager.lastResult)
                statisticsView?.update(errorCount: fmLocationManager.errors.count, lastError: fmLocationManager.errors.last)
                statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
                statisticsView?.isUserInteractionEnabled = false
                self.viewIfLoaded?.addSubview(statisticsView!)
            }
            statisticsView?.isHidden = !showsStatistics
        }
    }
        
    public override var shouldAutorotate: Bool {
        return false
    }
}

// MARK: -
// MARK: FMLocationDelegate

extension FMParkingViewController: FMLocationManagerDelegate {
    
    func locationManager(didBeginUpload frame: FMFrame) {
        statisticsView?.update(activeUploads: fmLocationManager.activeUploads)
    }
    
    func locationManager(didUpdateLocation result: FMLocationResult) {
        delegate?.parkingViewController(self, didReceiveLocalizationResult: result)
        localizingViewController?.didReceiveLocalizationResult(result)
        
        statisticsView?.update(lastResult: result)
        statisticsView?.update(activeUploads: fmLocationManager.activeUploads)
    }

    func locationManager(didRequestBehavior behavior: FMBehaviorRequest) {
        delegate?.parkingViewController(self, didRequestLocalizationBehavior: behavior)
        localizingViewController?.didRequestLocalizationBehavior(behavior)
    }

    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {
        let fmError = error as! FMError  // TODO - change this method to receive an FMError
        delegate?.parkingViewController(self, didReceiveLocalizationError: fmError, errorMetadata: metadata)
        localizingViewController?.didReceiveLocalizationError(fmError, errorMetadata: metadata)
        
        statisticsView?.update(errorCount: fmLocationManager.errors.count, lastError: fmError)
        statisticsView?.update(activeUploads: fmLocationManager.activeUploads)
    }
    
    func locationManager(didChangeState state: FMLocationManager.State) {
        statisticsView?.update(state: state)
    }
        
    func locationManager(didUpdateFrame frame: FMFrame, info: AccumulatedARKitInfo) {
        statisticsView?.updateThrottled(frame: frame, info: info)
    }
    
    func locationManager(didUpdateFrameEvaluationStatistics frameEvaluationStatistics: FMFrameEvaluationStatistics) {
        statisticsView?.update(frameEvaluationStatistics: frameEvaluationStatistics)
    }
}

// MARK: -
// MARK: FMSceneViewDelegate

extension FMParkingViewController: FMSceneViewDelegate {
    
    func sceneView(_ sceneView: FMSceneView, didUpdate frame: FMFrame) {
        // Pass the current AR frame to the location manager
        fmLocationManager.sceneView(sceneView, didUpdate: frame)
        
        switch state {
        case .qrScanning:
            if qrCodeAwaitingContinue {
                // A scanned code was already passed to the delegate
                // but the continueBlock hasn't been called yet.
                return
            }
            guard let qrCode = qrCodeDetector.detectedQRCode else {
                // No code has been detected yet, check for one now.
                qrCodeDetector.checkAsyncThrottled(frame.capturedImage)
                return
            }
            // A code has been detected, notify the scanning view
            qrScanningViewController?.didScanQRCode(qrCode)
            // Set an AR anchor to use when localizing
            fmLocationManager.setAnchor()
            guard let delegate = delegate else {
                // No delegate set, continue immediately to localization.
                startLocalizing()
                return
            }
            // Pass the scanned code to the delegate along with a continueBlock
            qrCodeAwaitingContinue = true
            delegate.parkingViewController(self, didScanQRCode: qrCode) { [weak self] shouldContinue in
                guard Thread.isMainThread else {
                    fatalError("continueBlock must be invoked on main thread")
                }
                guard let state = self?.state, state == .qrScanning else {
                    return
                }
                if shouldContinue {
                    self?.startLocalizing()
                } else {
                    self?.qrCodeAwaitingContinue = false
                    self?.qrCodeDetector.detectedQRCode = nil
                    self?.fmLocationManager.unsetAnchor()
                }
            }
        default:
            break
        }
    }
    
    func sceneView(_ sceneView: FMSceneView, didUpdate location: CLLocation) {
        guard usesInternalLocationManager, state == .localizing else {
            return
        }
        fmLocationManager.sceneView(sceneView, didUpdate: location)
        statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
    }
    
    func sceneView(_ sceneView: FMSceneView, didFailWithError error: Error) {
        guard error is ARError else {
            return
        }
        let errorWithInfo: NSError
        if #available(iOS 14.5, *) {
            let underlyingError = (error as NSError).underlyingErrors.first
            errorWithInfo = underlyingError as NSError? ?? error as NSError
        } else {
            errorWithInfo = error as NSError
        }
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "ARSession Error", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Dismiss", style: .default) { _ in
                alertController.dismiss(animated: true) { self.dismiss(animated: true, completion: nil) }
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
