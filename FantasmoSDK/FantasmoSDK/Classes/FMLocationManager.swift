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


/// The methods that you use to receive events from an associated
/// location manager object.
public protocol FMLocationDelegate : NSObjectProtocol {
    
    /// Tells the delegate that new location data is available.
    ///
    /// - Parameters:
    ///   - location: Location of the device (or anchor if set)
    ///   - zones: Semantic zone corresponding to the location
    func locationManager(didUpdateLocation location: CLLocation,
                         withZones zones: [FMZone]?)
    
    
    /// Tells the delegate that an error has occurred.
    ///
    /// - Parameters:
    ///   - error: The error reported.
    ///   - metadata: Metadata related to the error.
    func locationManager(didFailWithError error: Error,
                         errorMetadata metadata: Any?)
}

/// Empty implementations of the protocol to allow optional
/// implementation for delegates.
extension FMLocationDelegate {
    func locationManager(didUpdateLocation location: CLLocation,
                         withZones zones: [FMZone]?) {}
    
    func locationManager(didFailWithError error: Error,
                         errorMetadata metadata: Any?) {}
}


/// Start and stop the delivery of camera-based location events.
open class FMLocationManager {
    
    public enum State {
        case stopped
        case idle
        case localizing
    }
    
    
    // MARK: - Properties
    
    public static let shared = FMLocationManager()
    public private(set) var state = State.idle
    
    private var anchorFrame: ARFrame?
    private var delegate: FMLocationDelegate?
    private let isStatic = true // For Static data
    
    
    // MARK: - Lifecycle
    
    private init() {}
    
    /// Connect to the location service.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    public func connect(accessToken: String,
                        delegate: FMLocationDelegate) {
        
        // TODO: Validate token
        
        self.delegate = delegate
    }
    
    
    // MARK: - Public instance methods
    
    /// Starts the generation of updates that report the user’s current location.
    public func startUpdatingLocation() {
        self.state = .idle
    }
    
    /// Stops the generation of location updates.
    public func stopUpdatingLocation() {
        self.state = .stopped
    }
    
    /// Set an anchor point. All location updates will now report the
    /// location of the anchor instead of the camera.
    public func setAnchor() {
        self.anchorFrame = ARSession.lastFrame
    }
    
    /// Unset the anchor point. All location updates will now report the
    /// location of the camera.
    public func unsetAnchor() {
        self.anchorFrame = nil
    }
    
    
    // MARK: - Internal instance methods
    
    /// Localize the image frame. It triggers a network request that
    /// provides a response via the delegate.
    ///
    /// - Parameter frame: Frame to localize.
    internal func localize(frame: ARFrame) {
        
        self.state = .localizing
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        let deviceOrientation = UIDevice.current.orientation
        
        DispatchQueue.global(qos: .background).async {
            var params: [String : Any]?
            var imageData: Data?
            #if DEBUG
            let mockData = MockData.getLocalizeRequestWithType(success: true)
            params = mockData.params
            imageData = mockData.image
            #else
            let localizeRequest = self.getlocalizeRequest(frame: frame,
                                                          deviceOrientation: deviceOrientation,
                                                          interfaceOrientation: interfaceOrientation,
                                                          currentLocation: CLLocationManager.lastLocation ?? CLLocation())
            params = localizeRequest.params
            imageData = localizeRequest.image
            #endif
            
            guard let parameters = params else {
                self.delegate?.locationManager(didFailWithError: "Invalid request parameters" as! Error, errorMetadata: nil)
                return
            }
            
            guard let image = imageData else {
                self.delegate?.locationManager(didFailWithError: "Invalid image frame" as! Error, errorMetadata: nil)
                return
            }
            
            FMNetworkManager.uploadImage(url: FMConfiguration.Server.routeUrl,
                                         parameters: parameters,
                                         jpegData: image, onCompletion: { (response) in
                                            
                                            self.state = .idle
                                            
                                            if let response = response {
                                                do {
                                                    let decoder = JSONDecoder()
                                                    let userLocation = try decoder.decode(UserLocation.self, from: response)
                                                    let cpsLocation = userLocation.location?.coordinate?.getLocation()
                                                    
                                                    // TODO - add guard statement to throw error if the cpsLocation
                                                    
                                                    // TODO - Transform to anchor position if set
                                                    
                                                    // TODO - add zones from the response
                                                    
                                                    self.delegate?.locationManager(didUpdateLocation: cpsLocation!, withZones: nil)
                                                    
                                                } catch {
                                                    // TODO - Handle exception
                                                }
                                            }
                                         }) { (error) in
                
                self.state = .idle
                
                let error: Error = FMError.network(type: .notFound)
                self.delegate?.locationManager(didFailWithError: error,
                                               errorMetadata:frame)
            }
        }
    }
    
    
    /// Generate the localize HTTP request parameters. Can fail if the jpeg
    /// conversion throws an exception.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - deviceOrientation: Current device orientation for computing intrinsics
    ///   - interfaceOrientation: Current interface orientation for computing intrinsics
    ///   - currentLocation: Current geo location for coarse estimate
    /// - Returns: Formatted
    func getLocalizeParams(frame: ARFrame,
                           deviceOrientation: UIDeviceOrientation,
                           interfaceOrientation: UIInterfaceOrientation,
                           currentLocation: CLLocation) -> (params: [String : Any]?,
                                                            image: Data?) {
        let pose = FMPose(fromTransform: frame.camera.transform)
        let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                      atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                      withStatusBarOrientation: interfaceOrientation,
                                      withDeviceOrientation: deviceOrientation,
                                      withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                      withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
        guard let jpegData = FMUtility.toJpeg(fromPixelBuffer: frame.capturedImage, withDeviceOrientation: deviceOrientation) else {
            // TODO - Handle exception
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
