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
     
     @param frame The frame recorded for location udpate.
     @param location The current CPS Location
     @param metadata The meta data releated to the CPS Location
     */
    @objc optional func locationManager(didUpdateLocation location: CLLocation?, locationMetadata metadata: Any)
    
    /**
    This is called when CPS update fails.
    
    @param frame The frame which cause the failure, It will return nil if session is not available.
    @param error The error being reported .
    */
    @objc optional func locationManager(_ frame: ARFrame, didFailWithError error: Error)
}


open class FMLocationManager {

    public static let shared = FMLocationManager()
    private var anchorFrame: ARFrame?
    public var delegate: FMLocationDelegate?
    
    private init() {}
    
    // Start method for pass delegate and license key.
    public func start(locationDelegate: FMLocationDelegate, licenseKey: String) {
        // TODO: Here we have to validate license key for each user.
        delegate = locationDelegate
    }
    
    // Set current anchor ARFrame
    public func setAnchorTimeNow(frame: ARFrame) {
        anchorFrame = frame
    }
    
    // Localize method for upload images
    internal func localize(frame: ARFrame) {
        let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation ?? UIInterfaceOrientation.unknown
        let deviceOrientation = UIDevice.current.orientation
        
        DispatchQueue.global(qos: .background).async {
            
            let tosImage = FMImage(frame: frame,
                                    withStatusBarOrientation: interfaceOrientation,
                                    withDeviceOrientation: deviceOrientation,
                                    atLocation: nil)
            
            guard let jpegData = FMImage.convertToJpeg(fromPixelBuffer: frame.capturedImage,
                                                        withDeviceOrientation: deviceOrientation) else {
                                                            print("Error: Could not convert frame to JPEG.")
                                                            return
            }
            
            let intrinsicsJson = String(format: "{\"fx\": %f, \"fy\": %f, \"cx\": %f, \"cy\": %f}",
                                        tosImage.intrinsics.fx,
                                        tosImage.intrinsics.fy,
                                        tosImage.intrinsics.cx,
                                        tosImage.intrinsics.cy)
            
            let gravityJson = String(format: "{\"w\": %f, \"x\": %f, \"y\": %f, \"z\": %f}",
                                     tosImage.pose.orientation.w,
                                     tosImage.pose.orientation.x,
                                     tosImage.pose.orientation.y,
                                     tosImage.pose.orientation.z)
            
            let parameters = [
                "intrinsics" : intrinsicsJson,
                "gravity"    : gravityJson
            ]
            
            FMNetworkManager.uploadImage(url: FMConfiguration.Server.routeUrl, parameters: parameters,
                                       image: tosImage, jpegData: jpegData, mapName: "", onCompletion: { (response) in
                if let response = response {
                    let cpsLocation = CLLocation()
                    self.delegate?.locationManager?(didUpdateLocation: cpsLocation, locationMetadata: response)
                }
            }) { (err) in
                let error: Error = FMError.network(type: .notFound)
                self.delegate?.locationManager?(frame, didFailWithError: error)
            }
        }
    }
}
