//
//  FMSimpleSessionViewController.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 06.10.21.
//

import Foundation
import UIKit

public protocol FMSimpleSessionViewControllerDelegate: AnyObject {
    func sessionViewController(_ sessionViewController: FMSimpleSessionViewController, localizationDidUpdateLocation result: FMLocationResult)
    func sessionViewController(_ sessionViewController: FMSimpleSessionViewController, localizationDidFailWithError error: Error, errorMetadata: Any?)
}

public final class FMSimpleSessionViewController: UIViewController {
    
    public weak var delegate: FMSimpleSessionViewControllerDelegate?
    
    private var topBar: UIView!
    
    private let topBarHeight: CGFloat = 44.0
    
    private var sessionViewController: FMSessionViewController!
    
    override init(nibName: String?, bundle: Bundle?) {
        super.init(nibName: nibName, bundle: bundle)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        modalPresentationStyle = .fullScreen
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
                
        sessionViewController = FMSessionViewController()
        sessionViewController.registerLocalizingViewController(FMSimpleLocalizingViewController.self)
        sessionViewController.registerQRScanningViewController(FMSimpleQRScanningViewController.self)
        sessionViewController.delegate = self
                
        addChild(sessionViewController)
        view.addSubview(sessionViewController.view)
        sessionViewController.willMove(toParent: self)
        
        topBar = UIView()
        topBar.backgroundColor = .blue
        view.addSubview(topBar)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let bounds = self.view.bounds
        
        var topBarRect = CGRect.zero
        topBarRect.size.width = bounds.width
        topBarRect.size.height = topBarHeight
        
        var sessionViewRect = bounds
        sessionViewRect.origin.y = topBarHeight
        sessionViewRect.size.height -= topBarHeight
        sessionViewController.view.frame = sessionViewRect
    }
    
    public func start() {
        sessionViewController.startQRScanning()
    }
}

extension FMSimpleSessionViewController: FMSessionViewControllerDelegate {
    public func sessionViewController(_ sessionViewController: FMSessionViewController, didDetectQRCodeFeature qrCodeFeature: CIQRCodeFeature) {
        
    }
    
    public func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidUpdateLocation result: FMLocationResult) {
        
    }
    
    public func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidRequestBehavior behavior: FMBehaviorRequest) {
        
    }
    
    public func sessionViewController(_ sessionViewController: FMSessionViewController, localizationDidFailWithError error: Error, errorMetadata: Any?) {
        
    }
}
