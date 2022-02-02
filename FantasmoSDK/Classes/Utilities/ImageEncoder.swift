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
    
    /// Data structure containing encoded image data and resolution information
    struct Image {
        var data: Data
        var resolution: CGSize
        var originalResolution: CGSize
    }

    /// Largest single image output dimension, orientation agnostic
    let largestSingleOutputDimension: CGFloat
    /// The output compression quality, from 0.0 (worst) to 1.0 (best)
    let compressionQuality: CGFloat
    /// Reusable image renderer, renders the output image preserving aspect ratio
    var imageRenderer: UIGraphicsImageRenderer?
    /// The current configured output size of the `imageRenderer`
    var currentOutputSize: CGSize = .zero
    /// Reusable CoreImage context
    let ciContext: CIContext
    
    init(largestSingleOutputDimension: CGFloat, compressionQuality: CGFloat = 0.9) {
        self.largestSingleOutputDimension = largestSingleOutputDimension
        self.compressionQuality = compressionQuality
        self.ciContext = CIContext(options: [.highQualityDownsample: true, .priorityRequestLow: true])
    }
    
    func encodedImage(from frame: FMFrame) -> ImageEncoder.Image? {
        let ciImage = CIImage(cvPixelBuffer: frame.capturedImage)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else {
            log.error("error creating cgImage")
            return nil
        }
        
        let imageOrientation: UIImage.Orientation
        switch frame.deviceOrientation {
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
            // We don't need to resize, attempt to encode the original image to jpeg
            guard let jpegData = image.jpegData(compressionQuality: compressionQuality) else {
                log.error("error encoding jpeg")
                return nil
            }
            return Image(data: jpegData, resolution: image.size, originalResolution: image.size)
        }
        
        // We need to shrink the image, calculate the new size keeping the aspect ratio.
        var newSize = CGSize.zero
        if image.size.width > image.size.height {
            newSize.width = floor(largestSingleOutputDimension)
            newSize.height = floor(largestSingleOutputDimension * image.size.height / image.size.width)
        } else {
            newSize.height = floor(largestSingleOutputDimension)
            newSize.width = floor(largestSingleOutputDimension * image.size.width / image.size.height)
        }
        
        // Create a new image renderer if we haven't already, or if the output size has changed.
        if imageRenderer == nil || currentOutputSize != newSize {
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1.0
            format.opaque = true
            imageRenderer = UIGraphicsImageRenderer(size: newSize, format: format)
            currentOutputSize = newSize
        }

        // Attempt to resize and encode the image to jpeg.
        let jpegData = imageRenderer?.jpegData(withCompressionQuality: compressionQuality) { context in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        guard let jpegData = jpegData else {
            log.error("error resizing and encoding jpeg")
            return nil
        }
        
        return Image(data: jpegData, resolution: newSize, originalResolution: image.size)
    }
}
