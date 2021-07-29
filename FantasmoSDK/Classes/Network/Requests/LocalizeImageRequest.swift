//
//  LocalizeImageRequest.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 27.07.2021.
//

import ARKit

struct LocalizeImageRequest: RestAPIRequest {
    
    let frame: ARFrame
    
    /// Pose of anchor coordinate system in virtual device coordinate system and for both following OpenCV conventions
    let relativeOpenCVAnchorPose: FMPose?
    
    /// Accumulator and aggregator of the data related with frames received starting from invoking
    /// `FMLocationManager.startUpdatingLocation()` or starting anchoring.
    let frameBasedInfoAccumulator: FrameBasedInfoAccumulator
    
    /// An estimate of the location. Coarse resolution is acceptable such as GPS or cellular tower proximity.
    let approximateCoordinate: CLLocationCoordinate2D
    
    /// See comment to `FMLocationManager.localizationSessionId` for details.
    let localizationSessionId: UUID
    
    /// See comment to `FMLocationManager.rideId` for details.
    let sessionId: String
    
    // TODO: refactor constructing better mechanism for simulation
    let simulationParams: (isSimulation: Bool, simulationZone: FMZone.ZoneType)
    
    // MARK: - RestAPIRequest
    
    var relativeURL: String { "image.localize" }
    
    var httpMethod: HTTPMethod {
        .post
    }
    
    func parameters() throws -> [String : Any]? {
        var params = [String : String]()
        
        if !simulationParams.isSimulation {
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            
            let pose = FMPose(frame.openCVTransformOfVirtualDeviceInWorldCS)
            
            let intrinsics = FMIntrinsics(intrinsics: frame.camera.intrinsics,
                                          atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                          withStatusBarOrientation: interfaceOrientation,
                                          withDeviceOrientation: frame.deviceOrientation,
                                          withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                          withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
            
            params["intrinsics"] = try intrinsics.toJson()
            params["gravity"] = try pose.orientation.toJson()
            params["capturedAt"] = String(NSDate().timeIntervalSince1970)
            params["uuid"] = UUID().uuidString
            params["coordinate"] =
                "{\"longitude\" : \(approximateCoordinate.longitude), \"latitude\": \(approximateCoordinate.latitude)}"
        }
        else {
            params = MockData.params(forZone: simulationParams.simulationZone)
        }
        
        if let relativeOpenCVAnchorPose = relativeOpenCVAnchorPose {
            params["referenceFrame"] = try relativeOpenCVAnchorPose.toJson()
        }
        
        params["rotationSpread"] = try frameBasedInfoAccumulator.eulerAngleSpreadsAccumulator.spreads.toJson()
        params["totalTranslation"] = String(frameBasedInfoAccumulator.totalTranslation)
        params["deviceModel"] = UIDevice.current.identifier    // "iPhone7,1"
        params["deviceOs"] = UIDevice.current.system           // "iPadOS 14.5"
        params["sdkVersion"] = Bundle.fullVersion              // "1.1.18(365)
        params["udid"] = UIDevice.current.identifierForVendor?.uuidString

        params["localizationSessionId"] = localizationSessionId.uuidString
        params["sessionId"] = sessionId
        
        let trackingStateAccumulator = frameBasedInfoAccumulator.trackingStateStatisticsAccumulator
        let filterRejectionAccumulator = frameBasedInfoAccumulator.filterRejectionStatisticsAccumulator
        
        params["frameEventCounts"] = try [
            "excessiveTilt" : filterRejectionAccumulator.excessiveTiltRelatedRejectionCount,
            "excessiveBlur" : filterRejectionAccumulator.filterRejectionReasonCounts[.movingTooFast],
            "excessiveMotion" : trackingStateAccumulator.trackingStateFrameCounts[.limited(.excessiveMotion)],
            "insufficientFeatures" : trackingStateAccumulator.trackingStateFrameCounts[.limited(.insufficientFeatures)],
            "lossOfTracking" : trackingStateAccumulator.trackingStateFrameCounts[.notAvailable],
            "total" : frameBasedInfoAccumulator.trackingStateStatisticsAccumulator.totalCountOfFrames
        ].toJson()

        return params
    }
    
    func multipartFormData() throws -> MultipartFormData? {
        let multipartFormData = MultipartFormData()
        
        do {
            if let params = try parameters() {
                try multipartFormData.appendParameters(params)
            }
        }
        catch {
            throw ApiError.multipartConstructionFailed(error: error)
        }
        
        let imageData = extractDataOfProperlyOrientedImage(from: frame)
        if let imageData = imageData {
            multipartFormData.append(imageData, withName: "image", fileName: "image.jpg")
        }
        else {
            throw ApiError.multipartConstructionFailed(msg: "Image unaccessible")
        }
        return multipartFormData
    }
    
    // MARK: - Helpers
    
    /// Generate the image data used to perform "localize" HTTP request .
    /// Image of `frame` is oriented taking into account orientation of camera when taking image. For example, if device was upside-down when
    /// frame was captured from camera, then resulting image is rotated by 180 degrees. So server always receives properly oriented image
    /// as if it was captured from properly oriented camera.
    ///
    /// - Parameters:
    ///   - frame: Frame to localize
    ///   - Returns: Prepared localization image
    private func extractDataOfProperlyOrientedImage(from frame: ARFrame) -> Data? {
        if simulationParams.isSimulation {
            return MockData.imageData(forZone: simulationParams.simulationZone)
        }
        else {
            let imageData = FMUtility.toJpeg(pixelBuffer: frame.capturedImage, with: frame.deviceOrientation)
            return imageData
        }
    }
    
    
}

extension MultipartFormData {
    
    static var boundary: String { "ce8f07c0c2d14f0bbb1e3a96994e0354" }
    
    /// - throws `ApiError.requestSerializationFailed` in case of failure
    func appendParameters(_ params: [String : Any]) throws {
        for (key, value) in params {
            let stringValue: String
            
            if let aValue = value as? String {
                stringValue = aValue
            }
            else if let aValue = value as? Encodable {
                do {
                    stringValue = try aValue.toJson()
                }
                catch {
                    throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(error: error))
                }
            }
            else {
                let msg = "Parameter with key = \(key) and value = \(value) cannot be added to `MultipartFormData`"
                throw ApiError.requestSerializationFailed(reason: .jsonEncodingFailed(msg: msg))
            }
            append(stringValue.data(using: .utf8)!, withName: key)
        }
    }
    
}

