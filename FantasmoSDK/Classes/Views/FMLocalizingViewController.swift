//
//  FMLocalizingViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit

public class FMLocalizingViewController: UIViewController {
    var label: FMTipLabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        
        label = FMTipLabel()
        label.setText("Point at stores, signs and buildings around you to get a precise location")
        view.addSubview(label)
    }
        
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        let labelMaxSize = CGSize(width: 300.0, height: bounds.height)
        var labelRect = CGRect.zero
        labelRect.size = label.sizeThatFits(labelMaxSize)
        labelRect.origin.x = bounds.midX - 0.5 * labelRect.width
        labelRect.origin.y = bounds.midY - 0.5 * labelRect.height
        label.frame = labelRect
    }
}

extension FMLocalizingViewController: FMLocalizingViewControllerProtocol {
    public func didReceiveLocalizationResult(_ result: FMLocationResult) {
        label.setText("Success")
        view.setNeedsLayout()
    }

    public func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest) {
        label.setText(behavior.rawValue)
        view.setNeedsLayout()
    }
    
    public func didReceiveLocalizationError(_ error: Error, errorMetadata: Any?) {
        label.setText(error.localizedDescription)
        view.setNeedsLayout()
    }
}
