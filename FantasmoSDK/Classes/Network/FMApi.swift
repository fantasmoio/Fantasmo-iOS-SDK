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
    typealias ErrorResult = (Error) -> Void
    
    enum ApiError: Error {
        case invalidImage
        case invalidResponse
        case locationNotFound
    }
    
    func localize(frame: ARFrame,
                  completion: @escaping LocalizationResult,
                  error: @escaping ErrorResult) {
        
        // set up request parameters
        guard let data = getImageData(frame: frame) else {
            error(ApiError.invalidImage)
            return
        }
        let params = getParams(frame: frame)
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, response in
            
            // handle invalid response
            guard let code = code, let response = response else {
                error(ApiError.invalidResponse)
                return
            }
            
            // handle valid but erroneous response
            guard !(400...499 ~= code) else {
                do {
                    let errorResponse = try JSONDecoder().decode(ErrorResponse.self, from: response)
                    let customError = FMError.custom(errorDescription: errorResponse.message)
                    error(customError)
                } catch let jsonError {
                    print("JSON error: \(jsonError.localizedDescription)")
                    error(ApiError.invalidResponse)
                }
                return
            }
            
            // ensure non-error response
            guard code == 200 else {
                error(ApiError.invalidResponse)
                return
            }
            
            do {
                // decode server response
                let localizeResponse = try JSONDecoder().decode(LocalizeResponse.self, from: response)
                
                // get location
                guard let location = localizeResponse.location?.coordinate?.getLocation() else {
                    error(ApiError.locationNotFound)
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
            } catch {
                
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            error(errorResponse)
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
                error(ApiError.invalidResponse)
                return
            }
            do {
                //TODO: user JSONDecoder
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, String>
                if let result = json?["result"], result == "true" {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let jsonError {
                print("JSON error: \(jsonError.localizedDescription)")
                error(ApiError.invalidResponse)
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            error(errorResponse)
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
        ] as [String : String]
        
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
