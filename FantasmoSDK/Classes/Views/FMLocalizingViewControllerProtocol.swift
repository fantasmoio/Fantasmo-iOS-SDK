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
    func didReceiveLocalizationError(_ error: Error, errorMetadata: Any?)
}

// Default implementation, makes these methods optional.
extension FMLocalizingViewControllerProtocol {
    public func didStartLocalizing() {}
    public func didStopLocalizing() {}
    public func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest) {}
    public func didReceiveLocalizationResult(_ result: FMLocationResult) {}
    public func didReceiveLocalizationError(_ error: Error, errorMetadata: Any?) {}
}
