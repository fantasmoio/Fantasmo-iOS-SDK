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
     - Parameter scale: Scale of image.
     - Parameter deviceOrientation: Current orientation of device.
     */
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
    
    /**
     Convert to a jpeg inside an Autorelease Pool to memory performance
     
     - Parameter compressionQuality:  Compression quality of the image .
     - Returns: NSData of after compress image
     */
    func toJpeg(compressionQuality: CGFloat) -> Data? {
        return autoreleasepool(invoking: { () -> Data? in
            return self.jpegData(compressionQuality: compressionQuality)
        })
    }
    
    
    func pixelBuffer() -> CVPixelBuffer? {
        let width = self.size.width
        let height = self.size.height
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                        kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                            Int(width),
                                            Int(height),
                                            kCVPixelFormatType_32ARGB,
                                            attrs,
                                            &pixelBuffer)

        guard let resultPixelBuffer = pixelBuffer, status == kCVReturnSuccess else {
            return nil
        }

        CVPixelBufferLockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(resultPixelBuffer)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                        width: Int(width),
                                        height: Int(height),
                                        bitsPerComponent: 8,
                                        bytesPerRow: CVPixelBufferGetBytesPerRow(resultPixelBuffer),
                                        space: rgbColorSpace,
                                        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
                                        return nil
        }

        context.translateBy(x: 0, y: height)
        context.scaleBy(x: 1.0, y: -1.0)

        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(resultPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

        return resultPixelBuffer
    }
}
