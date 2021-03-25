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
    private let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

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
        print("ViewController: didUpdateLocations")
        
        // also update the FMLocationManager
        FMLocationManager.shared.locationManager(manager, didUpdateLocations: locations)
    }
}

extension ViewController: ARSessionDelegate, ARSCNViewDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // also update the FMLocationManager
        FMLocationManager.shared.session(session, didUpdate: frame)
    }
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation, withZones zones: [FMZone]?) {
        print("ViewController: User location Lat: \(location.coordinate.latitude) Longitude: \(location.coordinate.longitude)")
        if let zone = zones?.first, zone.zoneType == .parking {
            print("ViewController: Parking validated!")
        } else {
            print("ViewController: Parking invalid.")
        }
    }
    
    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {
        print("ViewController: didFailWithError called")
        if let metadataError = metadata as? Error {
            print("ViewController:  Error : \(metadataError.localizedDescription)")
        }
    }
}
