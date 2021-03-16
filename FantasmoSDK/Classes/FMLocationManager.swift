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
        case stopped        // doing nothing
        case localizing     // localizing
        case uploading      // uploading image while localizing
    }
    
    
    // MARK: - Properties
    
    public static let shared = FMLocationManager()
    public private(set) var state = State.stopped
    
    private var anchorFrame: ARFrame?

    private var delegate: FMLocationDelegate?
    private var token: String?
    
    /// When in simulation mode, mock data is used from the assets directory instead of the live camera feed.
    /// This mode is useful for implementation and debugging.
    public var isSimulation = false
    /// The zone that will be simulated.
    public var simulationZone = FMZone.ZoneType.parking
    public var isConnected = false

    // MARK: - Lifecycle
    
    private init() {}
    
    /// Connect to the location service.
    ///
    /// - Parameters:
    ///   - accessToken: Token for service authorization.
    ///   - delegate: Delegate for receiving location events.
    public func connect(accessToken: String,
                        delegate: FMLocationDelegate) {
        
        debugPrint("FMLocationManager connected with delegate: \(delegate)")
        
        self.token = accessToken
        self.delegate = delegate
    }
    
    
    // MARK: - Public instance methods
    
    /// Starts the generation of updates that report the user’s current location.
    public func startUpdatingLocation() {
        debugPrint("FMLocationManager:startUpdatingLocation")
        self.isConnected = true
        self.state = .localizing
    }
    
    /// Stops the generation of location updates.
    public func stopUpdatingLocation() {
        debugPrint("FMLocationManager:stopUpdatingLocation")
        self.state = .stopped
    }
    
    /// Set an anchor point. All location updates will now report the
    /// location of the anchor instead of the camera.
    public func setAnchor() {
        debugPrint("FMLocationManager:setAnchor")
        self.anchorFrame = ARSession.lastFrame
    }
    
    /// Unset the anchor point. All location updates will now report the
    /// location of the camera.
    public func unsetAnchor() {
        debugPrint("FMLocationManager:unsetAnchor")
        self.anchorFrame = nil
    }
    

    /// Calculate the FMPose difference of the anchor frame with respect to the given frame
    public func anchorDeltaPoseForFrame(_ frame: ARFrame) -> FMPose {
        if let anchorFrame = anchorFrame {
            return FMPose.diffPose(anchorFrame.camera.transform, withRespectTo: frame.camera.transform)
        } else {
            return FMPose()
        }
    }
    
    /// Check to see if a given zone is in the provided radius
    ///
    /// - Parameter zone: zone to search for
    /// - Parameter radius: search radius in meters
    /// - Parameter completion: closure that consumes boolean server result
    public func isZoneInRadius(_ zone: FMZone.ZoneType, radius: Int, completion: @escaping (Bool)->Void) {
        // TODO rewrite networking layer to remove dependencies
        // as FMNetworkManager does not support multipart forms without an image
        // and no point in adding it now, as we are removing AlamoFire shortly
        // TODO switch based on zone type
        // TODO url should be dynamic, based on build scheme"
        
        let session = URLSession.shared
        let url = URL(string: "https://api.fantasmo.io/v1/parking.in.radius")!
        
        // build request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(self.token, forHTTPHeaderField: "Fantasmo-Key")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // prepare payload
        
        let fieldName1 = "radius"
        let fieldValue1 = radius
        
        let coordinate = FMConfiguration.Location.current.coordinate
        
        let fieldName2 = "coordinate"
        let fieldValue2 = "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}"
        
        // package fields as Data
        
        var data = Data()
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName1)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(fieldValue1)".data(using: .utf8)!)
        
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(fieldName2)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(fieldValue2)".data(using: .utf8)!)
        
        // End the raw http request data, note that there is 2 extra dash ("-") at the end, this is to indicate the end of the data
        // According to the HTTP 1.1 specification https://tools.ietf.org/html/rfc7230
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
         
        // set up task and its completion
        session.uploadTask(with: request, from: data, completionHandler: { data, response, error in
            guard let data = data, let response = response as? HTTPURLResponse else {
                print("no data")
                completion(false)
                return
            }
            
            print("status: \(response.statusCode)")
            print("data: \(data)")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, String>
                print(json ?? "JSON error")
                if let result = json?["result"], result == "true" {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch {
                print("JSON error: \(error.localizedDescription)")
                completion(false)
            }
        }).resume()
    }
    
    
    // MARK: - Internal instance methods
    
    /// Localize the image frame. It triggers a network request that
    /// provides a response via the delegate.
    ///
    /// - Parameter frame: Frame to localize.
    internal func localize(frame: ARFrame) {
        if !isConnected {
            return
        }
        
        debugPrint("FMLocationManager:localize called with simulation: \(isSimulation)")
        self.state = .uploading
        
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
                                                  currentLocation: FMConfiguration.Location.current)
                imageData = FMUtility.toJpeg(fromPixelBuffer: frame.capturedImage,
                                             withDeviceOrientation: deviceOrientation)
            }
            
            guard let parameters = localizeParams else {
                debugPrint("FMLocationManager:didFailWithError localizeParams")
                self.delegate?.locationManager(didFailWithError: FMError.custom(errorDescription: "Invalid request parameters") as Error, errorMetadata: nil)
                return
            }
            
            guard let image = imageData else {
                debugPrint("FMLocationManager:didFailWithError imageData")
                self.delegate?.locationManager(didFailWithError: FMError.custom(errorDescription: "Invalid image frame") as Error, errorMetadata: nil)
                return
            }
            
            debugPrint("FMLocationManager:uploadImage")
            FMNetworkManager.uploadImage(url: FMConfiguration.Server.routeUrl,
                                         token: self.token,
                                         parameters: parameters,
                                         jpegData: image, onCompletion: { (code, response) in
                                            
                                            if self.state != .stopped {
                                                self.state = .localizing
                                            }
            
                                            if let response = response, let code = code {
                                                debugPrint("FMLocationManager:uploadImage response: (\(code)) \(String(data: response, encoding: .utf8)!)")
                                                do {
                                                    let decoder = JSONDecoder()
                                                    
                                                    switch code {
                                                    case 200:
                                                        let localizeResponse = try decoder.decode(LocalizeResponse.self, from: response)
                                                        let cpsLocation = localizeResponse.location?.coordinate?.getLocation()
            
                                                        guard let location = cpsLocation else {
                                                            debugPrint("FMLocationManager:uploadImage didFailWithError cpsLocation")
                                                            let error: Error = FMError.custom(errorDescription: "Location not found")
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
                                                        self.delegate?.locationManager(didUpdateLocation: location, withZones: zones)
                                                    default:
                                                        let errorResponse = try decoder.decode(ErrorResponse.self, from: response)
                                                        debugPrint("FMLocationManager:uploadImage didFailWithError: \(errorResponse.message ?? "Unkown error")")
                                                        let error: Error = FMError.custom(errorDescription: errorResponse.message)
                                                        self.delegate?.locationManager(didFailWithError: error, errorMetadata: nil)
                                                    }
                                                    
                                                } catch {
                                                    debugPrint("FMLocationManager:uploadImage didFailWithError \(error)")
                                                }
                                            }
                                            else {
                                                debugPrint("FMLocationManager:uploadImage response not received.")
                                            }
                                            
                                         })
            { (error) in
                if self.state != .stopped {
                    self.state = .localizing
                }
                debugPrint("FMLocationManager:uploadImage didFailWithError \(String(describing: error))")
                let error: Error = FMError.custom(errorDescription: error?.localizedDescription)
                self.delegate?.locationManager(didFailWithError: error, errorMetadata:frame)
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
        
        var params = [
            "intrinsics" : intrinsics.toJson(),
            "gravity" : pose.orientation.toJson(),
            "capturedAt" : (NSDate().timeIntervalSince1970),
            "uuid" : UUID().uuidString,
            "coordinate": "{\"longitude\" : \(currentLocation.coordinate.longitude), \"latitude\": \(currentLocation.coordinate.latitude)}"
        ] as [String : Any]
        
        // calculate and send reference frame if anchoring
        if anchorFrame != nil {
            params["referenceFrame"] = anchorDeltaPoseForFrame(frame).toJson()
        }
        
        return params
    }
}
