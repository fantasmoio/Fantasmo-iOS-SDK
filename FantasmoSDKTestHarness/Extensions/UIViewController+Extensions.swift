//
//  UIViewController+Extensions.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 01.11.21.
//

import Foundation
import UIKit

extension UIViewController {
    
    func showAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message ?? "", preferredStyle: .alert)
        alert.addAction(.init(title: "Dismiss", style: .cancel, handler: { _ in }))
        self.present(alert, animated: true)
    }
    
    func showOpenSettingsAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let openSettingsAction = UIAlertAction(title: "Open Settings", style: .default, handler: { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        alert.addAction(openSettingsAction)
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        alert.preferredAction = openSettingsAction
        self.present(alert, animated: true)
    }
}
