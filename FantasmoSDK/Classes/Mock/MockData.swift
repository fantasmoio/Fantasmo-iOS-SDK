//
//  MockData.swift
//  FantasmoSDK
//
//

import Foundation
import ARKit
import UIKit

class MockData {

    /// Return a simulated localization images from a known location.
    ///
    /// - Parameters:
    ///   - zone: Type of semantic zone to simulate.
    /// - Returns: Parameters and encoded image data for query.
    static func imageData(_ request: FMLocalizationRequest) -> Data {
        var jpegData: Data?
        
        switch request.simulationZone {
        case .parking:
            jpegData = UIImage(named: "inParking", in:Bundle(for:MockData.self), compatibleWith: nil)?.toJpeg(compressionQuality: FMUtility.Constants.JpegCompressionRatio)
        default:
            jpegData = UIImage(named: "onStreet", in:Bundle(for:MockData.self), compatibleWith: nil)?.toJpeg(compressionQuality: FMUtility.Constants.JpegCompressionRatio)
        }
        
        return jpegData ?? Data()
    }

    /// Generate a simulated localization query params from a known location.
    ///
    /// - Parameters:
    ///   - zone: Type of semantic zone to simulate.
    /// - Returns: Parameters for query.
    static func params(_ request: FMLocalizationRequest) -> [String : String] {
        var params: [String : String]
        switch request.simulationZone {
        case .parking:
            params = Self.parkingMockParameters
        default:
            params = Self.streetMockParameters
        }
        
        if let relativeOpenCVAnchorPose = request.relativeOpenCVAnchorPose {
            params["referenceFrame"] = relativeOpenCVAnchorPose.toJson()
        }
        return params
    }
    
    private static var parkingMockParameters: [String: String] {

        let intrinsic = ["fx": 1211.782470703125,
                         "fy": 1211.9073486328125,
                         "cx": 1017.4938354492188,
                         "cy": 788.2992553710938]
        let gravity = ["w": 0.7729115057076497,
                       "x": 0.026177782246603,
                       "y": 0.6329531644390612,
                       "z": -0.03595580186787759]
        let coordinate = ["longitude" : 11.572596873561112,
                          "latitude": 48.12844364094412]

        return ["intrinsics" : intrinsic.json,
                "gravity" : gravity.json,
                "capturedAt" : String(NSDate().timeIntervalSince1970),
                "uuid" : "C6241E04-974A-4131-8B36-044A11E2C7F0",
                "coordinate": coordinate.json]
    }

    private static var streetMockParameters: [String: String] {

        let intrinsic = ["fx": 1036.486083984375,
                         "fy": 1036.486083984375,
                         "cx": 480.23284912109375,
                         "cy": 628.2947998046875]
        let gravity = ["w": 0.7634205318288221,
                       "x": 0.05583266127506817,
                       "y": 0.6407979294057553,
                       "z": -0.058735161414937516]
        let coordinate = ["longitude" : 11.572596873561112,
                          "latitude": 48.12844364094412]

        return ["intrinsics" : intrinsic.json,
                "gravity" : gravity.json,
                "capturedAt" : String(NSDate().timeIntervalSince1970),
                "uuid" : "A87E55CB-0649-4F87-A42F-8A33970F421E",
                "coordinate": coordinate.json]
    }
}
