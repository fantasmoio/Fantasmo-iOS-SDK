//
//  FMApi.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation
import ARKit
import CoreMotion
import UIKit

struct FMLocalizationRequest {
    var isSimulation: Bool
    var simulationZone: FMZone.ZoneType
    var approximateLocation: CLLocation
    var relativeOpenCVAnchorPose: FMPose?
    var analytics: FMLocalizationAnalytics
}

struct FMLocalizationAnalytics {
    var appSessionId: String?
    var appSessionTags: [String]?
    var localizationSessionId: String?
    var frameEvents: FMFrameEvents
    var rotationSpread: FMRotationSpread
    var totalDistance: Float
    var magneticField: MotionManager.MagneticField?
    var imageQualityFilterInfo: FMImageQualityFilterInfo?
    var remoteConfigId: String
}

struct FMImageQualityFilterInfo: Codable {
    var modelVersion: String?
    var lastImageQualityScore: Float
}

struct FMRotationSpread: Codable {
    var pitch: Float
    var yaw: Float
    var roll: Float
}

struct FMFrameEvents {
    var excessiveTilt: Int
    var excessiveBlur: Int
    var excessiveMotion: Int
    var insufficientFeatures: Int
    var lossOfTracking: Int
    var total: Int
}

struct FMFrameResolution: Codable {
    var height: Int
    var width: Int
}

class FMApi {
    
    static let shared = FMApi()
    var token: String?
    var imageEncoder = ImageEncoder(largestSingleOutputDimension: 1280)
    
    typealias LocalizationResult = (CLLocation, [FMZone]?) -> Void
    typealias InitializationResult = (Bool) -> Void
    typealias IsLocalizationAvailableResult = (Bool) -> Void
    typealias ErrorResult = (FMError) -> Void
    
    enum ApiError: LocalizedError {
        case httpError(_ statusCode: Int)
        case invalidImage
        case noResponseData
        case jsonDecodingError
        case locationNotFound
    }
    
    // MARK: - internal methods
    
    /// Localize based on the given image
    ///
    /// - Parameters:
    ///   - frame: The current ARFrame as given by ARSession
    ///   - request: Localization request struct
    ///   - completion: Completion closure
    ///   - error: Error closure
    func sendLocalizationRequest(frame: ARFrame,
                                 request: FMLocalizationRequest,
                                 completion: @escaping LocalizationResult,
                                 error: @escaping ErrorResult) {
        
        // set up request parameters
        guard let image = encodedImage(from: frame, request: request) else {
            error(FMError(ApiError.invalidImage))
            return
        }
        
        let params = getLocalizeParams(for: frame, image: image, request: request)
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, data in
            
            // handle invalid response
            guard let code = code, let data = data else {
                error(FMError(ApiError.noResponseData))
                return
            }
            
            // ensure non-error response
            guard code == 200 else {
                error(FMError(ApiError.httpError(code), data))
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
                error(FMError(ApiError.jsonDecodingError, cause: jsonError))
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
            imageData: image.data,
            token: token,
            completion: postCompletion,
            error: postError
        )
    }

    /// Check if localization is available *near* the supplied location.
    ///
    /// - Parameters:
    ///   - location: Center of area to search
    ///   - completion: Completion closure
    ///   - error: Error closure
    func sendIsLocalizationAvailableRequest(location: CLLocation,
                                            completion: @escaping IsLocalizationAvailableResult,
                                            error: @escaping ErrorResult) {
        // set up request parameters
        let params = getInitializeParams(for: location)
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, data in
            guard let code = code, let data = data else {
                error(FMError(ApiError.noResponseData))
                return
            }
            guard code == 200 else {
                error(FMError(ApiError.httpError(code), data))
                return
            }
            do {
                // decode server response
                let response = try JSONDecoder().decode(IsLocalizationAvailableResponse.self, from: data)
                completion(response.available)
            } catch let jsonError {
                error(FMError(ApiError.jsonDecodingError, cause: jsonError))
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            error(FMError(errorResponse))
        }
        
        // send request
        FMRestClient.post(
            .isLocalizationAvailable,
            parameters: params,
            token: token,
            completion: postCompletion,
            error: postError
        )
    }

    /// Initialize Fantasmo at a specified location
    ///
    /// - Parameters:
    ///   - location: Location of the device
    ///   - completion: Completion closure
    ///   - error: Error closure
    func sendInitializationRequest(location: CLLocation,
                                   completion: @escaping InitializationResult,
                                   error: @escaping ErrorResult) {
        // set up request parameters
        let params = getInitializeParams(for: location)
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, data in
            guard let code = code, let data = data else {
                error(FMError(ApiError.noResponseData))
                return
            }
            guard code == 200 else {
                error(FMError(ApiError.httpError(code), data))
                return
            }
            do {
                // decode server response
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                let initializeResponse = try jsonDecoder.decode(InitializeResponse.self, from: data)
                // update remote config values
                if let config = initializeResponse.config {
                    RemoteConfig.update(config)
                    ImageQualityModelUpdater.shared.checkForUpdates()
                }
                completion(initializeResponse.parkingInRadius)
            } catch let jsonError {
                error(FMError(ApiError.jsonDecodingError, cause: jsonError))
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            error(FMError(errorResponse))
        }
        
        // send request
        FMRestClient.post(
            .initialize,
            parameters: params,
            token: token,
            completion: postCompletion,
            error: postError
        )
    }
    
    // MARK: - private methods
    
    private func getInitializeParams(for location: CLLocation) -> [String: Any] {
        let params: [String: Any] = [
            "location": [
                "coordinate": [
                    "latitude": location.coordinate.latitude,
                    "longitude": location.coordinate.longitude,
                ],
                "altitude": location.altitude,
                "horizontalAccuracy": location.horizontalAccuracy,
                "verticalAccuracy": location.verticalAccuracy,
                "timestamp": location.timestamp.timeIntervalSince1970
            ]
        ]
        return params.merging(getDeviceAndHostAppInfo()) { (_, new) in new }
    }
    
    /// Calculate parameters of the "Localize" request for the given `ARFrame`.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Formatted localization parameters
    private func getLocalizeParams(for frame: ARFrame, image: ImageEncoder.Image, request: FMLocalizationRequest) -> [String : String?] {
        var params: [String : String?]
        
        // mock if simulation
        if !request.isSimulation {
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            
            let pose = FMPose(frame.openCVTransformOfVirtualDeviceInWorldCS)
            
            let imageSize = max(image.resolution.width, image.resolution.height)
            let originalImageSize = max(image.originalResolution.width, image.originalResolution.height)
            let imageScaleFactor = originalImageSize > 0 ? imageSize / originalImageSize : 0
            let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                          atScale: Float(imageScaleFactor),
                                          withStatusBarOrientation: interfaceOrientation,
                                          withDeviceOrientation: frame.deviceOrientation,
                                          withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                          withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
            
            let location = request.approximateLocation

            let events = request.analytics.frameEvents
            let frameEventCounts = [
                "excessiveTilt": events.excessiveTilt,
                "excessiveBlur": events.excessiveBlur,
                "excessiveMotion": events.excessiveMotion,
                "insufficientFeatures": events.insufficientFeatures,
                "lossOfTracking": events.lossOfTracking,
                "total": events.total,
            ]
            
            // TODO - in v2 api we should serialize these as a single named json object
            params = [
                "intrinsics" : intrinsics.toJson(),
                "gravity" : pose.orientation.toJson(),
                "capturedAt" : String(NSDate().timeIntervalSince1970 * 1000.0),
                "uuid" : UUID().uuidString,
                
                "location": location.toJson(),
                
                // session identifiers
                "appSessionId": request.analytics.appSessionId,
                "localizationSessionId": request.analytics.localizationSessionId,

                // other analytics
                "frameEventCounts": frameEventCounts.toJson(),
                "totalDistance": String(request.analytics.totalDistance),
                "rotationSpread": request.analytics.rotationSpread.toJson(),
            ]
            
            // add image quality filter info if enabled
            if let imageQualityFilterInfo = request.analytics.imageQualityFilterInfo {
                params["imageQualityModelVersion"] = imageQualityFilterInfo.modelVersion
                params["imageQualityScore"] = String(imageQualityFilterInfo.lastImageQualityScore)
            }
            
            if let magneticData = request.analytics.magneticField?.toJson() {
                params["magneticData"] = magneticData
            }
        }
        else {
            params = MockData.params(request)
        }
        
        params["remoteConfigId"] = request.analytics.remoteConfigId
        
        let appSessionTags: [String] = request.analytics.appSessionTags ?? []
        params["appSessionTags"] = appSessionTags.toJson()
        
        let imageResolution = FMFrameResolution(height: Int(image.resolution.height), width: Int(image.resolution.width))
        params["imageResolution"] = imageResolution.toJson()
        
        // calculate and send reference frame if anchoring
        if let relativeOpenCVAnchorPose = request.relativeOpenCVAnchorPose {
            params["referenceFrame"] = relativeOpenCVAnchorPose.toJson()
        }
                
        return params.merging(getDeviceAndHostAppInfo()) { (_, new) in new }
    }
    
    /// Generate the image data used to perform "localize" HTTP request .
    /// Image of `frame` is oriented taking into account orientation of camera when taking image. For example, if device was upside-down when
    /// frame was captured from camera, then resulting image is rotated by 180 degrees. So server always receives properly oriented image
    /// as if it was captured from properly oriented camera.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - request: Localization request struct
    ///   - Returns: Prepared localization image
    private func encodedImage(from frame: ARFrame, request: FMLocalizationRequest) -> ImageEncoder.Image? {
        
        // mock if simulation
        guard !request.isSimulation else {
            return MockData.encodedImage(request)
        }

        let encodedImage = imageEncoder.encodedImage(from: frame)
        return encodedImage
    }
    
    /// Returns a dictionary of common device and host app info that can be added to request parameters.
    private func getDeviceAndHostAppInfo() -> [String: String] {
        let info: [String: String] = [
            "udid": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "deviceModel": UIDevice.current.identifier,
            "deviceOs": UIDevice.current.correctedSystemName,
            "deviceOsVersion": UIDevice.current.systemVersion,
            "sdkVersion": FMSDKInfo.fullVersion,
            "hostAppBundleIdentifier": FMSDKInfo.hostAppBundleIdentifier,
            "hostAppMarketingVersion": FMSDKInfo.hostAppMarketingVersion,
            "hostAppBuildNumber": FMSDKInfo.hostAppBuildNumber
        ]
        return info
    }
}
