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
    
    // MARK: - RestAPIRequest
    
    var relativeURL: String { "image.localize" }
    
    var httpMethod: HTTPMethod {
        .post
    }
    
    var parameters: [String : Any]? {
        var params = [String : String]()
        
        // mock if simulation
        if !FMLocationManager.shared.isSimulation {
            let interfaceOrientation = UIApplication.shared.statusBarOrientation
            
            let pose = FMPose(frame.openCVTransformOfVirtualDeviceInWorldCS)
            
            let intrinsics = FMIntrinsics(fromIntrinsics: frame.camera.intrinsics,
                                          atScale: Float(FMUtility.Constants.ImageScaleFactor),
                                          withStatusBarOrientation: interfaceOrientation,
                                          withDeviceOrientation: frame.deviceOrientation,
                                          withFrameWidth: CVPixelBufferGetWidth(frame.capturedImage),
                                          withFrameHeight: CVPixelBufferGetHeight(frame.capturedImage))
            
            params["intrinsics"] = (try? intrinsics.toJson()) ?? "{}"
            params["gravity"] = (try? pose.orientation.toJson()) ?? "{}"
            params["capturedAt"] = String(NSDate().timeIntervalSince1970)
            params["uuid"] = UUID().uuidString
            params["coordinate"] =
                "{\"longitude\" : \(approximateCoordinate.longitude), \"latitude\": \(approximateCoordinate.latitude)}"
        }
        else {
            params = MockData.params(forZone: FMLocationManager.shared.simulationZone)
        }
        
        if let relativeOpenCVAnchorPose = relativeOpenCVAnchorPose {
            params["referenceFrame"] = (try? relativeOpenCVAnchorPose.toJson()) ?? "{}"
        }
        
        params["rotationSpread"] = (try? frameBasedInfoAccumulator.eulerAngleSpreadsAccumulator.spreads.toJson()) ?? "{}"
        params["totalTranslation"] = String(frameBasedInfoAccumulator.totalTranslation)
        params["deviceModel"] = UIDevice.current.identifier    // "iPhone7,1"
        params["deviceOs"] = UIDevice.current.system           // "iPadOS 14.5"
        params["sdkVersion"] = Bundle.fullVersion              // "1.1.18(365)
        
        return params
    }
    
    func multipartFormData() throws -> MultipartFormData? {
        let multipartFormData = MultipartFormData()
        if let params = parameters {
            try multipartFormData.appendParameters(params)
        }
        let imageData = extractDataOfProperlyOrientedImage(from: frame)
        if let imageData = imageData {
            multipartFormData.append(imageData, withName: "image", fileName: "image.jpg")
        }
        else {
            throw ApiError.multipartEncodingFailed(reason: .bodyPartDataUnreachable(msg: "Image unaccessible"))
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
        if FMLocationManager.shared.isSimulation {
            return MockData.imageData(forZone: FMLocationManager.shared.simulationZone)
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

