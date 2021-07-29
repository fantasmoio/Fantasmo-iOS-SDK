//
//  ARFrame+Extension.swift
//  Fantasmo-iOS-SDK-Test-Harness
//
//  Created by lucas kuzma on 3/18/21.
//

import ARKit


extension ARFrame {
    
    /// Default pixel buffer resolution and plane count for ARFrames.
    private static let pixelBufferWidth: Int = 1920
    private static let pixelBufferHeight: Int = 1440
    private static let pixelBufferPlaneCount: Int = 2
    
    /// Encode to a JPEG. The pixel buffer is assummed to be coming from
    /// an ARFrame which has a default resolution and plane count. The method
    /// will need to be refactored to other resolutions.
    ///
    /// - Parameters:
    ///   - scaleFactor:
    ///   - deviceOrientation: Rotate based on orientation.
    /// - Returns: Encoded JPEG image.
    func toJpeg(withCompression compression: Float, scaleFactor: Float, deviceOrientation: UIDeviceOrientation) -> Data? {
        
        let pixelBufferHeight = CVPixelBufferGetHeight(capturedImage)
        let pixelBufferWidth = CVPixelBufferGetWidth(capturedImage)
        let pixelBufferPlaneCount = CVPixelBufferGetPlaneCount(capturedImage)
        
        if( (pixelBufferHeight != pixelBufferHeight) ||
                (pixelBufferWidth != pixelBufferWidth) ||
                (pixelBufferPlaneCount != pixelBufferPlaneCount)) {
            return nil
        }
        
        if let uiImage = UIImage(pixelBuffer: capturedImage,
                                 scaleFactor: scaleFactor,
                                 deviceOrientation: deviceOrientation) {
            if let jpegData = uiImage.toJpeg(compressionQuality: compression) {
                return jpegData
            } else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
}
