//
//  FMLocationManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import CoreLocation

@objc public protocol FMLocationDelegate : NSObjectProtocol {
    /**
     This is called when a new CPS location has been updated.
     
     - Parameter location: The current CPS Location
     - Parameter metadata: The meta data releated to the CPS Location
     */
    @objc optional func locationManager(didUpdateLocation location: CLLocation?, locationMetadata metadata: Any)
    
    /**
     This is called when CPS update fails.
     
     - Parameter error:  The error being reported .
     - Parameter metadata: The meta data releated to the error
     */
    @objc optional func locationManager(didFailWithError error: Error, errorMetadata metadata: Any)
}


open class FMLocationManager {
    
    public static let shared = FMLocationManager()
    private var anchorFrame: ARFrame?
    private var delegate: FMLocationDelegate?
    private let isStatic = true // For Static data
    
    private init() {}
    
    /**
     Start method for pass delegate and license key.
     
     - Parameter locationDelegate:  The error being reported .
     - Parameter licenseKey: LicenseKey of user
     */
    public func start(locationDelegate: FMLocationDelegate, licenseKey: String) {
        // TODO: Here we have to validate license key for each user.
        delegate = locationDelegate
    }
    
    /**
     Set current anchor ARFrame.
     
     - Parameter frame:  Current frame of image .
     */
    public func setAnchorTimeNow(frame: ARFrame) {
        anchorFrame = frame
    }
    
    /**
     Localize method for upload images.
     
     - Parameter frame:  Frame of image .
     */
    internal func localize(frame: ARFrame) {
        let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation ?? UIInterfaceOrientation.unknown
        let deviceOrientation = UIDevice.current.orientation
        
        DispatchQueue.global(qos: .background).async {
            
            let pose = FMPose(fromTransform: frame.camera.transform)
            let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                      atScale: Float(Constants.ImageScaleFactor),
                                      withStatusBarOrientation: interfaceOrientation,
                                      withDeviceOrientation: deviceOrientation,
                                      withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                      withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
            guard let jpegData = self.isStatic ? UIImage(named: "testImage")?.toJpeg(compressionQuality: Constants.JpegCompressionRatio) : self.convertToJpeg(fromPixelBuffer: frame.capturedImage, withDeviceOrientation: deviceOrientation) else {
                print("Error: Could not convert frame to JPEG.")
                return
            }
            
            var parameters = [
                "intrinsics" : intrinsics.toJson(),
                "gravity"    : pose.orientation.toJson(),
                "capturedAt" :"\(NSDate().timeIntervalSince1970)".data(using: String.Encoding.utf8)!,
                "uuid" : UUID().uuidString,
                "mapId" : "",
                "coordinate": ["longitude" : 11.572596873561112, "latitude": 48.12844364094412]
            ] as [String : Any]

            if self.isStatic {
                parameters = [
                    "intrinsics" : "{\"fx\": 1211.782470703125, \"fy\": 1211.9073486328125, \"cx\": 1017.4938354492188, \"cy\": 788.2992553710938}",
                    "gravity"    : "{\"w\": 0.7729115057076497, \"x\": 0.026177782246603, \"y\": 0.6329531644390612, \"z\": -0.03595580186787759}",
                    "capturedAt" :"\(NSDate().timeIntervalSince1970)".data(using: String.Encoding.utf8)!,
                    "uuid" : "C6241E04-974A-4131-8B36-044A11E2C7F0",
                    "mapId" : "terra_explorer",
                    "coordinate": "{\"longitude\" : 11.572596873561112, \"latitude\": 48.12844364094412}"
                ] as [String : Any]
            }
            FMNetworkManager.uploadImage(url: FMConfiguration.Server.routeUrl, parameters: parameters,
                                         jpegData: jpegData, onCompletion: { (response) in
                                            if let response = response {
                                                let cpsLocation = CLLocation()
                                                self.delegate?.locationManager?(didUpdateLocation: cpsLocation, locationMetadata: response)
                                            }
                                         }) { (err) in
                let error: Error = FMError.network(type: .notFound)
                self.delegate?.locationManager?(didFailWithError: error, errorMetadata:frame)
            }
        }
    }
    
    
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
            print("No image data supplied. Skipping write.")
            return nil
        }
    }
    
    private enum Constants {
        public static let JpegCompressionRatio: CGFloat = 0.9
        public static let ImageScaleFactor: CGFloat = 2.0/3.0
        public static let PixelBufferWidth: Int = 1920
        public static let PixelBufferHeight: Int = 1440
        public static let PixelBufferPlaneCount: Int = 2
    }
}

