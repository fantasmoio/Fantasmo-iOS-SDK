//
//  ParkingExampleViewController.swift
//  FantasmoSDKParkingExample
//
//  Created by Nick Jensen on 07.10.21.
//

import UIKit
import FantasmoSDK
import CoreLocation

class ParkingExampleViewController: UIViewController {
        
    @IBOutlet var resultLabel: UILabel!
    @IBOutlet var isSimulationSwitch: UISwitch!
    @IBOutlet var showsStatisticsSwitch: UISwitch!
    
    var errorCount: Int = 0
    
    @IBAction func handleEndRideButton(_ button: UIButton) {
        /// Test location of a parking space in Berlin
        let testLocation = CLLocation(latitude: 52.50578283943285, longitude: 13.378954977173915)
        /// Before trying to localize with Fantasmo you should check if the user is near a mapped parking space
        FMParkingViewController.isParkingAvailable(near: testLocation) { [weak self] isParkingAvailable in
            if !isParkingAvailable {
                self?.resultLabel.text = "Parking not available near your location."
                return
            }
            self?.startParkingFlow()
        }
    }
    
    func startParkingFlow() {
        /// Create a new `FMParkingViewController` and `sessionId`. This is typically a UUID string
        /// but it can also follow your own format. It is used for analytics and billing purposes and
        /// should represent a single parking session.
        let sessionId = UUID().uuidString
        let parkingViewController = FMParkingViewController(sessionId: sessionId)
                
        /// Assign a delegate
        parkingViewController.delegate = self
                
        /// Run in simulation mode, if you're not near a space
        parkingViewController.isSimulation = isSimulationSwitch.isOn
        
        /// Show useful stats for debugging, if needed
        parkingViewController.showsStatistics = showsStatisticsSwitch.isOn

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
        /// Optional validation of the QR code can be done here
        /// Note: If you choose to implement this method, you *must* call the `continueBlock` with the validation result
        let isValidCode = qrCode.messageString != nil
        continueBlock(isValidCode)
        /// Validation can also be done asynchronously.
        ///
        ///     APIService.validateQRCode(qrCode) { isValidCode in
        ///         continueBlock(isValidCode)
        ///     }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {
        /// Got a localization result
        /// Localization will continue until you dismiss the view
        /// You should decide on acceptable criteria for a result, one way is by checking the `confidence` value
        if result.confidence != .low {
            /// We're satisfied with the result, dismiss to stop localizing
            parkingViewController.dismiss(animated: true) {
                let coordinate = result.location.coordinate
                self.resultLabel.text = "Coordinates: \(coordinate.latitude), \(coordinate.longitude)\n\nConfidence: \(result.confidence)"
                self.errorCount = 0
            }
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
        if errorCount >= 5 {
            /// Too many errors, dismiss to stop localizing
            parkingViewController.dismiss(animated: true) {
                self.resultLabel.text = error.localizedDescription
                self.errorCount = 0
            }
        }
    }
}
