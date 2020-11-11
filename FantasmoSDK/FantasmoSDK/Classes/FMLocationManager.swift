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
    
    /// When in simulation mode, mock data is used from the assets directory instead of the live camera feed.
    /// This mode is useful for implementation and debugging.
    public var isSimulation = false
    /// The zone that will be simulated.
    public var simulationZone = FMZone.ZoneType.parking
    
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
            var localizeParams: [String : Any]?
            var imageData: Data?
            
            // Use the mock data instead of the ARFrame if we are simulating
            if self.isSimulation {
                let mockData = MockData.simulateLocalizeRequest(forZone: self.simulationZone,
                                                                isValid: true)
                localizeParams = mockData.params
                imageData = mockData.image
            } else {
                localizeParams = self.getLocalizeParams(frame: frame,
                                                  deviceOrientation: deviceOrientation,
                                                  interfaceOrientation: interfaceOrientation,
                                                  currentLocation: CLLocationManager.lastLocation ?? CLLocation())
                imageData = FMUtility.toJpeg(fromPixelBuffer: frame.capturedImage,
                                             withDeviceOrientation: deviceOrientation)
            }
            
            guard let parameters = localizeParams else {
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
                                                    let localizeResponse = try decoder.decode(LocalizeResponse.self, from: response)
                                                    let cpsLocation = localizeResponse.location?.coordinate?.getLocation()

                                                    guard let location = cpsLocation else {
                                                        let error: Error = FMError.custom(errorDescription: "Invalid location")
                                                        self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
                                                        return
                                                    }
                                                
                                                    var zones: [FMZone]?

                                                    if let geofences = localizeResponse.geofences {
                                                        zones = geofences.map {
                                                            FMZone(zoneType: FMZone.ZoneType(rawValue: $0.elementType.lowercased()) ?? .unknown, id: $0.elementID.description)
                                                        }
                                                    }

                                                    // TODO - Transform to anchor position if set
                                                    
                                                    self.delegate?.locationManager(didUpdateLocation: location,
                                                                                   withZones: zones)
                                                    
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
                           currentLocation: CLLocation) -> [String : Any]? {
        
        let pose = FMPose(fromTransform: frame.camera.transform)
        let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                      atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                      withStatusBarOrientation: interfaceOrientation,
                                      withDeviceOrientation: deviceOrientation,
                                      withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                      withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
        return ([
            "intrinsics" : intrinsics.toJson(),
            "gravity"    : pose.orientation.toJson(),
            "capturedAt" :(NSDate().timeIntervalSince1970),
            "uuid" : UUID().uuidString,
            "mapId" : "map",
            "coordinate": "{\"longitude\" : \(currentLocation.coordinate.longitude), \"latitude\": \(currentLocation.coordinate.latitude)}"
        ] as [String : Any])
    }
}
