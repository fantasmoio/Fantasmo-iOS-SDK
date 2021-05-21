//
//  FMApi.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation
import ARKit

protocol FMApiDelegate: class {
    var isSimulation: Bool { get }
    var simulationZone: FMZone.ZoneType  { get }
    var anchorFrame: ARFrame? { get }
}

class FMApi {
    
    static let shared = FMApi()
    weak var delegate: FMApiDelegate?
    var token: String?
    private var coordinate: CLLocationCoordinate2D {
        get {
            return FMLocationManager.shared.currentLocation.coordinate
        }
    }
    
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
    ///   - deviceOrientation: Orientation of device when frame was captured from camera.
    ///   - completion: Completion closure
    ///   - error: Error closure
    func localize(frame: ARFrame,
                  with deviceOrientation: UIDeviceOrientation,
                  completion: @escaping LocalizationResult,
                  error: @escaping ErrorResult) {
        
        // set up request parameters
        guard let data = extractDataOfProperlyOrientedImage(of: frame, with: deviceOrientation) else {
            error(FMError(ApiError.invalidImage))
            return
        }
        let params = paramsOfLocalizeRequest(for: frame, with: deviceOrientation)
        
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
            token: token,
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
            error: postError)
    }
    
    // MARK: - private methods
    
    /// Calculate parameters of the "Localize" request for the given `ARFrame`.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Formatted localization parameters
    private func paramsOfLocalizeRequest(for frame: ARFrame, with deviceOrientation: UIDeviceOrientation) -> [String : String] {
        
        // mock if simulation
        guard delegate == nil || !delegate!.isSimulation else {
            return MockData.params(forZone: delegate!.simulationZone)
        }
        
        let interfaceOrientation = UIApplication.shared.statusBarOrientation
        
        let transformOfOpenCvVirtualDeviceInOpenCVWorldCS =
            frame.transformOfOpenCvVirtualDeviceInOpenCVWorldCS(for: deviceOrientation)
        let pose = FMPose(transformOfOpenCvVirtualDeviceInOpenCVWorldCS)
        
        let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                      atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                      withStatusBarOrientation: interfaceOrientation,
                                      withDeviceOrientation: deviceOrientation,
                                      withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                      withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
        
        var params = [
            "intrinsics" : intrinsics.toJson(),
            "gravity" : pose.orientation.toJson(),
            "capturedAt" : String(NSDate().timeIntervalSince1970),
            "uuid" : UUID().uuidString,
            "coordinate": "{\"longitude\" : \(coordinate.longitude), \"latitude\": \(coordinate.latitude)}"
        ]
        
        // calculate and send reference frame if anchoring
        if let anchorFrame = delegate?.anchorFrame {
            /// Server uses the following formula for calculating transform of anchor:
            ///      `openCVAnchorInOpenCVWorldCS = deviceInOpenCVWorldCS * openCVAnchorInOpenCVDeviceCS`
            let anchorTransformInOpenCVDeviceCS =
                transformOfOpenCvVirtualDeviceInOpenCVWorldCS.calculateRelativeTransformInTheCsOfSelf(
                    of: anchorFrame.transformOfOpenCVDeviceInOpenCVWorldCS
                )

            params["referenceFrame"] = FMPose(anchorTransformInOpenCVDeviceCS).toJson()
        }
        
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
    private func extractDataOfProperlyOrientedImage(of frame: ARFrame,
                                                    with deviceOrientation: UIDeviceOrientation) -> Data? {
        
        // mock if simulation
        guard delegate == nil || !delegate!.isSimulation else {
            return MockData.imageData(forZone: delegate!.simulationZone)
        }

        let imageData = FMUtility.toJpeg(pixelBuffer: frame.capturedImage, with: deviceOrientation)
        return imageData
    }
}
