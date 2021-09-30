//
//  FMSessionViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit
import ARKit
import SceneKit

public protocol FMSessionViewControllerDelegate: UIViewController {
    func sessionViewController(_ sessionViewController: FMSessionViewController, didDetectQRCodeFeature qrCodeFeature: CIQRCodeFeature)
}

public class FMSessionViewController: UIViewController {
        
    public enum State {
        case idle
        case qrScanning
        case localizing
    }
    
    private (set) var state: State = .idle
    
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
     
     Detected QR codes can be handled either via `FMSessionViewControllerDelegate` or in a custom registered `FMQRScanningViewControllerProtocol` implementation.
     This method automatically stops localizing.
     */
    public func startQRScanning() {
        if state == .qrScanning {
            return
        }
        if state == .localizing {
            self.stopLocalizing()
        }
        state = .qrScanning
        showChildViewController(qrScanningViewControllerType.init())
    }
    
    /**
     Dismisses the default or custom registered QR scanning view controller and stops observing QR codes in the ARSession.
     */
    public func stopQRScanning() {
        if state != .qrScanning {
            return
        }
        state = .idle
        showChildViewController(nil)
    }
    
    // MARK: -
    // MARK: Localization
    
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
     
     Localization results can be handled either via `FMSessionViewControllerDelegate` or in a custom registered `FMLocalizingViewControllerProtocol` implementation.
     This method automatically stops QR scanning.
     */
    public func startLocalizing() {
        if state == .localizing {
            return
        }
        if state == .qrScanning {
            self.stopQRScanning()
        }
        state = .localizing
        showChildViewController(localizingViewControllerType.init())
    }
        
    /**
     Dismisses the default or custom registered localizing view controller and stops the localization process.
     */
    public func stopLocalizing() {
        if state != .localizing {
            return
        }
        state = .idle
        showChildViewController(nil)
    }
    
    private func handleQRScanningResult(_ qrCodeFeature: CIQRCodeFeature) {
        qrScanningViewController?.didDetectQRCodeFeature(qrCodeFeature)
        delegate?.sessionViewController(self, didDetectQRCodeFeature: qrCodeFeature)
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
}

// MARK: -
// MARK: ARSessionDelegate

extension FMSessionViewController: ARSessionDelegate {

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        if state == .qrScanning {
            if let detectedQRCodeFeature = qrCodeDetector.detectedQRCodeFeature {
                self.handleQRScanningResult(detectedQRCodeFeature)
                qrCodeDetector.detectedQRCodeFeature = nil
            } else {
                qrCodeDetector.checkFrameAsync(frame)
            }
        }
    }
}
