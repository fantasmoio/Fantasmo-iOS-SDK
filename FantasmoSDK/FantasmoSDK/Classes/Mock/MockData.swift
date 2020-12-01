//
//  MockData.swift
//  FantasmoSDK
//
//

import Foundation
import ARKit
import UIKit
import CocoaLumberjack

open class MockData {


    /// Generate a simulated localization query using stored images from
    /// a known location.
    ///
    /// - Parameters:
    ///   - zone: Type of semantic zone to simulate.
    ///   - isValid: True if attempt should succeed. False if attempt should fail.
    /// - Returns: Parameters and encoded image data for query.
    public static func simulateLocalizeRequest(forZone zone: FMZone.ZoneType,
                                               isValid: Bool) -> (params: [String : Any]?, image: Data?) {
        var params: [String: Any]?
        var jpegData: Data?

        switch zone {
        case .parking:
            params = MockData.parkingMockParameters
            jpegData = UIImage(named: "inParking", in:Bundle(for:MockData.self), compatibleWith: nil)?.toJpeg(compressionQuality: FMUtility.Constants.JpegCompressionRatio)
        default:
            params = MockData.streetMockParameters
            jpegData = UIImage(named: "onStreet", in:Bundle(for:MockData.self), compatibleWith: nil)?.toJpeg(compressionQuality: FMUtility.Constants.JpegCompressionRatio)
        }

        guard jpegData != nil else {
            DDLogWarn("Error: Could not convert frame to JPEG.")
            return (nil, nil)
        }

        return (params, jpegData)
    }


    
    private static var parkingMockParameters: [String: Any] {

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
                "capturedAt" :(NSDate().timeIntervalSince1970),
                "uuid" : "C6241E04-974A-4131-8B36-044A11E2C7F0",
                "coordinate": coordinate.json] as [String : Any]
    }

    private static var streetMockParameters: [String: Any] {

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
                "capturedAt" :(NSDate().timeIntervalSince1970),
                "uuid" : "A87E55CB-0649-4F87-A42F-8A33970F421E",
                "coordinate": coordinate.json] as [String : Any]
    }
}
