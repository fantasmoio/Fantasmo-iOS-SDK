//
//  ImageEncoder.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 15.11.21.
//

import UIKit
import ARKit
import CoreImage
import CoreVideo

class ImageEncoder {
    
    /// Largest single image output dimension, orientation agnostic
    let largestSingleOutputDimension: CGFloat
    /// Reusable image renderer, renders the output image preserving aspect ratio
    var imageRenderer: UIGraphicsImageRenderer?
    /// The output size the current `imageRenderer` was configured with
    var imageRendererOutputSize: CGSize = .zero
    /// Reusable CoreImage context
    let ciContext: CIContext
    
    init(largestSingleOutputDimension: CGFloat) {
        self.largestSingleOutputDimension = largestSingleOutputDimension
        self.ciContext = CIContext(options: [.highQualityDownsample: true, .priorityRequestLow: true])
    }
    
    func jpegData(from arFrame: ARFrame, compressionQuality: CGFloat = 0.9) -> Data? {
        let ciImage = CIImage(cvPixelBuffer: arFrame.capturedImage)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            log.error("Unable to create CGImage from CVPixelBuffer!")
            return nil
        }
        
        let imageOrientation: UIImage.Orientation
        switch arFrame.deviceOrientation {
        case .landscapeLeft:
            imageOrientation = .up
        case .landscapeRight:
            imageOrientation = .down
        case .portrait:
            imageOrientation = .right
        case .portraitUpsideDown:
            imageOrientation = .left
        default:
            imageOrientation = .right
        }
        
        // Create a UIImage with the device orientation of the ARFrame.
        let image = UIImage(cgImage: cgImage, scale: 1.0, orientation: imageOrientation)
        
        // Check if we need to resize the image.
        if max(image.size.width, image.size.height) <= largestSingleOutputDimension {
            // The image is smaller than or equal to the desired size, we don't need to resize it.
            return image.jpegData(compressionQuality: compressionQuality)
            // Note: The resulting orientation of bytes from this API is unchanged from the CVPixelBuffer.
            // The JPEG / Exif Orientation flag is set to match the `imageOrientation`.
        }
        
        // The image is bigger than the desired size, calculate the new smaller size keeping the aspect ratio.
        var newSize = CGSize.zero
        if image.size.width > image.size.height {
            newSize.width = largestSingleOutputDimension
            newSize.height = largestSingleOutputDimension * image.size.height / image.size.width
        } else {
            newSize.height = largestSingleOutputDimension
            newSize.width = largestSingleOutputDimension * image.size.width / image.size.height
        }
        
        // Create a new image renderer if we haven't already, or if the output size has changed.
        if imageRenderer == nil || imageRendererOutputSize != newSize {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            imageRenderer = UIGraphicsImageRenderer(size: newSize, format: format)
            imageRendererOutputSize = newSize
        }

        // Resize the image
        let jpegData = imageRenderer?.jpegData(withCompressionQuality: compressionQuality) { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
            // Note: The resulting orientation of bytes from this API is changed to match the `imageOrientation`.
            // The JPEG / Exif Orientation flag is set to Top-Left.
        }
        
        return jpegData
    }
}
