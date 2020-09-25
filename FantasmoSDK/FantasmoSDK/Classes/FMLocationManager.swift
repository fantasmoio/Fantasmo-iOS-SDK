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
            
            let fmImage = FMImage(frame: frame,
                                   withStatusBarOrientation: interfaceOrientation,
                                   withDeviceOrientation: deviceOrientation,
                                   atLocation: nil)
            
            guard let jpegData = FMImage.convertToJpeg(fromPixelBuffer: frame.capturedImage,
                                                       withDeviceOrientation: deviceOrientation) else {
                print("Error: Could not convert frame to JPEG.")
                return
            }
            
            let intrinsicsJson = String(format: "{\"fx\": %f, \"fy\": %f, \"cx\": %f, \"cy\": %f}",
                                        fmImage.intrinsics.fx,
                                        fmImage.intrinsics.fy,
                                        fmImage.intrinsics.cx,
                                        fmImage.intrinsics.cy)
            
            let gravityJson = String(format: "{\"w\": %f, \"x\": %f, \"y\": %f, \"z\": %f}",
                                     fmImage.pose.orientation.w,
                                     fmImage.pose.orientation.x,
                                     fmImage.pose.orientation.y,
                                     fmImage.pose.orientation.z)
            
            let parameters = [
                "intrinsics" : intrinsicsJson,
                "gravity"    : gravityJson
            ]
            
            FMNetworkManager.uploadImage(url: FMConfiguration.Server.routeUrl, parameters: parameters,
                                         image: fmImage, jpegData: jpegData, mapName: "", onCompletion: { (response) in
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
}
