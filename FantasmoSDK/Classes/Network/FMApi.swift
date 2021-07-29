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
    func sendLocalizeImageRequest(requestObject: LocalizeImageRequest ,
                                  completion: @escaping LocalizationResult,
                                  errorClosure: @escaping ErrorResult) {
        
        // set up completion closure
        let postCompletion: FMRestClient.RestResult = { code, data in
            
            // handle invalid response
            guard let code = code, let data = data else {
                errorClosure(FMError(ApiError.invalidResponse))
                return
            }
            
            // handle valid but erroneous response
            guard !(400...499 ~= code) else {
                errorClosure(FMError(data))
                return
            }
            
            // ensure non-error response
            guard code == 200 else {
                errorClosure(FMError(ApiError.invalidResponse))
                return
            }
            
            do {
                // decode server response
                let localizeResponse = try JSONDecoder().decode(LocalizeResponse.self, from: data)
                
                // get location
                guard let location = localizeResponse.location?.coordinate?.getLocation() else {
                    errorClosure(FMError(ApiError.locationNotFound))
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
                errorClosure(FMError(ApiError.invalidResponse, cause: jsonError))
            }
        }
        
        // set up error closure
        let postError: FMRestClient.RestError = { errorResponse in
            errorClosure(FMError(errorResponse))
        }
        
        let urlRequest = requestForEndpoint(.localize, token: token)
        if let paramaters = try? requestObject.parameters(), let params = paramaters {
            log.info(String(describing: urlRequest.url), parameters: params)
        }
        do {
            if let multipartFormData = try requestObject.multipartFormData() {
                FMRestClient.post(
                    urlRequest: urlRequest,
                    multipartFormData: multipartFormData,
                    completion: postCompletion,
                    errorClosure: postError
                )
            }
            else {
                // "programming" error, do nothing
            }
        }
        catch {
            errorClosure(FMError(error))
        }
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
        let postErrorClosure: FMRestClient.RestError = { errorResponse in
            error(FMError(errorResponse))
        }
        
        let urlRequest = requestForEndpoint(.zoneInRadius, token: token)
        log.info(String(describing: urlRequest.url), parameters: params)
        
        // send request
        FMRestClient.post(
            urlRequest: urlRequest,
            parameters: params,
            completion: postCompletion,
            errorClosure: postErrorClosure
        )
    }
    
    // MARK: - Helpers
    
    /// Generates a request that can be used for posting
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to post to
    ///   - token: Optional API security token
    /// - Returns: POST request containing server URL, endpoint, token header, and `multipart/from-data` header
    private func requestForEndpoint(_ endpoint: FMApiRouter.ApiEndpoint, token: String?) -> URLRequest {
        var request = URLRequest(url: FMApiRouter.urlForEndpoint(endpoint))
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "Fantasmo-Key")
        }
        request.setValue("multipart/form-data; boundary=\(Data.boundary)", forHTTPHeaderField: "Content-Type")
        return request
    }
    
}

