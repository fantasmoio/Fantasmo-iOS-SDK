//
//  ParkingExampleViewController.swift
//  FantasmoSDKParkingExample
//
//  Created by Nick Jensen on 07.10.21.
//

import UIKit
import FantasmoSDK
import CoreLocation
import MapKit

class ParkingExampleViewController: UIViewController {
        
    @IBOutlet var resultLabel: UILabel!
    @IBOutlet var mapPinButton: UIButton!
    @IBOutlet var endRideButton: UIButton!
    @IBOutlet var isSimulationSwitch: UISwitch!
    
    var errorCount: Int = 0
    var lastResult: FMLocationResult?
    var locationManager = CLLocationManager()
    var deviceLocation: CLLocation!
    var parkingSimulation = FMSimulation(named: "parking-session-1")
        
    @IBAction func handleEndRideButton(_ button: UIButton) {
        let myLocation = getMyLocation()
        /// Before trying to localize with Fantasmo, check if you're near a mapped parking space
        FMParkingViewController.isParkingAvailable(near: myLocation) { [weak self] isParkingAvailable in
            if !isParkingAvailable {
                self?.resultLabel.text = "Parking not available near your location."
                return
            }
            self?.startParkingFlow()
        }
    }
    
    func startParkingFlow() {
        /// Create a new `FMParkingViewController` with a `sessionId`. This is typically a UUID string
        /// but it can also follow your own format. You may also provide an optional list of `sessionTags`
        /// for the session. Both of these params are only used for analytics and/or billing purposes.
        let sessionId = UUID().uuidString
        let sessionTags = ["ios-sdk-parking-example"]
        let parkingViewController = FMParkingViewController(sessionId: sessionId, sessionTags: sessionTags)
                
        /// Assign a delegate
        parkingViewController.delegate = self
        
        if isSimulationSwitch.isOn {
            /// If you're not physically near a space or you're running in the Simulator, use our recorded parking simulation
            parkingViewController.simulation = parkingSimulation
        }
        
        /// Optionally register custom view controllers for each step
        ///
        ///     parkingViewController.registerQRScanningViewController(MyCustomQRScanningViewController.self)
        ///     parkingViewController.registerLocalizingViewController(MyCustomLocalizingViewController.self)
        
        /// Present modally to start
        parkingViewController.modalPresentationStyle = .fullScreen
        self.present(parkingViewController, animated: true)
    }
}

extension ParkingExampleViewController: FMParkingViewControllerDelegate {
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void)) {
        /// Optional validation of a scanned QR code can be done here
        /// Note: If you choose to implement this method, you *must* call the `continueBlock` with the validation result
        let isValidCode = qrCode.messageString != nil
        continueBlock(isValidCode)
        
        /// Validation can also be done asynchronously.
        ///
        ///     APIService.validateQRCode(qrCode) { isValidCode in
        ///         continueBlock(isValidCode)
        ///     }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didEnterQRCodeString qrCodeString: String, continueBlock: @escaping ((Bool) -> Void)) {
        /// Optional validation of a manually-entered QR code string can be done here
        /// Note: If you choose to implement this method, you *must* call the `continueBlock` with the validation result
        let isValidCode = qrCodeString.isEmpty == false
        continueBlock(isValidCode)
        
        /// Validation can also be done asynchronously.
        ///
        ///     APIService.validateQRCode(qrCode) { isValidCode in
        ///         continueBlock(isValidCode)
        ///     }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {
        /// Got a localization result. You should decide on acceptable criteria for the result and dismiss the view when you're satisfied.
        /// For example you could optionally require a result confidence of `.medium` or higher.
        ///
        ///     if result.confidence == .low {
        ///         return
        ///     }
        ///
        /// Dismiss the view to stop localizing.
        parkingViewController.dismiss(animated: true) {
            let coordinate = result.location.coordinate
            self.resultLabel.text = "Coordinates: \(coordinate.latitude), \(coordinate.longitude)\n\nConfidence: \(result.confidence)"
            self.errorCount = 0
            self.lastResult = result
            self.mapPinButton.isHidden = false
        }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
        /// A localization error occured
        if (error.type as? FMLocationError) == FMLocationError.invalidCoordinate {
            /// This error means that we don't have a location for the device.
            /// If you're providing manual location updates (e.g. `parkingViewController.usesInternalLocationManager = false`)
            /// then check that you're setting the device location with `parkingViewController.updateLocation(clLocation)`
            /// Otherwise check that the user allowed access to location.
            return
        }
        /// Localization will continue until you dismiss the view
        /// You should decide on an acceptable threshold of errors and dismiss the view when it's reached
        errorCount += 1
        if errorCount < 10 {
            return
        }
        /// Too many errors, dismiss to stop localizing
        parkingViewController.dismiss(animated: true) {
            self.resultLabel.text = error.localizedDescription
            self.errorCount = 0
            self.lastResult = nil
            self.mapPinButton.isHidden = true
        }
    }
}


/// Code below here should not be relevant for host app integration.

extension ParkingExampleViewController: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        deviceLocation = locations.last
        updateEndRideButtonState()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        updateEndRideButtonState()
    }
    
    @IBAction func handleSimulationModeToggle(_ sender: UISwitch) {
        if !isSimulationSwitch.isOn {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            locationManager.stopUpdatingLocation()
        }
        updateEndRideButtonState()
    }
    
    /// Returns the device location or a test parking location in simulation mode.
    private func getMyLocation() -> CLLocation {
        var location: CLLocation
        if isSimulationSwitch.isOn {
            location = parkingSimulation.location
        } else {
            location = deviceLocation
        }
        return location
    }
    
    /// Returns whether the user denied access to location services.
    private var didDenyLocationAccess: Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()
        return authorizationStatus == .denied || authorizationStatus == .restricted
    }
    
    /// Enable the "Verify Parking" button only if we have a location or we're in simulation mode.
    private func updateEndRideButtonState() {
        endRideButton.isEnabled = isSimulationSwitch.isOn || deviceLocation != nil
        endRideButton.alpha = endRideButton.isEnabled ? 1.0 : 0.5
        if !isSimulationSwitch.isOn && didDenyLocationAccess {
            endRideButton.titleLabel?.adjustsFontSizeToFitWidth = true
            endRideButton.setTitle("Location access denied", for: .normal)
        } else {
            endRideButton.setTitle("Verify Parking", for: .normal)
        }
    }
        
    /// Show the lastResult on a MKMapView
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let mapView = segue.destination.view as? MKMapView, let result = lastResult else {
            return
        }
        let resultAnnotation = MKPointAnnotation()
        resultAnnotation.coordinate = result.location.coordinate
        let resultSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let resultRegion = MKCoordinateRegion(center: result.location.coordinate, span: resultSpan)
        mapView.addAnnotation(resultAnnotation)
        mapView.setRegion(resultRegion, animated: false)
    }
}
