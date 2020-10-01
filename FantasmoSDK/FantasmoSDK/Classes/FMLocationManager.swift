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
     
     - Parameter error:  The error being reported
     - Parameter metadata: The meta data releated to the error
     */
    @objc optional func locationManager(didFailWithError error: Error, errorMetadata metadata: Any)
    
    /**
     This is called when CPS update fails.
     
     - Parameter error: The error being reported
     */
    @objc optional func locationManager(didFailWithError description: String)
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
    internal func localize(frame: ARFrame, currentLocation: CLLocation) {
        let interfaceOrientation = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.windowScene?.interfaceOrientation ?? UIInterfaceOrientation.unknown
        let deviceOrientation = UIDevice.current.orientation
        
        DispatchQueue.global(qos: .background).async {
            var params: [String : Any]?
            var imageData: Data?
            #if DEBUG
            let mockData = MockData().getLocaliseResponseWithType(success: true)
            params = mockData.params
            imageData = mockData.image
            #else
            let localiseResponse = self.getLocaliseResponse(frame: frame, deviceOrientation: deviceOrientation, interfaceOrientation: interfaceOrientation, currentLocation: currentLocation)
            params = localiseResponse.params
            imageData = localiseResponse.image
            #endif
            
            guard let parameters = params else {
                self.delegate?.locationManager?(didFailWithError: "Invalid parameters")
                return
            }
            
            guard let image = imageData else {
                self.delegate?.locationManager?(didFailWithError: "Invalid frame")
                return
            }
            
            FMNetworkManager.uploadImage(url: FMConfiguration.Server.routeUrl, parameters: parameters,
                                         jpegData: image, onCompletion: { (response) in
                                            if let response = response {
                                                do {
                                                    let decoder = JSONDecoder()
                                                    let userLocation = try decoder.decode(UserLocation.self, from: response)
                                                    let cpsLocation = userLocation.location?.coordinate?.getLocation()
                                                    self.delegate?.locationManager?(didUpdateLocation: cpsLocation, locationMetadata: response)
                                                } catch {
                                                }
                                            }
                                         }) { (error) in
                let error: Error = FMError.network(type: .notFound)
                self.delegate?.locationManager?(didFailWithError: error, errorMetadata:frame)
            }
        }
    }
            
    func getLocaliseResponse(frame: ARFrame, deviceOrientation: UIDeviceOrientation,
                interfaceOrientation: UIInterfaceOrientation, currentLocation: CLLocation) -> (params: [String : Any]?, image: Data?) {
        let pose = FMPose(fromTransform: frame.camera.transform)
        let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                      atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                      withStatusBarOrientation: interfaceOrientation,
                                      withDeviceOrientation: deviceOrientation,
                                      withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                      withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
        guard let jpegData = FMUtility().convertToJpeg(fromPixelBuffer: frame.capturedImage, withDeviceOrientation: deviceOrientation) else {
            return (nil, nil)
        }
        return ([
            "intrinsics" : intrinsics.toJson(),
            "gravity"    : pose.orientation.toJson(),
            "capturedAt" :(NSDate().timeIntervalSince1970),
            "uuid" : UUID().uuidString,
            "coordinate": "{\"longitude\" : \(currentLocation.coordinate.longitude), \"latitude\": \(currentLocation.coordinate.latitude)}"
        ] as [String : Any], jpegData)
    }
}
