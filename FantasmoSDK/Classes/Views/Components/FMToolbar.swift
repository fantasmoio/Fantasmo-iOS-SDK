//
//  FMToolbar.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 12.10.21.
//

import Foundation
import UIKit

class FMToolbar: UIView {
    
    public static let tintColor: UIColor = .white
    public static let height: CGFloat = 50.0
    public static let fontSize: CGFloat = 14.0
    public static let buttonInsetX: CGFloat = 30.0
    public static let buttonTouchAreaPadding = UIEdgeInsets.init(top: 20.0, left: 20.0, bottom: 20.0, right: 20.0)
    
    public private(set) var titleLabel: UILabel!
    public private(set) var closeButton: UIButton!
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    var title: String = "" {
        didSet {
            titleLabel.text = title
            titleLabel.sizeToFit()
            setNeedsLayout()
        }
    }
    
    private func configure() {
        backgroundColor = .clear
                        
        titleLabel = UILabel()
        titleLabel.text = self.title
        titleLabel.font = UIFont.systemFont(ofSize: FMToolbar.fontSize)
        titleLabel.textColor = FMToolbar.tintColor
        titleLabel.numberOfLines = 1
        titleLabel.textAlignment = .center
        titleLabel.backgroundColor = .clear
        addSubview(titleLabel)
        
        let closeImage = UIImage(named: "btn-close", in:Bundle(for: FMToolbar.self), compatibleWith: nil)!
        closeButton = UIButton()
        closeButton.setImage(closeImage, for: .normal)
        closeButton.tintColor = FMToolbar.tintColor
        closeButton.contentEdgeInsets = FMToolbar.buttonTouchAreaPadding
        closeButton.sizeToFit()
        addSubview(closeButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bounds = self.bounds
        
        var closeRect = closeButton.frame
        closeRect.origin.x = bounds.maxX - 0.5 * closeRect.width - FMToolbar.buttonInsetX
        closeRect.origin.y = bounds.midY - 0.5 * closeRect.height
        closeButton.frame = closeRect
        
        var textRect = titleLabel.frame
        let edgeInsetX = bounds.maxX - closeRect.minX
        textRect.origin.x = edgeInsetX
        textRect.origin.y = bounds.midY - 0.5 * textRect.height
        textRect.size.width = bounds.width - 2.0 * edgeInsetX
        titleLabel.frame = textRect
    }
}
