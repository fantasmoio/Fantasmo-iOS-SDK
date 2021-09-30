//
//  FMLocalizingViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit

public protocol FMLocalizingViewControllerProtocol: UIViewController {
}

public class FMLocalizingViewController: UIViewController, FMLocalizingViewControllerProtocol {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.init(white: 1.0, alpha: 0.5)
    }
}
