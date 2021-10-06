//
//  EndRideViewController.swift
//  FantasmoSDKSimpleExample
//
//  Created by Nick Jensen on 06.10.21.
//

import UIKit
import FantasmoSDK

class EndRideViewController: UIViewController {
    
    @IBAction func handleEndRideButton(_ button: UIButton) {
        var simpleSessionViewController: FMSimpleSessionViewController!
        simpleSessionViewController = FMSimpleSessionViewController()
        simpleSessionViewController.delegate = self
        self.present(simpleSessionViewController, animated: true) {
            simpleSessionViewController.start()
        }
    }
}

extension EndRideViewController: FMSimpleSessionViewControllerDelegate {
    
    func sessionViewController(_ sessionViewController: FMSimpleSessionViewController, localizationDidUpdateLocation result: FMLocationResult) {
        let coordinate = result.location.coordinate
        print("Location: \(coordinate.latitude), \(coordinate.longitude)")
        print("Confidence: \(result.confidence.description)")
    }
    
    func sessionViewController(_ sessionViewController: FMSimpleSessionViewController, localizationDidFailWithError error: Error, errorMetadata: Any?) {
        print("Localiation Error: \(error.localizedDescription)")
    }
}
