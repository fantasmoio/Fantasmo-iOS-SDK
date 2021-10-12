//
//  FMLocalizingViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit

public class FMLocalizingViewController: UIViewController {
    
    var label: FMTipLabel!
    
    var toolbar: FMToolbar!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        
        label = FMTipLabel()
        label.alpha = 0
        label.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        view.addSubview(label)
        
        toolbar = FMToolbar()
        toolbar.title = "VERIFY PARKING"
        toolbar.closeButton.addTarget(self, action: #selector(handleCloseButton(_:)), for: .touchUpInside)
        view.addSubview(toolbar)
    }

    @objc private func handleCloseButton(_ sender: UIButton) {
        guard let parkingViewController = self.parent as? FMParkingViewController else {
            return
        }
        parkingViewController.dismiss(animated: true, completion: nil)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        let safeAreaBounds = self.view.safeAreaLayoutGuide.layoutFrame
        
        var toolbarRect = toolbar.frame
        toolbarRect.origin.y = safeAreaBounds.origin.y
        toolbarRect.size.width = safeAreaBounds.width
        toolbarRect.size.height = FMToolbar.height
        toolbar.frame = toolbarRect

        let labelMaxSize = CGSize(width: 300.0, height: bounds.height)
        var labelRect = CGRect.zero
        labelRect.size = label.sizeThatFits(labelMaxSize)
        labelRect.origin.x = bounds.midX - 0.5 * labelRect.width
        
        let qrCutoutSize = min(300.0, bounds.size.width - 80.0)
        let labelAreaHeight = (bounds.midY - 0.5 * qrCutoutSize) - toolbarRect.maxY
        labelRect.origin.y = toolbarRect.maxY + 0.5 * labelAreaHeight - 0.5 * labelRect.height
        label.frame = labelRect
    }
        
    private func showBehaviorText(_ behaviorText: String) {
        UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve) {
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
