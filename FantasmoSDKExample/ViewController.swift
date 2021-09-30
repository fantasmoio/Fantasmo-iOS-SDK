//
//  ViewController.swift
//  FantasmoSDKExample
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit
import FantasmoSDK

class ViewController: UIViewController {
    
    @IBAction func handleEndRideButton(_ sender: UIButton) {
        guard self.presentedViewController == nil else {
            return
        }
        
        let fmSessionViewController = FMSessionViewController()
        fmSessionViewController.modalTransitionStyle = .crossDissolve
        fmSessionViewController.modalPresentationStyle = .fullScreen
        fmSessionViewController.delegate = self
        fmSessionViewController.startQRScanning()
        self.present(fmSessionViewController, animated: false)
    }
}

extension ViewController: FMSessionViewControllerDelegate {
    func sessionViewController(_ sessionViewController: FMSessionViewController, didDetectQRCodeFeature qrCodeFeature: CIQRCodeFeature) {
        if let message = qrCodeFeature.messageString {
            print("got qr code: \(message)")
            sessionViewController.stopQRScanning()
            sessionViewController.startLocalizing()
        }
    }
}
