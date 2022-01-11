//
//  FMQRScanningViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 29.09.21.
//

import UIKit
import AVFoundation

public class FMQRScanningViewController: UIViewController {
        
    var label: FMTipLabel!

    var toolbar: FMToolbar!
    
    var manualEntryButton: UIButton!
    
    var torchButton: UIButton!
    
    var isTorchOn: Bool = false
            
    @objc func handleManualEntryButton(_ sender: UIButton) {
        guard let parkingViewController = self.parent as? FMParkingViewController else {
            return
        }
        
        let inputAlertControler = UIAlertController(title: "Enter QR Code", message: nil, preferredStyle: .alert)
        inputAlertControler.addTextField()
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            guard let qrCodeString = inputAlertControler.textFields?.first?.text else {
                return
            }
            parkingViewController.enterQRCode(string: qrCodeString)
        }
        inputAlertControler.addAction(submitAction)
        inputAlertControler.preferredAction = submitAction

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        inputAlertControler.addAction(cancelAction)
        
        present(inputAlertControler, animated: true)
    }
    
    @objc func handleCloseButton(_ sender: UIButton) {
        guard let parkingViewController = self.parent as? FMParkingViewController else {
            return
        }
        parkingViewController.dismiss(animated: true, completion: nil)
    }
        
    @objc func handleTorchButton(_ sender: UIButton) {
        toggleTorch(on: !isTorchOn)
    }
    
    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video), device.hasTorch else {
            return
        }
        do {
            try device.lockForConfiguration()
            device.torchMode = on ? .on : .off
            device.unlockForConfiguration()
            isTorchOn = on
        } catch {
            log.info("Torch cannot be used")
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        toggleTorch(on: false)
    }
        
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.init(white: 0.0, alpha: 0.6)
                
        label = FMTipLabel()
        label.setText("Scan QR Code")
        view.addSubview(label)
        
        toolbar = FMToolbar()
        toolbar.title = "VERIFY PARKING"
        toolbar.closeButton.addTarget(self, action: #selector(handleCloseButton(_:)), for: .touchUpInside)
        view.addSubview(toolbar)
        
        manualEntryButton = buttonWithTitle("Enter Code", systemImageName: "keyboard.fill")
        manualEntryButton.addTarget(self, action: #selector(handleManualEntryButton(_:)), for: .touchUpInside)
        view.addSubview(manualEntryButton)
        manualEntryButton.sizeToFit()

        torchButton = buttonWithTitle("Torch", systemImageName: "flashlight.on.fill")
        torchButton.addTarget(self, action: #selector(handleTorchButton(_:)), for: .touchUpInside)
        view.addSubview(torchButton)
        torchButton.sizeToFit()
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
        
        var manualEntryButtonRect = manualEntryButton.frame
        manualEntryButtonRect.origin.x = cutoutRect.maxX - manualEntryButtonRect.width
        manualEntryButtonRect.origin.y = safeAreaBounds.maxY - manualEntryButtonRect.height
        manualEntryButton.frame = manualEntryButtonRect

        var torchButtonRect = torchButton.frame
        torchButtonRect.origin.x = cutoutRect.minX
        torchButtonRect.origin.y = safeAreaBounds.maxY - torchButtonRect.height
        torchButton.frame = torchButtonRect
    }
    
    private func buttonWithTitle(_ buttonTitle: String, systemImageName: String) -> FMImageButton {
        let buttonRange = NSRange(location: 0, length: buttonTitle.count)
        let buttonTitleString = NSMutableAttributedString(string: buttonTitle)
        buttonTitleString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: buttonRange)
        buttonTitleString.addAttribute(.foregroundColor, value: UIColor.white.cgColor, range: buttonRange)
        buttonTitleString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14.0), range: buttonRange)

        let button = FMImageButton()
        button.setAttributedTitle(buttonTitleString, for: .normal)
        button.contentEdgeInsets = .init(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        button.tintColor = .white
        
        if #available(iOS 13.0, *) {
            button.setImage(UIImage(systemName: systemImageName), for: .normal)
        }
        
        return button
    }
}

extension FMQRScanningViewController: FMQRScanningViewControllerProtocol {
}
