//
//  ViewController.swift
//  FantasmoSDKDemo
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import UIKit
import FantasmoSDK
import CoreLocation
import ARKit

class ViewController: UIViewController {

    @IBOutlet weak var sceneView: ARSCNView!
    
    private let clLocationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        clLocationManager.delegate = self
        clLocationManager.requestAlwaysAuthorization()
        clLocationManager.startUpdatingLocation()
        
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
        print("ARSession did Update frame")
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])")
    }
}
