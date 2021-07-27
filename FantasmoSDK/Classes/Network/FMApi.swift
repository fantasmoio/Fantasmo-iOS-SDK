//
//  FMApi.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation
import ARKit

protocol FMApiDelegate: AnyObject {
    var isSimulation: Bool { get }
    var simulationZone: FMZone.ZoneType  { get }
    /// An estimate of the location. Coarse resolution is acceptable such as GPS or cellular tower proximity.
    var approximateCoordinate: CLLocationCoordinate2D { get }
}

class FMApi {
    
    static let shared = FMApi()
    weak var delegate: FMApiDelegate?
    var token: String?
    
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
    ///   - deviceOrientation: Orientation of device when frame was captured from camera.
    ///   - relativeOpenCVAnchorPose: Pose of anchor coordinate system in virtual device coordinate system and for both following OpenCV
    ///      conventions
    ///   - approximateLocation: An estimate of the location. Coarse resolution is acceptable such as GPS or cellular tower proximity.
    ///   - completion: Completion closure
    ///   - error: Error closure
    func sendLocalizeImageRequest(frame: ARFrame,
                                  relativeOpenCVAnchorPose: FMPose?,
                                  frameBasedInfoAccumulator: FrameBasedInfoAccumulator,
                                  completion: @escaping LocalizationResult,
                                  error: @escaping ErrorResult) {
        
        guard let imageData = extractDataOfProperlyOrientedImage(of: frame) else {
            error(FMError(ApiError.invalidImage))
            return
        }
        
        let params = paramsOfLocalizeImageRequest(for: frame,
                                                  relativeOpenCVAnchorPose: relativeOpenCVAnchorPose,
                                                  frameBasedInfoAccumulator: frameBasedInfoAccumulator)
        
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
                        FMZone(zoneType: FMZone.ZoneType(rawValue: $0.elementType.lowercased()) ?? .unknown,
                               id: $0.elementID.description)
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
            imageData: imageData,
            token: token,
            completion: postCompletion,
            error: postError
        )
    }
    
    /// Check if a given zone is within a radius of our location.
    /// Currently only `parking` is supported.
    ///
    /// - Parameters:
    ///   - zone: The zone to search for
    ///   - coordinate: Center of area to search for
    ///   - radius: Radius, in meters, within which to search
    ///   - completion: Completion closure
    ///   - error: Error closure
    func sendZoneInRadiusRequest(_ zone: FMZone.ZoneType,
                                 coordinate: CLLocationCoordinate2D,
                                 radius: Int,
                                 completion: @escaping RadiusResult,
                                 error: @escaping ErrorResult) {
        
        // set up request parameters
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
            token: token,
            completion: postCompletion,
            error: postError
        )
    }
    
    // MARK: - Helpers
    
    /// Calculate parameters of the "Localize" request for the given `ARFrame`.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Formatted localization parameters
    private func paramsOfLocalizeImageRequest(
        for frame: ARFrame,
        relativeOpenCVAnchorPose: FMPose?,
        frameBasedInfoAccumulator: FrameBasedInfoAccumulator
    ) -> [String : String] {
        
        var params = [String : String]()
        
        // mock if simulation
        if delegate == nil || !delegate!.isSimulation {
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            
            let pose = FMPose(frame.openCVTransformOfVirtualDeviceInWorldCS)
            
            let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                          atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                          withStatusBarOrientation: interfaceOrientation,
                                          withDeviceOrientation: frame.deviceOrientation,
                                          withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                          withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
            
            let coordinate = delegate!.approximateCoordinate
            
            params["intrinsics"] = intrinsics.toJson()
            params["gravity"] = pose.orientation.toJson()
            params["capturedAt"] = String(NSDate().timeIntervalSince1970)
            params["uuid"] = UUID().uuidString
            params["coordinate"] = "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}"
        }
        else {
            params = MockData.params(forZone: delegate!.simulationZone)
        }
        
        if let relativeOpenCVAnchorPose = relativeOpenCVAnchorPose {
            params["referenceFrame"] = relativeOpenCVAnchorPose.toJson()
        }
        
        params["rotationSpread"] = frameBasedInfoAccumulator.eulerAngleSpreadsAccumulator.spreads.toJson()
        params["totalTranslation"] = String(frameBasedInfoAccumulator.totalTranslation)
        params["deviceModel"] = UIDevice.current.identifier    // "iPhone7,1"
        params["deviceOs"] = UIDevice.current.system           // "iPadOS 14.5"
        params["sdkVersion"] = Bundle.fullVersion              // "1.1.18(365)
        
        return params
    }
    
    /// Generate the image data used to perform "localize" HTTP request .
    /// Image of `frame` is oriented taking into account orientation of camera when taking image. For example, if device was upside-down when
    /// frame was captured from camera, then resulting image is rotated by 180 degrees. So server always receives properly oriented image
    /// as if it was captured from properly oriented camera.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Prepared localization image
    private func extractDataOfProperlyOrientedImage(of frame: ARFrame) -> Data? {
        
        // mock if simulation
        guard delegate == nil || !delegate!.isSimulation else {
            return MockData.imageData(forZone: delegate!.simulationZone)
        }

        let imageData = FMUtility.toJpeg(pixelBuffer: frame.capturedImage, with: frame.deviceOrientation)
        return imageData
    }
    
    private func deviceCharacteristics() -> [String : String] {
        [
            "deviceModel"        : UIDevice.current.identifier,          // "iPhone7,1"
            "deviceOs"           : UIDevice.current.system,              // "iPadOS 14.5"
            "fantasmoSdkVersion" : Bundle.fullVersion                    // "1.1.18(365)
        ]
    }
}
