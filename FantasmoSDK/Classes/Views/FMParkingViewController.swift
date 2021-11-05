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
    
    /// Default radius in meters used when checking parking availability via `isParkingAvailable(near:completion:)`.
    ///
    /// This value can be overriden in the Info.plist with the key `FM_AVAILABILITY_RADIUS`
    public static let defaultParkingAvailabilityRadius: Int = 50
    
    /// Check if there's an available parking space near a supplied CLLocation.
    ///
    /// - Parameter location: the CLLocation to check
    /// - Parameter completion: block with a boolean result
    ///
    /// This method should be used to determine whether or not you should try to park and localize with Fantasmo.
    /// The boolean value passed to the completion block tells you if there is an available parking space within the
    /// acceptable radius of the supplied location. If `true`, you should construct an `FMParkingViewController` and
    /// attempt to localize. If `false` you should resort to other options.
    public static func isParkingAvailable(near location: CLLocation, completion: @escaping (Bool) -> Void) {
        log.debug()
        guard CLLocationCoordinate2DIsValid(location.coordinate) else {
            log.error(FMError(FMLocationError.invalidCoordinate))
            completion(false)
            return
        }
        let radius = FMConfiguration.intForInfoKey(.availabilityRadius) ?? defaultParkingAvailabilityRadius
        FMApi.shared.token = FMConfiguration.accessToken()
        FMApi.shared.sendZoneInRadiusRequest(.parking, coordinate: location.coordinate, radius: radius, completion: completion
        ) { error in
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
    
    public let accessToken: String
    
    /// Designated initializer.
    ///
    /// - Parameter sessionId: an identifier for the parking session
    ///
    /// The `sessionId` parameter allows you to associate localization results with your own session identifier.
    /// Typically this would be a UUID string, but it can also follow your own format. For example, a scooter parking
    /// session might involve multiple localization attempts. For analytics and billing purposes this identifier allows
    /// you to link a set of attempts with a single parking session.
    public init(sessionId: String) {
        self.sessionId = sessionId
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
    
    // MARK: -
    // MARK: Localization
        
    private let clLocationManager: CLLocationManager = CLLocationManager()
        
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
                
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if usesInternalLocationManager {
            clLocationManager.requestWhenInUseAuthorization()
            clLocationManager.startUpdatingLocation()
        }
        
        fmLocationManager.connect(accessToken: accessToken, delegate: self)
        fmLocationManager.startUpdatingLocation(sessionId: sessionId)
        
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
                clLocationManager.requestWhenInUseAuthorization()
                clLocationManager.startUpdatingLocation()
            } else {
                clLocationManager.stopUpdatingLocation()
            }
        }
    }
    
    /// Allows host apps to manually provide a location update.
    ///
    /// - Parameter location: the device's current location.
    ///
    /// This method can only be used when `usesInternalLocationManager` is set to `false`.
    public func updateLocation(_ location: CLLocation) {
        guard !usesInternalLocationManager, state == .localizing else {
            return
        }
        fmLocationManager.updateLocation(location)
        statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
    }
    
    // MARK: -
    // MARK: Debug
        
    public var isSimulation: Bool {
        set {
            fmLocationManager.isSimulation = newValue
            fmLocationManager.simulationZone = isSimulation ? .parking : .unknown
        }
        get {
            return fmLocationManager.isSimulation
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
    
    private var sceneView: ARSCNView!
    
    private var containerView: UIView!
    
    private var statisticsView: FMSessionStatisticsView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                
        let session = ARSession()
        session.delegate = self
     
        sceneView = ARSCNView(frame: .zero)
        sceneView.session = session
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        sceneView.preferredFramesPerSecond = 60
        self.view.addSubview(sceneView)
        
        containerView = UIView()
        self.view.addSubview(containerView)
        
        if let statisticsView = statisticsView {
            self.view.addSubview(statisticsView)
        }
        
        if let camera = sceneView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.isAutoFocusEnabled = true
        }
        configuration.worldAlignment = .gravity
        
        let options: ARSession.RunOptions = [.resetTracking]
        session.run(configuration, options: options)
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if state == .idle {
            startQRScanning()
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
    
    deinit {
        fmLocationManager.unsetAnchor()
        fmLocationManager.stopUpdatingLocation()
    }
}

// MARK: -
// MARK: FMLocationDelegate

extension FMParkingViewController: FMLocationManagerDelegate {
    
    func locationManager(didUpdateLocation result: FMLocationResult) {
        delegate?.parkingViewController(self, didReceiveLocalizationResult: result)
        localizingViewController?.didReceiveLocalizationResult(result)
        statisticsView?.update(lastResult: result)
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
    }
    
    func locationManager(didChangeState state: FMLocationManager.State) {
        statisticsView?.update(state: state)
    }
    
    func locationManager(didUpdateFrame frame: ARFrame, info: AccumulatedARKitInfo, rejections: FrameFilterRejectionStatisticsAccumulator) {
        statisticsView?.updateThrottled(frame: frame, info: info, rejections: rejections)
    }
}

// MARK: -
// MARK: ARSessionDelegate

extension FMParkingViewController: ARSessionDelegate {

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch state {
        case .qrScanning:
            if qrCodeAwaitingContinue {
                // A scanned code was already passed to the delegate
                // but the continueBlock hasn't been called yet.
                return
            }
            guard let qrCode = qrCodeDetector.detectedQRCode else {
                // No code has been detected yet, check for one now.
                qrCodeDetector.checkFrameAsyncThrottled(frame)
                return
            }
            // A code has been detected, notify the scanning view
            qrScanningViewController?.didScanQRCode(qrCode)
            guard let delegate = delegate else {
                // No delegate set, continue immediately to localization.
                startLocalizing()
                return
            }
            // Set an AR anchor to use when localizing
            fmLocationManager.setAnchor()
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
        
        case .localizing:
            // If localizing, pass the current AR frame to the location manager
            fmLocationManager.session(session, didUpdate: frame)
        
        default:
            break
        }
    }
}

// MARK: -
// MARK: CLLocationManagerDelegate

extension FMParkingViewController: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard usesInternalLocationManager, state == .localizing else {
            return
        }
        fmLocationManager.locationManager(manager, didUpdateLocations: locations)
        statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
    }
}
