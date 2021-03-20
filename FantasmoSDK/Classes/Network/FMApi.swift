//
//  FMApi.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation
import ARKit

protocol FMApiDelegate {
    var isSimulation: Bool { get }
    var simulationZone: FMZone.ZoneType  { get }
    var token: String? { get }
    var anchorFrame: ARFrame? { get }
}

class FMApi {
    
    public static let shared = FMApi()
    public var delegate: FMApiDelegate?
    
    typealias LocalizationResult = (CLLocation, [FMZone]?) -> Void
    typealias RadiusResult = (Bool) -> Void
    typealias ErrorResult = (FMError) -> Void
    
    enum ApiError: Error {
        case errorResponse
        case invalidImage
        case invalidResponse
        case locationNotFound
    }
    
    /// Localize based on the given image
    ///
    /// - Parameters:
    ///   - frame: The current ARFrame as given by ARSession
    ///   - completion: Completion closure
    ///   - error: Error closure
    func localize(frame: ARFrame,
                  completion: @escaping LocalizationResult,
                  error: @escaping ErrorResult) {
        
        // set up request parameters
        guard let data = getImageData(frame: frame) else {
            error(FMError(ApiError.invalidImage))
            return
        }
        let params = getParams(frame: frame)
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, data in
            
            // handle invalid response
            guard let code = code, let data = data else {
                error(FMError(ApiError.invalidResponse))
                return
            }
            
            // handle valid but erroneous response
            guard !(400...499 ~= code) else {
                error(FMError(data))
                return
            }
            
            // ensure non-error response
            guard code == 200 else {
                error(FMError(ApiError.invalidResponse))
                return
            }
            
            do {
                // decode server response
                let localizeResponse = try JSONDecoder().decode(LocalizeResponse.self, from: data)
                
                // get location
                guard let location = localizeResponse.location?.coordinate?.getLocation() else {
                    error(FMError(ApiError.locationNotFound))
                    return
                }
                
                // get zones
                var zones: [FMZone]?
                if let geofences = localizeResponse.geofences {
                    zones = geofences.map {
                        FMZone(zoneType: FMZone.ZoneType(rawValue: $0.elementType.lowercased()) ?? .unknown, id: $0.elementID.description)
                    }
                }
                
                completion(location, zones)
            } catch let jsonError {
                error(FMError(ApiError.invalidResponse, cause: jsonError))
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            error(FMError(errorResponse))
        }
        
        // send request
        FMRestClient.post(
            .localize,
            parameters: params,
            imageData: data,
            token: delegate?.token,
            completion: postCompletion,
            error: postError)
    }
    
    /// Check if a given zone is within a radius of our location.
    /// Currently only `parking` is supported.
    ///
    /// - Parameters:
    ///   - zone: The zone to search for
    ///   - radius: Radius, in meters, within which to search
    ///   - completion: Completion closure
    ///   - error: Error closure
    func isZoneInRadius(_ zone: FMZone.ZoneType,
                        radius: Int,
                        completion: @escaping RadiusResult,
                        error: @escaping ErrorResult) {
        
        // set up request parameters
        let coordinate = FMConfiguration.Location.current.coordinate
        let params = [
            "radius": String(radius),
            "coordinate": "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}",
        ]
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, data in
            guard let data = data else {
                error(FMError(ApiError.invalidResponse))
                return
            }
            do {
                // decode server response
                let radiusResponse = try JSONDecoder().decode(RadiusResponse.self, from: data)
                completion(radiusResponse.result == "true")
            } catch let jsonError {
                error(FMError(ApiError.invalidResponse, cause: jsonError))
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            error(FMError(errorResponse))
        }
        
        // send request
        FMRestClient.post(
            .zoneInRadius,
            parameters: params,
            token: delegate?.token,
            completion: postCompletion,
            error: postError)
    }
    
    /// Generate the localize HTTP request parameters.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Formatted localization parameters
    func getParams(frame: ARFrame) -> [String : String] {
        
        // mock if simulation
        guard delegate == nil || !delegate!.isSimulation else {
            return MockData.params(forZone: delegate!.simulationZone)
        }
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        let deviceOrientation = UIDevice.current.orientation
        
        let pose = FMPose(fromTransform: frame.camera.transform)
        let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                      atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                      withStatusBarOrientation: interfaceOrientation,
                                      withDeviceOrientation: deviceOrientation,
                                      withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                      withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
        let coordinate = FMConfiguration.Location.current.coordinate
        var params = [
            "intrinsics" : intrinsics.toJson(),
            "gravity" : pose.orientation.toJson(),
            "capturedAt" : String(NSDate().timeIntervalSince1970),
            "uuid" : UUID().uuidString,
            "coordinate": "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}"
        ]
        
        // calculate and send reference frame if anchoring
        if let anchorFrame = delegate?.anchorFrame {
            params["referenceFrame"] = anchorFrame.poseWithRespectTo(frame).toJson()
        }
        
        return params
    }
    
    /// Generate the localize HTTP request image data.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Prepared localization image
    func getImageData(frame: ARFrame) -> Data? {
        
        // mock if simulation
        guard delegate == nil || !delegate!.isSimulation else {
            return MockData.imageData(forZone: delegate!.simulationZone)
        }
        
        let deviceOrientation = UIDevice.current.orientation
        return FMUtility.toJpeg(fromPixelBuffer: frame.capturedImage,
                                withDeviceOrientation: deviceOrientation)
    }
}
