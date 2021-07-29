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
    /**
     Init method of image
     
     - Parameter pixelBuffer: PixelBuffer of image.
     - Parameter scaleFactor: The scale factor by which the size of an image should be scaled.
     - Parameter deviceOrientation: Orientation of device with which image was captured.
     */
    convenience init?(pixelBuffer: CVPixelBuffer, scaleFactor: Float, deviceOrientation: UIDeviceOrientation) {
        
        // Convert to a CGImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let ciContext = CIContext(options: [CIContextOption.highQualityDownsample: true,
                                            CIContextOption.priorityRequestLow: true])
        
        guard var cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            return nil
        }
        
        if (abs(scaleFactor - 1.0) > 0.01) {
            guard let scaledImage = cgImage.scale(byFactor: scaleFactor) else {
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
            // default is portrait
            self.init(cgImage: cgImage, scale: 1.0, orientation: .right)
            break
        }
    }
    
    /**
     Convert to a jpeg inside an Autorelease Pool to memory performance
     
     - Parameter compressionQuality:  Compression quality of the image . Default value is '0.9'. 
     - Returns: NSData of after compress image
     */
    func toJpeg(compressionQuality: Float = Constants.jpegCompressionRatio) -> Data? {
        return autoreleasepool(invoking: { () -> Data? in
            return self.jpegData(compressionQuality: CGFloat(compressionQuality))
        })
    }
}
