//
//  CGImage+Extension.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGImage {
    
    // Scale the image and preserve the aspect ratio.
    func scale(byFactor scale:CGFloat) -> CGImage? {
        
        guard let colorSpace = self.colorSpace else {
            print("No color space.")
            return nil
        }
        
        let width = CGFloat(self.width) * scale
        let height = CGFloat(self.height) * scale
        
        let context = CGContext(data: nil,
                                width: Int(width),
                                height: Int(height),
                                bitsPerComponent: self.bitsPerComponent,
                                bytesPerRow: self.bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: self.bitmapInfo.rawValue)
        
        guard let imageContext = context else {
            print("No context.")
            return nil
        }
        
        imageContext.interpolationQuality = .high
        imageContext.draw(self,
                          in: CGRect(origin: CGPoint.zero,
                                     size: CGSize(width: width, height: height)))
        
        return imageContext.makeImage()
    }
}
