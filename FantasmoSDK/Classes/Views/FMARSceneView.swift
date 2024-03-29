//
//  FMARSceneView.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 02.06.22.
//

import UIKit
import ARKit
import SceneKit

class FMARSceneView: UIView, FMSceneView {
    
    var delegate: FMSceneViewDelegate?
    
    var arScnView: ARSCNView!

    var clLocationManager: CLLocationManager!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let session = ARSession()
        session.delegate = self
        
        arScnView = ARSCNView(frame: .zero)
        arScnView.session = session
        arScnView.antialiasingMode = .multisampling4X
        arScnView.automaticallyUpdatesLighting = false
        arScnView.preferredFramesPerSecond = 60
        addSubview(arScnView)
        
        if let camera = arScnView.pointOfView?.camera {
            camera.wantsHDR = true
            camera.wantsExposureAdaptation = true
            camera.exposureOffset = -1
            camera.minimumExposure = -1
        }
        
        clLocationManager = CLLocationManager()
        clLocationManager.delegate = self
        clLocationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        arScnView.frame = self.bounds
    }
        
    func run() {
        let configuration = ARWorldTrackingConfiguration()
        if #available(iOS 11.3, *) {
            configuration.isAutoFocusEnabled = true
        }
        configuration.worldAlignment = .gravity
        
        let options: ARSession.RunOptions = [.resetTracking]
        arScnView.session.run(configuration, options: options)
    }
    
    func pause() {
        arScnView.session.pause()
    }
    
    func startUpdatingLocation() {
        clLocationManager.requestWhenInUseAuthorization()
        clLocationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        clLocationManager.stopUpdatingLocation()
    }
}

extension FMARSceneView: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Convert to FMFrame and pass to the delegate
        let fmFrame = FMFrame(arFrame: frame)
        delegate?.sceneView(self, didUpdate: fmFrame)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        delegate?.sceneView(self, didFailWithError: error)
    }
}

extension FMARSceneView: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        delegate?.sceneView(self, didUpdate: location)
    }
}
