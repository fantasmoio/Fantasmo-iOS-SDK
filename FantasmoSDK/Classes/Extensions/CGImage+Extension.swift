//
//  CGImage+Extension.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreGraphics

extension CGImage {
    
    /**
     Scale the image and preserve the aspect ratio
     
     - Parameter scale: The factor by which size of image should be scaled.
     - Returns: CGimage of image
     */
    func scale(byFactor scale: Float) -> CGImage? {
        
        guard let colorSpace = self.colorSpace else {
            log.warning("No color space.")
            return nil
        }
        
        let width = Float(self.width) * scale
        let height = Float(self.height) * scale
        
        let context = CGContext(data: nil,
                                width: Int(width),
                                height: Int(height),
                                bitsPerComponent: self.bitsPerComponent,
                                bytesPerRow: self.bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: self.bitmapInfo.rawValue)
        
        guard let imageContext = context else {
            log.warning("No context.")
            return nil
        }
        
        imageContext.interpolationQuality = .high
        let rect = CGRect(origin: CGPoint.zero, size: CGSize(width: width, height: height))
        imageContext.draw(self, in: rect)
        
        return imageContext.makeImage()
    }
}
