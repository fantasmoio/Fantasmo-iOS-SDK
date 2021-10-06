//
//  FMQRScanningViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 06.10.21.
//

import Foundation
import CoreImage
import UIKit

public protocol FMQRScanningViewController: UIViewController {
    func didDetectQRCodeFeature(_ qrCodeFeature: CIQRCodeFeature)
}
