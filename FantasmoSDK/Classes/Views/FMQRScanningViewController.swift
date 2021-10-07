//
//  FMQRScanningViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit

public class FMQRScanningViewController: UIViewController {
        
    var label: FMTipLabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.5)
        
        label = FMTipLabel()
        label.setText("Scan QR Code")
        view.addSubview(label)
    }
        
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let layer = self.view.layer
        let bounds = self.view.bounds
        
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
        labelRect.origin.y = cutoutRect.minY - labelRect.height - 40.0
        label.frame = labelRect
    }
}

extension FMQRScanningViewController: FMQRScanningViewControllerProtocol {
}
