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

    // fill this in with a valid token
    let FANTASMO_ACCESS_TOKEN = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // get location updates
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()

        // configure delegation
        sceneView.session.delegate = FMLocationManager.shared
        locationManager.delegate = FMLocationManager.shared

        // connect and start updating
        FMLocationManager.shared.connect(accessToken: FANTASMO_ACCESS_TOKEN, delegate: self)
        FMLocationManager.shared.startUpdatingLocation(sessionId: UUID().uuidString)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
}

extension ViewController: FMLocationDelegate {
    func locationManager(didUpdateLocation result: FMLocationResult) {
        let location = result.location
        let confidence = result.confidence
        let zones = result.zones

        debugPrint("ViewController: User location Lat: \(location.coordinate.latitude) Longitude: \(location.coordinate.longitude)")
        debugPrint("Confidence: \(confidence)")

        if let zone = zones?.first, zone.zoneType == .parking {
            debugPrint("ViewController: Parking validated!")
        } else {
            debugPrint("ViewController: Parking invalid.")
        }
    }

    func locationManager(didRequestBehavior behavior: FMBehaviorRequest) {
        let behavioralRemedy = behavior.rawValue
        debugPrint(behavioralRemedy)
    }

    func locationManager(didFailWithError error: Error, errorMetadata metadata: Any?) {
        debugPrint("ViewController: didFailWithError called")
        if let metadataError = metadata as? Error {
            debugPrint("ViewController:  Error : \(metadataError.localizedDescription)")
        }
    }
}
