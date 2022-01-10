//
//  FMParkingViewControllerDelegate.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 07.10.21.
//

import Foundation
import CoreImage

public protocol FMParkingViewControllerDelegate: AnyObject {

    /// Called when QR scanning has started and the registered `FMQRScanningViewControllerProtocol` is presented.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    func parkingViewControllerDidStartQRScanning(_ parkingViewController: FMParkingViewController)

    /// Called when QR scanning has stopped, just before the registered `QRScanningViewControllerProtocol` is dismissed.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    func parkingViewControllerDidStopQRScanning(_ parkingViewController: FMParkingViewController)

    /// Called when a QR code is scanned.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    /// - Parameter qrCode: the scanned QR code as `CIQRCodeFeature`
    /// - Parameter continueBlock: a block to be called with a boolean value indicating whether or not to continue to localization
    ///
    /// This method can be used to perform optional validation of the QR code and decide if localization should start.
    /// If you implement this method, you *must* eventually call the `continueBlock` with a boolean value. A value of `true` indicates
    /// the code scanned is valid and that localization should start. Passing `false` to this block indicates the code is invalid and
    /// will allow the user to scan, or manually enter another code. This block may be called synchronously or asynchronously but must
    /// be done so on the main queue. The default implementation does no validation and simply calls `continueBlock(true)`.
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void))

    /// Called when a QR code is manually entered via `enterQRCode(string:)`.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    /// - Parameter qrCodeString: the manually entered QR code string
    /// - Parameter continueBlock: a block to be called with a boolean value indicating whether or not to continue to localization
    ///
    /// This method can be used to perform optional validation of the QR code string and decide if localization should start.
    /// If you implement this method, you *must* eventually call the `continueBlock` with a boolean value. A value of `true` indicates
    /// the code entered is valid and that localization should start. Passing `false` to this block indicates the code is invalid and
    /// will allow the user to scan, or manually enter another code. This block may be called synchronously or asynchronously but must
    /// be done so on the main queue. The default implementation does no validation and simply calls `continueBlock(true)`.
    func parkingViewController(_ parkingViewController: FMParkingViewController, didEnterQRCodeString qrCodeString: String, continueBlock: @escaping ((Bool) -> Void))
    
    /// Called when localization has started and the registered `FMLocalizingViewControllerProtocol` is presented.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    func parkingViewControllerDidStartLocalizing(_ parkingViewController: FMParkingViewController)

    /// Called with a corrective behavior request that is intended to be displayed to the user.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    /// - Parameter behavior: the requested user behavior
    ///
    /// This method is called to inform the user what they should be doing with their device in order to localize properly. For example
    /// if the users device is aimed at the ground, you may receive the `FMBehaviorRequest.tiltUp` request. You should use this method
    /// to display any and all behavior requests to the user. For English, the string value in `behavior.description` should be used.
    func parkingViewController(_ parkingViewController: FMParkingViewController, didRequestLocalizationBehavior behavior: FMBehaviorRequest)

    /// Called any time a localization result is received. Localization is not stopped.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    /// - Parameter result: the localization result containing the parking `coordinate` and a `confidence` value.
    ///
    /// This method may be called multiple times with multiple results during localization. It is up to you to decide whether or not a result
    /// is acceptable. As one option, you could check the `result.confidence` value. When you're satisfied with the result you should dismiss
    /// the `parkingViewController` instance to stop localizing.
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult)

    ///  Called any time a localization error is received. Localization is not stopped.
    ///
    /// - Parameter parkingViewController: the `FMParkingViewController` instance
    /// - Parameter error: the localization error
    /// - Parameter errorMetadata: optional additional information about the error
    ///
    /// This method may be called multiple times with multiple errors during localization. The localization process is not stopped however and
    /// it is still possible to receive a successful localization result. You should determine an acceptable threshold for errors and dismiss
    /// the `parkingViewController` when that threshold is reached and resort to fallback options.
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?)
}

/// Default implementations, makes these methods optional.
public extension FMParkingViewControllerDelegate {
    func parkingViewControllerDidStartQRScanning(_ parkingViewController: FMParkingViewController) {}
    func parkingViewControllerDidStopQRScanning(_ parkingViewController: FMParkingViewController) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didScanQRCode qrCode: CIQRCodeFeature, continueBlock: @escaping ((Bool) -> Void)) {
        continueBlock(true) /// Default behavior, continues to localization without validating the code
    }
    func parkingViewController(_ parkingViewController: FMParkingViewController, didEnterQRCodeString qrCodeString: String, continueBlock: @escaping ((Bool) -> Void)) {
        continueBlock(true) /// Default behavior, continues to localization without validating the code
    }
    func parkingViewControllerDidStartLocalizing(_ parkingViewController: FMParkingViewController) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didRequestLocalizationBehavior behavior: FMBehaviorRequest) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationResult result: FMLocationResult) {}
    func parkingViewController(_ parkingViewController: FMParkingViewController, didReceiveLocalizationError error: FMError, errorMetadata: Any?) {}
}
