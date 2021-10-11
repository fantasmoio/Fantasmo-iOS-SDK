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
        label.alpha = 0
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
        
    private func showBehaviorText(_ behaviorText: String) {
        UIView.transition(with: self.view, duration: 0.1, options: .transitionCrossDissolve) {
            self.label.setText(behaviorText)
            self.label.alpha = behaviorText.isEmpty ? 0 : 1
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        } completion: { _ in
        }
    }
}

extension FMLocalizingViewController: FMLocalizingViewControllerProtocol {
    public func didReceiveLocalizationResult(_ result: FMLocationResult) {
        showBehaviorText("")
        view.setNeedsLayout()
    }

    public func didRequestLocalizationBehavior(_ behavior: FMBehaviorRequest) {
        showBehaviorText(behavior.description)
        view.setNeedsLayout()
    }
    
    public func didReceiveLocalizationError(_ error: FMError, errorMetadata: Any?) {
        log.debug(parameters: ["error": error.localizedDescription])
    }
}
