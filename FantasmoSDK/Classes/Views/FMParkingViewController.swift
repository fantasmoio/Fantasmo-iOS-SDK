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
    
    public init(sessionId: String) {
        self.sessionId = sessionId
        guard let accessToken = FMConfiguration.stringForInfoKey(.accessToken) else {
            fatalError("Missing or invalid access token. Please add an access token to the Info.plist with the following key: " +
                        "\(FMConfiguration.infoKeys.accessToken.rawValue)")
        }
        self.accessToken = accessToken
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    // MARK: QR Codes
    
    private var qrCodeDetector = QRCodeDetector()
    
    private var qrCodeAwaitingContinue: Bool = false
    
    private var qrScanningViewControllerType: FMQRScanningViewControllerProtocol.Type = FMQRScanningViewController.self
    
    private var qrScanningViewController: FMQRScanningViewControllerProtocol? { self.children.first as? FMQRScanningViewControllerProtocol }
    
    /**
     Registers a custom view controller class to present and use when scanning QR codes.
     - Parameter classType: Any class type conforming to FMQRScanningViewControllerProtocol.
     */
    public func registerQRScanningViewController(_ classType: FMQRScanningViewControllerProtocol.Type) {
        qrScanningViewControllerType = classType
    }

    /**
     Presents the default or custom registered QR scanning view controller and starts observing QR codes in the ARSession.
     
     This method is only intended to be called while idle.
     */
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
        
    private let fmLocationManager: FMLocationManager = FMLocationManager.shared
    
    private var localizingViewControllerType: FMLocalizingViewControllerProtocol.Type = FMLocalizingViewController.self
    
    private var localizingViewController: FMLocalizingViewControllerProtocol? { self.children.first as? FMLocalizingViewControllerProtocol }

    /**
     Registers a custom view controller type to present and use when localizing.
     - Parameter classType: Any class type conforming to FMLocalizingViewControllerProtocol.
     */
    public func registerLocalizingViewController(_ classType: FMLocalizingViewControllerProtocol.Type) {
        localizingViewControllerType = classType
    }

    /**
     Presents the default or custom registered localizing view controller and starts the localization process.
     
     This method is only intended to be called while QR scanning, it performs an animated transition to the localization view.
     */
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
    
    /**
     Controls whether this class uses its own internal `CLLocationManager` to determine the users location.
     
     When set to `false` it is expected that the user's location will be manually updated via `updateUserLocation(_:)`. Default is `true`.
     */
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
    
    /**
     Allows the host app to manually update the user's location when not using the internal `CLLocationManager`.
     
     - Parameter location: a `CLLocation` of the user's current location.
     
     Note: This method does nothing when `usesInternalLocationManager` is set to `true`.
     */
    public func updateUserLocation(_ location: CLLocation) {
        guard !usesInternalLocationManager else {
            return
        }
        locationManager(clLocationManager, didUpdateLocations: [location])
    }
    
    // MARK: -
    // MARK: Location Manager
        
    public var isSimulation: Bool {
        set {
            fmLocationManager.isSimulation = newValue
        }
        get {
            return fmLocationManager.isSimulation
        }
    }

    public var simulationZone: FMZone.ZoneType {
        set {
            fmLocationManager.simulationZone = newValue
        }
        get {
            return fmLocationManager.simulationZone
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
        
    // MARK: -
    // MARK: UI
    
    private var sceneView: ARSCNView!
    
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
        self.children.forEach { $0.view?.frame = bounds }
        statisticsView?.frame = bounds
    }
    
    private func showChildViewController(_ childViewController: UIViewController?, animated: Bool) {
        let fromViewController = self.children.first
        fromViewController?.willMove(toParent: nil)
        fromViewController?.removeFromParent()
                
        if let toViewController = childViewController {
            self.addChild(toViewController)
            self.view.addSubview(toViewController.view)
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
                statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
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
        delegate?.parkingViewController(self, didReceiveLocalizationError: error as! FMError, errorMetadata: metadata)
        localizingViewController?.didReceiveLocalizationError(error as! FMError, errorMetadata: metadata)
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
        if state == .localizing {
            fmLocationManager.locationManager(manager, didUpdateLocations: locations)
            statisticsView?.update(deviceLocation: fmLocationManager.lastCLLocation)
        }
    }
}
