//
//  FMUtility.swift
//  FantasmoSDK
//

import Foundation

open class FMUtility {
    // MARK: - Public static methods
    public func convertToJpeg(fromPixelBuffer pixelBuffer: CVPixelBuffer, withDeviceOrientation deviceOrientation: UIDeviceOrientation) -> Data? {
        
        let pixelBufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        let pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let pixelBufferPlaneCount = CVPixelBufferGetPlaneCount(pixelBuffer)
        
        if( (pixelBufferHeight != Constants.PixelBufferHeight) ||
                (pixelBufferWidth != Constants.PixelBufferWidth) ||
                (pixelBufferPlaneCount != Constants.PixelBufferPlaneCount)) {
            return nil
        }
        
        if let uiImage = UIImage(pixelBuffer: pixelBuffer, scale: Constants.ImageScaleFactor, deviceOrientation: deviceOrientation) {
            if let jpegData = uiImage.toJpeg(compressionQuality: Constants.JpegCompressionRatio){
                return jpegData
            } else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    public enum Constants {
        public static let JpegCompressionRatio: CGFloat = 0.9
        public static let ImageScaleFactor: CGFloat = 2.0/3.0
        public static let PixelBufferWidth: Int = 1920
        public static let PixelBufferHeight: Int = 1440
        public static let PixelBufferPlaneCount: Int = 2
    }
}
