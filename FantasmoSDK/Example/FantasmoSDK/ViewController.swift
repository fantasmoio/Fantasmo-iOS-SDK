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
        
        FMLocationManager.shared.start(locationDelegate: self, licenseKey: "")
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
    func locationManager(didUpdateLocation location: CLLocation?, locationMetadata metadata: Any) {
        if let metadata = metadata as? Data, let jsonResponse = String(data: metadata, encoding: String.Encoding.utf8) {
            print("Success Response JSON: \(jsonResponse)")
            print("User location Lat: \(location?.coordinate.latitude ?? 0.0) Longitude: \(location?.coordinate.longitude ?? 0.0)")
        }
    }
    
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any) {
        if let metadataError = metadata as? Error {
            print("Error : \(metadataError.localizedDescription)")
        }
    }
    
    func locationManager(didFailWithError description: String) {
        print("Error : \(description)")
    }
}
