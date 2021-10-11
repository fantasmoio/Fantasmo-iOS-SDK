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
        // parkingViewController.isSimulation = true
        // parkingViewController.simulationZone = .parking
        
        // Show useful debug info
        // parkingViewController.showsStatistics = true
        
        self.present(parkingViewController, animated: true)
    }
}

extension ParkingExampleViewController: FMParkingViewControllerDelegate {
    /**
     Called when a QR code is scanned in the parking view. This method can be used to perform optional validation of the QR code
     before continuing to localization.

     - Parameter parkingViewController: the `FMParkingViewController` instance in which the QR code was scanned.
     - Parameter qrCode: the scanned QR code as `CIQRCodeFeature`
     - Parameter continueBlock: a block to be called with a boolean value indicating whether or not to continue to localization.
          
     If you implement this method, you *must* eventually call the `continueBlock` with a boolean value. A value of `true` indicates
     the code is valid and that localization should begin. Passing `false` to this block indicates the code is invalid and instructs
     the parking view to scan for more QR codes. This block can be called synchronously or asynchronously and must be done so on the
     main queue. The default implementation of this method does nothing and will start localizing after any QR code is detected.
     */
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void)) {
        // Validate the code here
        let isValidCode = qrCode.messageString != nil
        continueBlock(isValidCode)
        // Note: Validation can also be done asynchronously.
        //
        // WebService.validateQRCode { isValidCode in
        //     continueBlock(isValidCode)
        // }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {
        // Got a localization result.
        // Localization will continue until the view is dismissed.
        // You should decide on acceptable criteria for the result success.
        // One way to measure the quality of the result is with the `confidence` vale.
        if result.confidence != .low {
            // Got a result with Medium or better confidence, dismiss to stop localizing.
            parkingViewController.dismiss(animated: true) {
                let coordinate = result.location.coordinate
                self.resultLabel.text = "Coordinates: \(coordinate.latitude), \(coordinate.longitude)\n\nConfidence: \(result.confidence)"
                self.errorCount = 0
            }
        }
    }
    
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?) {
        // A localization error occurred.
        if (error.type as? FMLocationError) == FMLocationError.accessDenied {
            return  // User denied access to location, handle accordingly.
        }
        // Localization will continue until the view is dismissed.
        // You should decide on an acceptable threshold for errors and dismiss the view when it's reached.
        errorCount += 1
        if errorCount >= 55 {
            // Too many errors, dismiss to stop localizing.
            parkingViewController.dismiss(animated: true) {
                self.resultLabel.text = error.localizedDescription
                self.errorCount = 0
                // Resort to fallback options.
            }
        }
    }
}
