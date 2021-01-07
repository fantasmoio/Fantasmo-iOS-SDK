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
        
        FMLocationManager.shared.isSimulation = false
        FMLocationManager.shared.simulationZone = .parking
        
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
        debugPrint("ViewController: didUpdateLocations")
    }
}

extension ViewController: ARSessionDelegate, ARSCNViewDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {

    }
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation, withZones zones: [FMZone]?) {
        debugPrint("ViewController: User location Lat: \(location.coordinate.latitude) Longitude: \(location.coordinate.longitude)")
        if let zone = zones?.first, zone.zoneType == .parking {
            debugPrint("ViewController: Parking validated!")
        } else {
            debugPrint("ViewController: Parking invalid.")
        }
    }
    
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {
        debugPrint("ViewController: didFailWithError called")
        if let metadataError = metadata as? Error {
            debugPrint("ViewController:  Error : \(metadataError.localizedDescription)")
        }
    }
}
