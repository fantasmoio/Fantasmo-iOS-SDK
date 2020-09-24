//
//  TOSImage.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import UIKit
import Foundation
import ARKit
import CoreLocation

// Convert and format images into the TerraOS specification.
internal class FMImage:Codable {
    
    private enum Constants {
        public static let JpegCompressionRatio: CGFloat = 0.9
        public static let ImageScaleFactor: CGFloat = 2.0/3.0
        public static let PixelBufferWidth: Int = 1920
        public static let PixelBufferHeight: Int = 1440
        public static let PixelBufferPlaneCount: Int = 2
    }
    
    private var userId:String?
    private var timestamp:Double
    private var latitude:Double
    private var longitude:Double
    
    internal var uuid = UUID().uuidString
    internal var intrinsics:FMIntrinsics
    internal var pose:FMPose
    
    // Filename used for both the jpeg and metadata files
    public var filename:String {
        return String(format:"%.9f_%@", timestamp, uuid)
    }

    // MARK: - Initializers
    
    init(frame: ARFrame,
         withStatusBarOrientation currentStatusBarOrientation:UIInterfaceOrientation,
         withDeviceOrientation currentDeviceOrientation:UIDeviceOrientation,
         atLocation newLocation: CLLocationCoordinate2D?) {
        
        timestamp = (Date().timeIntervalSince1970 - ProcessInfo().systemUptime) + frame.timestamp
                
        pose = FMPose(fromTransform: frame.camera.transform)
        intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                   atScale: Float(FMImage.Constants.ImageScaleFactor),
                                   withStatusBarOrientation: currentStatusBarOrientation,
                                   withDeviceOrientation: currentDeviceOrientation,
                                   withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                   withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
        if let _location = newLocation {
            latitude = Double(_location.latitude)
            longitude = Double(_location.longitude)
        } else {
            latitude = 0.0
            longitude = 0.0
        }
    }
    
    // MARK: - Public static methods
    
    public static func convertToJpeg(fromPixelBuffer pixelBuffer: CVPixelBuffer, withDeviceOrientation deviceOrientation: UIDeviceOrientation) -> Data? {
        
        let pixelBufferHeight = CVPixelBufferGetHeight(pixelBuffer)
        let pixelBufferWidth = CVPixelBufferGetWidth(pixelBuffer)
        let pixelBufferPlaneCount = CVPixelBufferGetPlaneCount(pixelBuffer)
                
        if( (pixelBufferHeight != FMImage.Constants.PixelBufferHeight) ||
            (pixelBufferWidth != FMImage.Constants.PixelBufferWidth) ||
            (pixelBufferPlaneCount != FMImage.Constants.PixelBufferPlaneCount)) {
            return nil
        }
        
        if let uiImage = UIImage(pixelBuffer: pixelBuffer, scale: FMImage.Constants.ImageScaleFactor, deviceOrientation: deviceOrientation) {
            if let jpegData = uiImage.toJpeg(compressionQuality: FMImage.Constants.JpegCompressionRatio){
                return jpegData
            } else {
                return nil
            }
        }
        else {
            print("No image data supplied. Skipping write.")
            return nil
        }
    }
    
}
