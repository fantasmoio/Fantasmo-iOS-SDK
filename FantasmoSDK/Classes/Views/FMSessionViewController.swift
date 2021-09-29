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
}

public class FMSessionViewController: UIViewController {
    
    public weak var delegate: FMSessionViewControllerDelegate?
    
    /**
     Registers a custom view controller class to construct and use when scanning QR codes.
     - Parameter classType: Any class type conforming to FMQRScanningViewControllerProtocol.
     */
    public func registerQRScanningViewController(_ classType: FMQRScanningViewControllerProtocol) {
        
    }

    /**
     Registers a custom view controller class to construct and use when localizing.
     - Parameter classType: Any class type conforming to FMLocalizingViewControllerProtocol.
     */
    public func registerLocalizingViewController(_ classType: FMLocalizingViewControllerProtocol) {
        
    }

    /**
     Presents the default or custom registered QR scanning view controller and starts observing QR codes in the ARSession.
     
     Found QR codes can be handled either via the session delegate `func TODO` or in a custom registered `FMQRScanningViewControllerProtocol` implementation.
     This method automatically stops localizing.
     */
    public func startQRScanning() {
        let qrScanningViewController = FMQRScanningViewController()
        childNavigationController.pushViewController(qrScanningViewController, animated: true)
    }
    
    /**
     Presents the default or custom registered localizing view controller and starts the localization process.
     
     Localization results can be handled either via the session delegate `func TODO` or in a custom registered `FMLocalizingViewControllerProtocol` implementation.
     This method automatically stops QR scanning.
     */
    public func startLocalizing() {
        
    }
    
    /**
     Dismisses the default or custom registered QR scanning view controller and stops observing QR codes in the ARSession.
     */
    public func stopQRScanning() {
        
    }
        
    /**
     Dismisses the default or custom registered localizing view controller and stops the localization process.
     */
    public func stopLocalizing() {
        
    }
    
    
    private var sceneView = ARSCNView(frame: .zero)
    
    private var childNavigationController = UINavigationController()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                
        let session = ARSession()
        session.delegate = self
        
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
        
        childNavigationController.setNavigationBarHidden(true, animated: false)
        self.addChild(childNavigationController)
        self.view.addSubview(childNavigationController.view)
        childNavigationController.didMove(toParent: self)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.worldAlignment = .gravity
        
        let options: ARSession.RunOptions = [.resetTracking]
        session.run(configuration, options: options)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        sceneView.frame = bounds
        childNavigationController.view.frame = bounds
    }
    
    public override var shouldAutorotate: Bool {
        return false
    }
}

extension FMSessionViewController: ARSessionDelegate {

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
}
