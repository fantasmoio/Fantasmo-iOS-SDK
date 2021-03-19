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
    
    typealias LocalizationResult = (CLLocation, [FMZone]) -> Void
    
    enum ApiError: Error {
        case invalidFrameImage
        case invalidServerResponse
    }
    
    func localize(frame: ARFrame,
                  completion: LocalizationResult,
                  error: (Error) -> Void) {
        
        guard let data = getImageData(frame: frame) else {
            error(ApiError.invalidFrameImage)
            return
        }
        let params = getParams(frame: frame)
        
        let completion: FMRestClient.RestResult = { code, response in
  
        }
        
        let error: FMRestClient.RestError = { error in
            
        }
        
        FMRestClient.post(
            .localize,
            parameters: params,
            imageData: data,
            token: delegate?.token,
            completion: completion,
            error: error)
    }
    
    func isZoneInRadius(_ zone: FMZone.ZoneType,
                        radius: Int,
                        completion: @escaping (Bool) -> Void,
                        error: @escaping (Error) -> Void) {
        
        let coordinate = FMConfiguration.Location.current.coordinate
        
        let params = [
            "radius": String(radius),
            "coordinate": "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}",
        ]
        
        let postCompletion: FMRestClient.RestResult = { code, data in
            guard let data = data else {
                error(ApiError.invalidServerResponse)
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? Dictionary<String, String>
                print(json ?? "JSON error")
                if let result = json?["result"], result == "true" {
                    completion(true)
                } else {
                    completion(false)
                }
            } catch let jsonError {
                print("JSON error: \(jsonError.localizedDescription)")
                error(jsonError)
            }
        }
        
        let postError: FMRestClient.RestError = { errorResponse in
            error(errorResponse)
        }
        
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
