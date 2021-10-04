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
        fmSessionViewController.modalPresentationStyle = .fullScreen
        fmSessionViewController.isSimulation = true
        fmSessionViewController.simulationZone = .parking
        fmSessionViewController.logLevel = .debug
        fmSessionViewController.delegate = self
        fmSessionViewController.startQRScanning()
        self.present(fmSessionViewController, animated: false)
    }
}

extension ViewController: FMSessionViewControllerDelegate {
    func sessionViewController(_ sessionViewController: FMSessionViewController, didDetectQRCodeFeature qrCodeFeature: CIQRCodeFeature) {
        print("didDetectQRCodeFeature: \(qrCodeFeature.messageString ?? "")")
        sessionViewController.stopQRScanning()
        sessionViewController.startLocalizing(sessionId: UUID().uuidString)
    }

    func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidUpdateLocation result: FMLocationResult) {
        print("localizationDidUpdateLocation: \(result)")
    }
    
    func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidRequestBehavior behavior: FMBehaviorRequest) {
        print("localizationDidRequestBehavior: \(behavior.rawValue)")
    }
    
    func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidFailWithError error: Error, errorMetadata: Any?) {
        print("localizationDidFailWithError: \(error.localizedDescription)")
    }
}
