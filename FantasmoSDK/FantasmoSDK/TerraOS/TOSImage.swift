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

class TOSImage: Codable {
    
    public enum Constants {
        public static let JpegCompressionRatio: CGFloat = 0.9
        public static let ImageScaleFactor: CGFloat = 2.0/3.0
        public static let PixelBufferWidth: Int = 1920
        public static let PixelBufferHeight: Int = 1440
        public static let PixelBufferPlaneCount: Int = 2
    }
    
    public let uuid = UUID().uuidString
    public private(set) var userId:String?
    public private(set) var timestamp:Double
    public private(set) var intrinsics:TOSIntrinsics
    public private(set) var pose:TOSPose
    public private(set) var latitude:Double
    public private(set) var longitude:Double
    
    public var filename:String {
        return String(format:"%.9f_%@", timestamp, uuid)
    }

    // MARK: - Initializers
    
    init(frame: ARFrame,
         withStatusBarOrientation currentStatusBarOrientation:UIInterfaceOrientation,
         withDeviceOrientation currentDeviceOrientation:UIDeviceOrientation,
         atLocation newLocation: CLLocationCoordinate2D?) {
        
        timestamp = (Date().timeIntervalSince1970 - ProcessInfo().systemUptime) + frame.timestamp
                
        pose = TOSPose(fromTransform: frame.camera.transform)
        intrinsics = TOSIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                   atScale: Float(TOSImage.Constants.ImageScaleFactor),
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
                
        if( (pixelBufferHeight != TOSImage.Constants.PixelBufferHeight) ||
            (pixelBufferWidth != TOSImage.Constants.PixelBufferWidth) ||
            (pixelBufferPlaneCount != TOSImage.Constants.PixelBufferPlaneCount)) {
            return nil
        }
        
        if let uiImage = UIImage(pixelBuffer: pixelBuffer, scale: TOSImage.Constants.ImageScaleFactor, deviceOrientation: deviceOrientation) {
            if let jpegData = uiImage.toJpeg(compressionQuality: TOSImage.Constants.JpegCompressionRatio){
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
