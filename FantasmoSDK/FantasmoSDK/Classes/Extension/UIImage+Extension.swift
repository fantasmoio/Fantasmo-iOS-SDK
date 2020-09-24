//
//  UIImage+Extension.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import CoreImage
import CoreGraphics
import UIKit

extension UIImage {

    convenience init?(pixelBuffer: CVPixelBuffer, scale: CGFloat, deviceOrientation: UIDeviceOrientation) {
        
        // Convert to a CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let ciContext = CIContext(options: [CIContextOption.highQualityDownsample: true,
                                            CIContextOption.priorityRequestLow: true])
        
        guard var cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        if (abs(scale - 1.0) > 0.01) {
            guard let scaledImage = cgImage.scale(byFactor: scale) else {
                return nil
            }
            
            cgImage = scaledImage
        }

        switch deviceOrientation {
        case .portrait:
            self.init(cgImage: cgImage, scale: 1.0, orientation: .right)
            break
        case .portraitUpsideDown:
            self.init(cgImage: cgImage, scale: 1.0, orientation: .left)
            break
        case .landscapeLeft:
            self.init(cgImage: cgImage, scale: 1.0, orientation: .up)
            break
        case .landscapeRight:
            self.init(cgImage: cgImage, scale: 1.0, orientation: .down)
            break
        default:
            //default is portrait
            self.init(cgImage: cgImage, scale: 1.0, orientation: .right)
            break
        }
    }
    
    // Convert to a jpeg inside an Autorelease Pool to memory performance
    func toJpeg(compressionQuality: CGFloat) -> Data? {
        return autoreleasepool(invoking: { () -> Data? in
            return self.jpegData(compressionQuality: compressionQuality)
        })
    }
}
