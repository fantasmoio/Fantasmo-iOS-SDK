//
//  FMSessionViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit
import ARKit
import SceneKit

public protocol FMSessionViewControllerDelegate: AnyObject {
    func sessionViewController(_ sessionViewController: FMSessionViewController, didDetectQRCodeFeature qrCodeFeature: CIQRCodeFeature)
    func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidUpdateLocation result: FMLocationResult)
    func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidRequestBehavior behavior: FMBehaviorRequest)
    func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidFailWithError error: Error, errorMetadata: Any?)
}

public class FMSessionViewController: UIViewController {
        
    public enum State {
        case idle
        case qrScanning
        case localizing
    }
    
    public private(set) var state: State = .idle
    
    public weak var delegate: FMSessionViewControllerDelegate?
    
    // MARK: -
    // MARK: QR Codes
    
    private var qrCodeDetector = QRCodeDetector()
    
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
     
     Detected QR codes can be handled either via `FMSessionViewControllerDelegate` or in a registered `FMQRScanningViewControllerProtocol` implementation.
     This method automatically stops localizing.
     */
    public func startQRScanning() {
        if state == .qrScanning {
            return
        }
        
        if state == .localizing {
            self.stopLocalizing()
        }
        
        showChildViewController(qrScanningViewControllerType.init())
        
        state = .qrScanning
    }
    
    /**
     Dismisses the default or custom registered QR scanning view controller and stops observing QR codes in the ARSession.
     */
    public func stopQRScanning() {
        if state != .qrScanning {
            return
        }
        
        showChildViewController(nil)
        
        state = .idle
    }
    
    // MARK: -
    // MARK: Localization
        
    private let clLocationManager: CLLocationManager = CLLocationManager()
        
    private let fmLocationManager: FMLocationManager = FMLocationManager.shared
            
    private let fmLocationManagerAccessTokenInfoPlistKey = "FMLocationManagerAccessToken"
    
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
     
     - Parameter sessionId: Identifier for a unique localization session for use by analytics and billing. The max length of the string is 64 characters.
     
     Localization results can be handled either via `FMSessionViewControllerDelegate` or in a registered `FMLocalizingViewControllerProtocol` implementation.
     This method automatically stops QR scanning.
     */
    public func startLocalizing(sessionId: String) {
        if state == .localizing {
            return
        }

        if state == .qrScanning {
            self.stopQRScanning()
        }
        
        let accessToken = Bundle.main.object(forInfoDictionaryKey: fmLocationManagerAccessTokenInfoPlistKey) as? String
        guard let accessToken = accessToken, !accessToken.isEmpty else {
            log.error("Missing or invalid access token.")
            log.error("Please add a Fantasmo access token to your Info.plist with the following key: \(fmLocationManagerAccessTokenInfoPlistKey)")
            return
        }
        
        guard CLLocationManager.locationServicesEnabled() else {
            log.error("Location services are not enabled or permission was denied by the user.")
            return
        }
        
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if usesInternalLocationManager {
            clLocationManager.requestWhenInUseAuthorization()
            clLocationManager.startUpdatingLocation()
        }
        
        fmLocationManager.connect(accessToken: accessToken, delegate: self)
        fmLocationManager.startUpdatingLocation(sessionId: sessionId)
        
        showChildViewController(localizingViewControllerType.init())
        
        state = .localizing
    }
        
    /**
     Dismisses the default or custom registered localizing view controller and stops the localization process.
     */
    public func stopLocalizing() {
        if state != .localizing {
            return
        }
        
        clLocationManager.stopUpdatingLocation()
        fmLocationManager.stopUpdatingLocation()
        
        showChildViewController(nil)
        
        state = .idle
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
    
    public func setAnchor() {
        fmLocationManager.setAnchor()
    }
    
    public func unsetAnchor() {
        fmLocationManager.unsetAnchor()
    }
    
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
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        sceneView.frame = bounds
        self.children.forEach { $0.view?.frame = bounds }
    }
    
    private func showChildViewController(_ childViewController: UIViewController?) {
        self.children.forEach {
            $0.willMove(toParent: nil)
            $0.removeFromParent()
            $0.view?.removeFromSuperview()
        }
        if let childViewController = childViewController {
            self.view.addSubview(childViewController.view)
            self.addChild(childViewController)
            childViewController.didMove(toParent: self)
        }
    }
    
    public override var shouldAutorotate: Bool {
        return false
    }
    
    deinit {
        fmLocationManager.stopUpdatingLocation()
    }
}

// MARK: -
// MARK: FMLocationDelegate

extension FMSessionViewController: FMLocationDelegate {
    
    func locationManager(didUpdateLocation result: FMLocationResult) {
        delegate?.sessionViewController(self, localizationDidUpdateLocation: result)
        localizingViewController?.didUpdateLocation(result)
    }

    func locationManager(didRequestBehavior behavior: FMBehaviorRequest) {
        delegate?.sessionViewController(self, localizationDidRequestBehavior: behavior)
        localizingViewController?.didRequestBehavior(behavior)
    }

    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {
        delegate?.sessionViewController(self, localizationDidFailWithError: error, errorMetadata: metadata)
        localizingViewController?.didFailWithError(error, errorMetadata: metadata)
    }
}

// MARK: -
// MARK: ARSessionDelegate

extension FMSessionViewController: ARSessionDelegate {

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if state == .qrScanning {
            if let detectedQRCodeFeature = qrCodeDetector.detectedQRCodeFeature {
                delegate?.sessionViewController(self, didDetectQRCodeFeature: detectedQRCodeFeature)
                qrScanningViewController?.didDetectQRCodeFeature(detectedQRCodeFeature)
                qrCodeDetector.detectedQRCodeFeature = nil
            } else {
                qrCodeDetector.checkFrameAsync(frame)
            }
        }
        if state == .localizing {
            fmLocationManager.session(session, didUpdate: frame)
        }
    }
}

// MARK: -
// MARK: CLLocationManagerDelegate

extension FMSessionViewController: CLLocationManagerDelegate {
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if state == .localizing {
            fmLocationManager.locationManager(manager, didUpdateLocations: locations)
        }
    }
}
