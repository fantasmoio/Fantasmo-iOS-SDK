//
//  FMApi.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation
import ARKit

struct FMLocalizationRequest {
    var isSimulation: Bool
    var simulationZone: FMZone.ZoneType
    var approximateCoordinate: CLLocationCoordinate2D
    var relativeOpenCVAnchorPose: FMPose?
    var analytics: FMLocalizationAnalytics
}

struct FMLocalizationAnalytics {
    var appSessionId: String?
    var localizationSessionId: String?
    var frameEvents: FMFrameEvents
}

struct FMFrameEvents {
    var excessiveTilt: Int
    var excessiveBlur: Int
    var excessiveMotion: Int
    var insufficientFeatures: Int
    var lossOfTracking: Int
    var total: Int
}

class FMApi {
    
    static let shared = FMApi()
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
    
    // MARK: - internal methods
    
    /// Localize based on the given image
    ///
    /// - Parameters:
    ///   - frame: The current ARFrame as given by ARSession
    ///   - relativeOpenCVAnchorPose: Pose of anchor coordinate system
    ///   - completion: Completion closure
    ///   - error: Error closure
    func sendLocalizationRequest(frame: ARFrame,
                                 request: FMLocalizationRequest,
                                 completion: @escaping LocalizationResult,
                                 error: @escaping ErrorResult) {
        
        // set up request parameters
        guard let imageData = imageData(from: frame, request: request) else {
            error(FMError(ApiError.invalidImage))
            return
        }
        
        let params = getParams(for: frame, request: request)
        
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
    
    // MARK: - private methods
    
    /// Calculate parameters of the "Localize" request for the given `ARFrame`.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Formatted localization parameters
    private func getParams(for frame: ARFrame, request: FMLocalizationRequest) -> [String : String?] {
        
        // mock if simulation
        if !request.isSimulation {
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            
            let pose = FMPose(frame.openCVTransformOfVirtualDeviceInWorldCS)
            
            let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                          atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                          withStatusBarOrientation: interfaceOrientation,
                                          withDeviceOrientation: frame.deviceOrientation,
                                          withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                          withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
            
            let coordinate = request.approximateCoordinate

            let events = request.analytics.frameEvents
            let frameEventCounts = [
                "excessiveTilt": events.excessiveTilt,
                "excessiveBlur": events.excessiveBlur,
                "excessiveMotion": events.excessiveMotion,
                "insufficientFeatures": events.insufficientFeatures,
                "lossOfTracking": events.lossOfTracking,
                "total": events.total,
            ]

            var params = [
                "intrinsics" : intrinsics.toJson(),
                "gravity" : pose.orientation.toJson(),
                "capturedAt" : String(NSDate().timeIntervalSince1970),
                "uuid" : UUID().uuidString,
                "coordinate": "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}",

                // device characteristics
                "deviceModel": UIDevice.current.identifier,
                "deviceOs": UIDevice.current.correctedSystemName,
                "deviceOsVersion": UIDevice.current.systemVersion,
                "sdkVersion": Bundle.fullVersion,

                // session identifiers
                "appSessionId": request.analytics.appSessionId,
                "localizationSessionId": request.analytics.localizationSessionId,

                "frameEventCounts": frameEventCounts.toJson(),
            ]

            // calculate and send reference frame if anchoring
            if let relativeOpenCVAnchorPose = request.relativeOpenCVAnchorPose {
                params["referenceFrame"] = relativeOpenCVAnchorPose.toJson()
            }

            return params
        }
        else {
            return MockData.params(request)
        }
    }
    
    /// Generate the image data used to perform "localize" HTTP request .
    /// Image of `frame` is oriented taking into account orientation of camera when taking image. For example, if device was upside-down when
    /// frame was captured from camera, then resulting image is rotated by 180 degrees. So server always receives properly oriented image
    /// as if it was captured from properly oriented camera.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Prepared localization image
    private func imageData(from frame: ARFrame, request: FMLocalizationRequest) -> Data? {
        
        // mock if simulation
        guard !request.isSimulation else {
            return MockData.imageData(request)
        }

        let imageData = FMUtility.toJpeg(pixelBuffer: frame.capturedImage, with: frame.deviceOrientation)
        return imageData
    }
}
