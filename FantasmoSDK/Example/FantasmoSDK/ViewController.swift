//
//  ViewController.swift
//  FantasmoSDK
//
//  Copyright (c) 2020 Fantasmo. All rights reserved.
//

import UIKit
import FantasmoSDK
import CoreLocation
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    var fmLocationManager: FMLocationManager?
    var fmLocationDelegate: FMLocationDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        
        fmLocationManager?.delegate = self
        fmLocationManager?.start(locationDelegate: fmLocationDelegate!, licenseKey: "")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
}

extension ViewController: ARSessionDelegate, ARSCNViewDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation?, locationMetadata metadata: Any) {
         
    }
    
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any) {
        
    }
}
