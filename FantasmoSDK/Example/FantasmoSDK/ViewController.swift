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
    private let clLocationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clLocationManager.delegate = self
        clLocationManager.requestAlwaysAuthorization()
        clLocationManager.startUpdatingLocation()

        sceneView.delegate = self
        sceneView.session.delegate = self
        
        FMLocationManager.shared.connect(accessToken: "", delegate: self)
        FMLocationManager.shared.startUpdatingLocation()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

    }
}

extension ViewController: ARSessionDelegate, ARSCNViewDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
    }
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation, withZones zones: [FMZone]?) {
            print("User location Lat: \(location.coordinate.latitude) Longitude: \(location.coordinate.longitude)")
    }
    
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {
        if let metadataError = metadata as? Error {
            print("Error : \(metadataError.localizedDescription)")
        }
    }
}
