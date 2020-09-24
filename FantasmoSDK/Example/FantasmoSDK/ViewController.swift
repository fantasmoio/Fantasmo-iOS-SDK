//
//  ViewController.swift
//  FantasmoSDK
//
//  Copyright (c) 2020 Fantasmo. All rights reserved.
//

import UIKit
import FantasmoSDK
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self
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
    func locationManager(receivedCPSLocation location: CLLocation) {
        
    }
    
    func locationManager(didFailWithError error: Error) {
        
    }
}
