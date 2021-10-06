//
//  FMLocalizingViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 06.10.21.
//

import Foundation
import UIKit

public protocol FMLocalizingViewController: UIViewController {
    func didUpdateLocation(_ result: FMLocationResult)
    func didRequestBehavior(_ behavior: FMBehaviorRequest)
    func didFailWithError(_ error: Error, errorMetadata metadata: Any?)
}
