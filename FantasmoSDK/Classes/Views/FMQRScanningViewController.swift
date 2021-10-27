//
//  FMQRScanningViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit

public class FMQRScanningViewController: UIViewController {
        
    var label: FMTipLabel!

    var toolbar: FMToolbar!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
                
        label = FMTipLabel()
        label.setText("Scan QR Code")
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
        
        let layer = self.view.layer
        let bounds = self.view.bounds
        let safeAreaBounds = self.view.safeAreaLayoutGuide.layoutFrame
        
        var toolbarRect = toolbar.frame
        toolbarRect.origin.y = safeAreaBounds.origin.y
        toolbarRect.size.width = safeAreaBounds.width
        toolbarRect.size.height = FMToolbar.height
        toolbar.frame = toolbarRect
        
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        layer.mask = maskLayer
        
        let cutoutSize = min(300.0, bounds.size.width - 80.0)
        var cutoutRect = CGRect.zero
        cutoutRect.size = CGSize(width: cutoutSize, height: cutoutSize)
        cutoutRect.origin.x = floor(0.5 * (bounds.width - cutoutSize))
        cutoutRect.origin.y = floor(0.5 * (bounds.height - cutoutSize))
        
        let cutoutPath = UIBezierPath(rect: cutoutRect)
        let path = CGMutablePath()
        path.addRect(bounds)
        path.addPath(cutoutPath.cgPath)
        
        maskLayer.backgroundColor = UIColor.clear.cgColor
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path
        layer.mask = maskLayer
        
        let labelMaxSize = CGSize(width: cutoutSize, height: bounds.height - cutoutRect.minY)
        var labelRect = CGRect.zero
        labelRect.size = label.sizeThatFits(labelMaxSize)
        labelRect.origin.x = cutoutRect.midX - 0.5 * labelRect.width
        
        let labelAreaHeight = (bounds.midY - 0.5 * cutoutSize) - toolbarRect.maxY
        labelRect.origin.y = toolbarRect.maxY + 0.5 * labelAreaHeight - 0.5 * labelRect.height
        label.frame = labelRect
    }
}

extension FMQRScanningViewController: FMQRScanningViewControllerProtocol {
}
