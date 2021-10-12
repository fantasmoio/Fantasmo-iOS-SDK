//
//  ParkingExampleViewController.swift
//  FantasmoSDKParkingExample
//
//  Created by Nick Jensen on 07.10.21.
//

import UIKit
import FantasmoSDK

class ParkingExampleViewController: UIViewController {
        
    @IBOutlet var resultLabel: UILabel!
    
    var errorCount: Int = 0
    
    @IBAction func handleEndRideButton(_ button: UIButton) {
        let parkingViewController = FMParkingViewController(sessionId: UUID().uuidString)
        parkingViewController.delegate = self
        parkingViewController.modalPresentationStyle = .fullScreen
        
        // Simulate
        parkingViewController.isSimulation = true
        parkingViewController.simulationZone = .parking
        
        // Show useful debug info
        // parkingViewController.showsStatistics = true
        
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
        /// APIService.validateQRCode(qrCode) { isValidCode in
        ///     continueBlock(isValidCode)
        /// }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {
        /// Got a localization result
        /// Localization will continue until the view is dismissed
        /// You should decide on acceptable criteria for a successful result, one way is to check the `confidence` value
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
        if (error.type as? FMLocationError) == FMLocationError.accessDenied {
            return  /// This error indicates we don't have access to the users location
        }
        /// Localization will continue until the view is dismissed
        /// You should decide on an acceptable threshold of errors and dismiss the view when it's reached
        errorCount += 1
        if errorCount >= 5 {
            /// Too many errors, dismiss to stop localizing and resort to fallback options
            parkingViewController.dismiss(animated: true) {
                self.resultLabel.text = error.localizedDescription
                self.errorCount = 0
            }
        }
    }
}
