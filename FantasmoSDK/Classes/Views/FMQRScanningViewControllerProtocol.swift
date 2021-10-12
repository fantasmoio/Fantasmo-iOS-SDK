//
//  FMQRScanningViewControllerProtocol.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 07.10.21.
//

import Foundation
import UIKit
import CoreImage

public protocol FMQRScanningViewControllerProtocol: UIViewController {
    func didStartQRScanning()
    func didStopQRScanning()
    func didScanQRCode(_ qrCode: CIQRCodeFeature)
}

// Default implementation, makes these methods optional.
public extension FMQRScanningViewControllerProtocol {
    func didStartQRScanning() {}
    func didStopQRScanning() {}
    func didScanQRCode(_ qrCode: CIQRCodeFeature) {}
}
