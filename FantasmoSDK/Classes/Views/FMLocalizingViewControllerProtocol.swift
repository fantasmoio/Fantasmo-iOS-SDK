//
//  FMLocalizingViewControllerProtocol.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 07.10.21.
//

import Foundation
import UIKit

public protocol FMLocalizingViewControllerProtocol: UIViewController {
    func didStartLocalizing()
    func didStopLocalizing()
    func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest)
    func didReceiveLocalizationResult(_ result: FMLocationResult)
    func didReceiveLocalizationError(_ error: FMError, errorMetadata: Any?)
}

// Default implementation, makes these methods optional.
public extension FMLocalizingViewControllerProtocol {
    func didStartLocalizing() {}
    func didStopLocalizing() {}
    func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest) {}
    func didReceiveLocalizationResult(_ result: FMLocationResult) {}
    func didReceiveLocalizationError(_ error: FMError, errorMetadata: Any?) {}
}
