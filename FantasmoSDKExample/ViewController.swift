//
//  ViewController.swift
//  FantasmoSDKExample
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit
import FantasmoSDK

class ViewController: UIViewController {
    
    weak var sessionViewController: FMSessionViewController!
    
    @IBOutlet var toggleModeButton: UIButton!
    @IBOutlet var toggleStatisticsButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sessionViewController.startLocalizing(sessionId: UUID().uuidString)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let sessionViewController = segue.destination as? FMSessionViewController else {
            return
        }
        sessionViewController.isSimulation = true
        sessionViewController.simulationZone = .parking
        sessionViewController.logLevel = .debug
        sessionViewController.delegate = self
        self.sessionViewController = sessionViewController
    }
        
    @IBAction func handleToggleStatisticsButton(_ sender: UIButton) {
        let showsStatistics = !sessionViewController.showsStatistics
        sessionViewController.showsStatistics = showsStatistics
        toggleStatisticsButton.isSelected = showsStatistics
    }
    
    @IBAction func handleToggleModeButton(_ sender: UIButton) {
        switch sessionViewController.state {
        case .localizing:
            sessionViewController.startQRScanning()
            toggleModeButton.setImage(UIImage(systemName: "location.viewfinder"), for: .normal)
        case .qrScanning:
            sessionViewController.startLocalizing(sessionId: UUID().uuidString)
            toggleModeButton.setImage(UIImage(systemName: "qrcode"), for: .normal)
        default:
            break
        }
    }
}

extension ViewController: FMSessionViewControllerDelegate {
    func sessionViewController(_ sessionViewController: FMSessionViewController, didDetectQRCodeFeature qrCodeFeature: CIQRCodeFeature) {
        print("didDetectQRCodeFeature: \(qrCodeFeature.messageString ?? "")")
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
