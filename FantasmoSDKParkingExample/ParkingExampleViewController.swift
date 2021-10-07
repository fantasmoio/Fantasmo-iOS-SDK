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
        // Simulate
        parkingViewController.showsStatistics = true
        parkingViewController.isSimulation = true
        parkingViewController.simulationZone = .parking
        //
        parkingViewController.delegate = self
        parkingViewController.modalPresentationStyle = .fullScreen
        self.present(parkingViewController, animated: true)
    }
}

extension ParkingExampleViewController: FMParkingViewControllerDelegate {
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void)) {
        // Optional validation of the QR code can be done here.
        // Once validated you should invoke the `continueBlock` with a boolean
        // indicating whether or not to continue to the localization.

        let isValidCode = qrCode.messageString != nil
        continueBlock(isValidCode)
        
        // Validation can also be done asynchronously.
        //
        // WebService.validateQRCode { isValidCode in
        //     continueBlock(isValidCode)
        // }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {
        if result.confidence != .low {
            // Dismiss the view when you're satisfied with the result
            parkingViewController.dismiss(animated: true) {
                let coordinate = result.location.coordinate
                self.resultLabel.text = "Coordinates: \(coordinate.latitude), \(coordinate.longitude)\n\nConfidence: \(result.confidence)"
                self.errorCount = 0
            }
        }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
        if (error.type as? FMLocationError) == FMLocationError.accessDenied {
            // User denied access to location, handle accordingly
            return
        }
        // An error occurred but localization will continue
        errorCount += 1
        if errorCount >= 5 {
            // You should decide on an acceptable threshold errors, dismiss the view when its reached
            // and resort to fallback options
            parkingViewController.dismiss(animated: true) {
                self.resultLabel.text = error.localizedDescription
                self.errorCount = 0
            }
        }
    }
}
