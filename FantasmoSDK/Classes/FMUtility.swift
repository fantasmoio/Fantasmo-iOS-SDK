//
//  FMUtility.swift
//  FantasmoSDK
//

import Foundation
import UIKit

/// Utility class for Fantasmo SDK.
open class FMUtility {

    // MARK: - Public static methods
    
    
    /// Encode to a JPEG. The pixel buffer is assummed to be coming from
    /// an ARFrame which has a default resolution and plane count. The method
    /// will need to be refactored to other resolutions.
    ///
    /// - Parameters:
    ///   - pixelBuffer: Pixel buffer to encode.
    ///   - deviceOrientation: Rotate based on orientation.
    /// - Returns: Encoded JPEG image.
    public static func toJpeg(pixelBuffer: CVPixelBuffer,
                              with deviceOrientation: UIDeviceOrientation) -> Data? {
        
        let pixelBufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        let pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let pixelBufferPlaneCount = CVPixelBufferGetPlaneCount(pixelBuffer)
        
        if( (pixelBufferHeight != Constants.PixelBufferHeight) ||
                (pixelBufferWidth != Constants.PixelBufferWidth) ||
                (pixelBufferPlaneCount != Constants.PixelBufferPlaneCount)) {
            return nil
        }
        
        if let uiImage = UIImage(pixelBuffer: pixelBuffer,
                                 scale: Constants.ImageScaleFactor,
                                 deviceOrientation: deviceOrientation) {
            if let jpegData = uiImage.toJpeg(compressionQuality: Constants.JpegCompressionRatio) {
                return jpegData
            } else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    public struct Constants {
        
        /// Compression factor of JPEG encoding, range 0.0 (worse) to 1.0 (best).
        /// Anything below 0.7 severely degrades localization recall and accuracy.
        public static let JpegCompressionRatio: CGFloat = 0.9
        
        /// Scale factor when encoding an image to JPEG.
        public static let ImageScaleFactor: CGFloat = 2.0/3.0
        
        /// Default pixel buffer resolution and plane count for ARFrames.
        public static let PixelBufferWidth: Int = 1920
        public static let PixelBufferHeight: Int = 1440
        public static let PixelBufferPlaneCount: Int = 2
    }
}
