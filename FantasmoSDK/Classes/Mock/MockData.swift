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
    static func encodedImage(_ request: FMLocalizationRequest) -> ImageEncoder.Image? {
        var image: UIImage?
        switch request.simulationZone {
        case .parking:
            image = UIImage(named: "inParking", in:Bundle(for:MockData.self), compatibleWith: nil)
        default:
            image = UIImage(named: "onStreet", in:Bundle(for:MockData.self), compatibleWith: nil)
        }
        guard let image = image, let jpegData = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }
        let resolution = CGSize(width: image.size.width * image.scale, height: image.size.height * image.scale)
        return ImageEncoder.Image(data: jpegData, resolution: resolution, originalResolution: resolution)
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
        
        let location = CLLocation(latitude: 48.12844364094412, longitude: 11.572596873561112)

        return ["intrinsics" : intrinsic.json,
                "gravity" : gravity.json,
                "location": location.toJson()]
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
        
        let location = CLLocation(latitude: 48.12844364094412, longitude: 11.572596873561112)

        return ["intrinsics" : intrinsic.json,
                "gravity" : gravity.json,
                "location": location.toJson()]
    }
}
