//
//  FMImageButton.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 11.01.22.
//

import UIKit

/// Button with image centered on top and title below
class FMImageButton: UIButton {
    
    let titleMaxWidth = 200.0
    let titlePadding = 3.0
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let titleMaxSize = CGSize(width: titleMaxWidth, height: .greatestFiniteMagnitude)
        guard let imageSize = imageView?.image?.size, imageSize != .zero,
              let titleSize = titleLabel?.sizeThatFits(titleMaxSize)
        else {
            return super.sizeThatFits(size)
        }
        let horiztonalInsets = contentEdgeInsets.left + contentEdgeInsets.right
        let verticalInsets = contentEdgeInsets.top + contentEdgeInsets.bottom
        return CGSize(
            width: max(imageSize.width, titleSize.width) + horiztonalInsets,
            height: imageSize.height + titleSize.height + verticalInsets + titlePadding
        )
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        titleLabel?.textAlignment = .center
        titleLabel?.numberOfLines = 0
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        guard var imageRect = imageView?.frame, imageRect.size != .zero, var titleRect = titleLabel?.frame else {
            return
        }
        
        let contentRect = bounds.inset(by: self.contentEdgeInsets)
        
        imageRect.origin.x = contentRect.midX - 0.5 * imageRect.width
        imageRect.origin.y = contentRect.minY
        imageView?.frame = imageRect
        
        titleRect.origin.x = contentRect.minX
        titleRect.origin.y = imageRect.maxY + titlePadding
        titleRect.size.width = contentRect.width
        titleRect.size.height = contentRect.height - imageRect.height - titlePadding
        titleLabel?.frame = titleRect
    }
}
