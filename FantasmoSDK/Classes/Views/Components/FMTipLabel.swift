//
//  FMTipLabel.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 30.09.21.
//

import Foundation
import UIKit

class FMTipLabel: UIView {
    
    private var label: UILabel!
    private let color: UIColor = .init(white: 0.0, alpha: 0.65)
    private let paddingX: CGFloat = 21.0
    private let paddingY: CGFloat = 12.0
    private let cornerRadius: CGFloat = 10.0
    private let fontSize: CGFloat = 18.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }
    
    private func configure() {
        backgroundColor = color
        
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        
        label = UILabel()
        label.font = UIFont.systemFont(ofSize: fontSize)
        label.backgroundColor = .clear
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.sizeToFit()
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds.insetBy(dx: paddingX, dy: paddingY)
    }
    
    func setText(_ text: String) {
        label.text = text
        setNeedsLayout()
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let textSize = label.sizeThatFits(size)
        return CGSize(
            width: textSize.width + 2.0 * paddingX,
            height: textSize.height + 2.0 * paddingY
        )
    }
}
