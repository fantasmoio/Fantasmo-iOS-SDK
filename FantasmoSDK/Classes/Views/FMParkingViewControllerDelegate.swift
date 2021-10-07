//
//  FMParkingViewControllerDelegate.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 07.10.21.
//

import Foundation
import CoreImage

public protocol FMParkingViewControllerDelegate: AnyObject {
    func parkingViewControllerDidStartQRScanning(_ parkingViewController: FMParkingViewController)
    func parkingViewControllerDidStopQRScanning(_ parkingViewController: FMParkingViewController)
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void))
    func parkingViewControllerDidStartLocalizing(_ parkingViewController: FMParkingViewController)
    func parkingViewControllerDidStopLocalizing(_ parkingViewController: FMParkingViewController)
    func parkingViewController(_ parkingViewController: FMParkingViewController, didRequestLocalizationBehavior behavior: FMBehaviorRequest)
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult)
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?)
}

// Default implementation, makes these methods optional.
public extension FMParkingViewControllerDelegate {
    func parkingViewControllerDidStartQRScanning(_ parkingViewController: FMParkingViewController) {}
    func parkingViewControllerDidStopQRScanning(_ parkingViewController: FMParkingViewController) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void)) {
        continueBlock(true) // Default behavior, continue immediately to localization.
    }
    func parkingViewControllerDidStartLocalizing(_ parkingViewController: FMParkingViewController) {}
    func parkingViewControllerDidStopLocalizing(_ parkingViewController: FMParkingViewController) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didRequestLocalizationBehavior behavior: FMBehaviorRequest) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: Error, errorMetadata: Any?) {}
}
